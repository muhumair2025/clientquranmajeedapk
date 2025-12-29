import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class PrayerAlarmService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static const String _alarmsKey = 'prayer_alarms';
  
  // Alarm presets in minutes before prayer (0 = at prayer time)
  static const List<AlarmPreset> presets = [
    AlarmPreset(minutes: 0, label: 'At prayer time'),
    AlarmPreset(minutes: 5, label: '5 minutes before'),
    AlarmPreset(minutes: 10, label: '10 minutes before'),
    AlarmPreset(minutes: 15, label: '15 minutes before'),
    AlarmPreset(minutes: 30, label: '30 minutes before'),
  ];

  /// Initialize notifications
  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Create notification channel with sound support
    await _createNotificationChannel();
    
    // Request permissions
    await _requestPermissions();
  }

  /// Create Android notification channel with sound support
  static Future<void> _createNotificationChannel() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // Delete existing channel if it exists (to allow recreation with new settings)
      await androidPlugin.deleteNotificationChannel('prayer_alarms');
      
      // Create channel with default sound (azan1)
      const channel = AndroidNotificationChannel(
        'prayer_alarms',
        'Prayer Alarms',
        description: 'Notifications for prayer times with Adhan sounds',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('azan1'),
      );
      
      await androidPlugin.createNotificationChannel(channel);
      print('📢 Notification channel created: prayer_alarms');
    }
  }

  static Future<void> _requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// Update notification channel sound (requires recreating channel)
  static Future<void> _updateChannelSound(String soundFile) async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // Delete and recreate channel with new sound
      await androidPlugin.deleteNotificationChannel('prayer_alarms');
      
      final channel = AndroidNotificationChannel(
        'prayer_alarms',
        'Prayer Alarms',
        description: 'Notifications for prayer times with Adhan sounds',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound(soundFile),
      );
      
      await androidPlugin.createNotificationChannel(channel);
      print('📢 Notification channel updated with sound: $soundFile');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('🔔 Notification tapped: ${response.payload}');
  }

  /// Save alarm setting for a prayer
  static Future<void> setAlarm({
    required String prayerName,
    required int minutesBefore,
    required String prayerTime,
    String? soundPath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarms = await getAlarms();
      
      alarms[prayerName] = PrayerAlarm(
        prayerName: prayerName,
        minutesBefore: minutesBefore,
        prayerTime: prayerTime,
        isEnabled: true,
        soundPath: soundPath,
      );
      
      await prefs.setString(_alarmsKey, jsonEncode(
        alarms.map((k, v) => MapEntry(k, v.toJson())),
      ));
      
      print('💾 Alarm saved for $prayerName: $minutesBefore min before $prayerTime, Sound: $soundPath');
      
      // Schedule the notification (don't let this fail the save)
      try {
        await _scheduleNotification(alarms[prayerName]!);
        print('⏰ Alarm scheduled for $prayerName at ${alarms[prayerName]!.prayerTime}');
      } catch (e, stackTrace) {
        print('⚠️ Failed to schedule notification (alarm still saved): $e');
        print('📋 Stack trace: $stackTrace');
        // Alarm is still saved, just notification scheduling failed
      }
    } catch (e) {
      print('❌ Error setting alarm: $e');
      rethrow;
    }
  }

  /// Remove alarm for a prayer
  static Future<void> removeAlarm(String prayerName) async {
    final prefs = await SharedPreferences.getInstance();
    final alarms = await getAlarms();
    
    if (alarms.containsKey(prayerName)) {
      // Cancel notification
      await _notifications.cancel(_getNotificationId(prayerName));
      alarms.remove(prayerName);
      
      await prefs.setString(_alarmsKey, jsonEncode(
        alarms.map((k, v) => MapEntry(k, v.toJson())),
      ));
      
      print('🔕 Alarm removed for $prayerName');
    }
  }

  /// Get all saved alarms
  static Future<Map<String, PrayerAlarm>> getAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_alarmsKey);
    
    if (saved == null) return {};
    
    try {
      final map = jsonDecode(saved) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, PrayerAlarm.fromJson(v)));
    } catch (e) {
      return {};
    }
  }

  /// Get alarm for specific prayer
  static Future<PrayerAlarm?> getAlarm(String prayerName) async {
    final alarms = await getAlarms();
    return alarms[prayerName];
  }

  /// Schedule notification for prayer
  static Future<void> _scheduleNotification(PrayerAlarm alarm) async {
    final now = DateTime.now();
    
    // Parse 12-hour format (e.g., "5:30 AM" or "1:30 PM")
    final prayerDateTime = _parse12HourTime(alarm.prayerTime, now);
    if (prayerDateTime == null) return;
    
    var scheduledTime = prayerDateTime.subtract(Duration(minutes: alarm.minutesBefore));
    
    // If time has passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }
    
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
    
    print('📅 Scheduling alarm for ${alarm.prayerName}:');
    print('   Prayer time: ${alarm.prayerTime}');
    print('   Minutes before: ${alarm.minutesBefore}');
    print('   Scheduled time: $scheduledTime (${tzScheduledTime})');
    print('   Current time: $now');
    
    // Prepare sound for notification
    String? soundFile;
    if (alarm.soundPath != null) {
      if (alarm.soundPath!.startsWith('assets/')) {
        // Extract filename from asset path (e.g., 'assets/adhan/azan1.mp3' -> 'azan1')
        soundFile = alarm.soundPath!.split('/').last.replaceAll('.mp3', '');
        print('🔊 Using sound: $soundFile (from ${alarm.soundPath})');
      } else {
        // Custom sound from file system - use raw resource name
        soundFile = 'custom_adhan';
        print('🔊 Using custom sound: $soundFile');
      }
    } else {
      // Default sound
      soundFile = 'azan1';
      print('🔊 Using default sound: $soundFile');
    }
    
    // Update channel sound if different from default
    if (soundFile != null && soundFile != 'azan1') {
      await _updateChannelSound(soundFile);
    }
    
    final androidDetails = AndroidNotificationDetails(
      'prayer_alarms',
      'Prayer Alarms',
      channelDescription: 'Notifications for prayer times',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: soundFile != null ? RawResourceAndroidNotificationSound(soundFile) : null,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
    );
    
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: soundFile != null ? '$soundFile.mp3' : null,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    final title = alarm.minutesBefore == 0
        ? 'Time for ${alarm.prayerName}!'
        : '${alarm.prayerName} in ${alarm.minutesBefore} minutes';
    
    final body = alarm.minutesBefore == 0
        ? 'It\'s time for ${alarm.prayerName} prayer'
        : 'Prepare for ${alarm.prayerName} prayer at ${alarm.prayerTime}';
    
    try {
      await _notifications.zonedSchedule(
        _getNotificationId(alarm.prayerName),
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: alarm.prayerName,
      );
      print('✅ Notification scheduled successfully for ${alarm.prayerName}');
    } catch (e, stackTrace) {
      print('❌ Error scheduling notification: $e');
      print('📋 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Reschedule all alarms with new prayer times
  static Future<void> rescheduleAlarms(Map<String, String> prayerTimes) async {
    final alarms = await getAlarms();
    
    for (final entry in alarms.entries) {
      final prayerTime = prayerTimes[entry.key];
      if (prayerTime != null) {
        entry.value.prayerTime = prayerTime;
        await _scheduleNotification(entry.value);
      }
    }
  }

  static int _getNotificationId(String prayerName) {
    switch (prayerName) {
      case 'Fajr': return 1;
      case 'Sunrise': return 2;
      case 'Dhuhr': return 3;
      case 'Asr': return 4;
      case 'Maghrib': return 5;
      case 'Isha': return 6;
      default: return prayerName.hashCode;
    }
  }

  /// Parse 12-hour format time (e.g., "5:30 AM" or "1:30 PM")
  static DateTime? _parse12HourTime(String timeStr, DateTime baseDate) {
    try {
      final cleanTime = timeStr.trim();
      final parts = cleanTime.split(' ');
      
      if (parts.isEmpty) return null;
      
      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return null;
      
      int hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      
      // Check for AM/PM
      if (parts.length > 1) {
        final period = parts[1].toUpperCase();
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }
      }
      
      return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
    } catch (e) {
      print('❌ Error parsing time "$timeStr": $e');
      return null;
    }
  }
}

class PrayerAlarm {
  final String prayerName;
  final int minutesBefore;
  String prayerTime;
  final bool isEnabled;
  final String? soundPath; // Path to adhan sound (asset or file path)

  PrayerAlarm({
    required this.prayerName,
    required this.minutesBefore,
    required this.prayerTime,
    required this.isEnabled,
    this.soundPath,
  });

  Map<String, dynamic> toJson() => {
    'prayerName': prayerName,
    'minutesBefore': minutesBefore,
    'prayerTime': prayerTime,
    'isEnabled': isEnabled,
    'soundPath': soundPath,
  };

  factory PrayerAlarm.fromJson(Map<String, dynamic> json) => PrayerAlarm(
    prayerName: json['prayerName'],
    minutesBefore: json['minutesBefore'],
    prayerTime: json['prayerTime'],
    isEnabled: json['isEnabled'],
    soundPath: json['soundPath'],
  );
}

class AlarmPreset {
  final int minutes;
  final String label;

  const AlarmPreset({required this.minutes, required this.label});
}

