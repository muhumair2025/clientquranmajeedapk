import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/prayer_times_model.dart';
import '../services/prayer_times_service.dart';
import '../services/prayer_alarm_service.dart';
import '../themes/app_theme.dart';
import '../widgets/app_text.dart';
import '../localization/app_localizations_extension.dart';
import 'adhan_sound_selection_screen.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final PrayerTimesService _service = PrayerTimesService();
  
  PrayerTimes? _prayerTimes;
  bool _isLoading = true;
  bool _isOffline = false;
  String? _error;
  int _selectedMethod = 1;
  Timer? _timer;
  String _nextPrayer = '';
  String _timeRemaining = '';
  Map<String, PrayerAlarm> _alarms = {};

  @override
  void initState() {
    super.initState();
    _initializeAlarms();
    _loadData();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeAlarms() async {
    await PrayerAlarmService.initialize();
    _alarms = await PrayerAlarmService.getAlarms();
    setState(() {});
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_prayerTimes != null) {
        _updateNextPrayer();
      }
    });
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      _selectedMethod = await _service.getSavedMethod();
      
      final connectivity = await Connectivity().checkConnectivity();
      final hasInternet = connectivity.contains(ConnectivityResult.mobile) || 
                          connectivity.contains(ConnectivityResult.wifi);
      
      print('📶 Has Internet: $hasInternet, Force Refresh: $forceRefresh');
      
      // If force refresh and has internet, clear cache first
      if (forceRefresh && hasInternet) {
        print('🗑️ Clearing cache for fresh data...');
        await _service.clearCache();
      }
      
      if (!hasInternet) {
        print('📁 No internet, loading from cache...');
        final cached = await _service.getCachedPrayerTimes();
        if (cached != null) {
          setState(() {
            _prayerTimes = cached;
            _isOffline = true;
            _isLoading = false;
          });
          _updateNextPrayer();
          print('✅ Loaded cached data: Fajr=${cached.fajr}, Dhuhr=${cached.dhuhr}');
          return;
        } else {
          print('❌ No cached data available');
          setState(() {
            _error = 'No internet and no cached data available';
            _isLoading = false;
          });
          return;
        }
      }
      
      final position = await _service.getCurrentLocation();
      
      if (position == null) {
        print('📍 Location unavailable, trying cache...');
        final cached = await _service.getCachedPrayerTimes();
        if (cached != null) {
          setState(() {
            _prayerTimes = cached;
            _isOffline = true;
            _isLoading = false;
          });
          _updateNextPrayer();
          return;
        }
        setState(() {
          _error = context.l.locationNotAvailable;
          _isLoading = false;
        });
        return;
      }
      
      print('🌐 Fetching fresh prayer times...');
      final times = await _service.getPrayerTimes(
        latitude: position.latitude,
        longitude: position.longitude,
        method: _selectedMethod,
      );
      
      if (times != null) {
        print('✅ Fresh data received: Fajr=${times.fajr}, Dhuhr=${times.dhuhr}');
        setState(() {
          _prayerTimes = times;
          _isOffline = false;
          _isLoading = false;
        });
        _updateNextPrayer();
        
        // Reschedule alarms with new times
        await PrayerAlarmService.rescheduleAlarms({
          'Fajr': times.fajr,
          'Dhuhr': times.dhuhr,
          'Asr': times.asr,
          'Maghrib': times.maghrib,
          'Isha': times.isha,
        });
      } else {
        print('❌ Failed to fetch, trying cache...');
        final cached = await _service.getCachedPrayerTimes();
        if (cached != null) {
          setState(() {
            _prayerTimes = cached;
            _isOffline = true;
            _isLoading = false;
          });
          _updateNextPrayer();
        } else {
          setState(() {
            _error = context.l.prayerTimesError;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error in _loadData: $e');
      // Try cache on error
      final cached = await _service.getCachedPrayerTimes();
      if (cached != null) {
        setState(() {
          _prayerTimes = cached;
          _isOffline = true;
          _isLoading = false;
        });
        _updateNextPrayer();
      } else {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _updateNextPrayer() {
    if (_prayerTimes == null) return;
    
    final now = DateTime.now();
    final prayers = [
      ('Fajr', _prayerTimes!.fajr),
      ('Dhuhr', _prayerTimes!.dhuhr),
      ('Asr', _prayerTimes!.asr),
      ('Maghrib', _prayerTimes!.maghrib),
      ('Isha', _prayerTimes!.isha),
    ];
    
    for (final prayer in prayers) {
      final prayerTime = _parse12HourTime(prayer.$2, now);
      
      if (prayerTime != null && prayerTime.isAfter(now)) {
        final diff = prayerTime.difference(now);
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        final seconds = diff.inSeconds % 60;
        
        final newTimeRemaining = hours > 0 
            ? '${hours}h ${minutes}m ${seconds}s'
            : '${minutes}m ${seconds}s';
        
        // Only update state if values changed to reduce rebuilds
        if (_nextPrayer != prayer.$1 || _timeRemaining != newTimeRemaining) {
          setState(() {
            _nextPrayer = prayer.$1;
            _timeRemaining = newTimeRemaining;
          });
        }
        return;
      }
    }
    
    // All prayers passed for today, next is Fajr tomorrow
    final fajrTime = _parse12HourTime(_prayerTimes!.fajr, now.add(const Duration(days: 1)));
    if (fajrTime != null) {
      final diff = fajrTime.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;
      
      final newTimeRemaining = hours > 0 
          ? '${hours}h ${minutes}m ${seconds}s'
          : '${minutes}m ${seconds}s';
      
      if (_nextPrayer != 'Fajr' || _timeRemaining != newTimeRemaining) {
        setState(() {
          _nextPrayer = 'Fajr';
          _timeRemaining = newTimeRemaining;
        });
      }
    } else {
      if (_nextPrayer != 'Fajr' || _timeRemaining != '--:--:--') {
        setState(() {
          _nextPrayer = 'Fajr';
          _timeRemaining = '--:--:--';
        });
      }
    }
  }

  /// Parse 12-hour format time (e.g., "5:30 AM" or "1:30 PM")
  DateTime? _parse12HourTime(String timeStr, DateTime baseDate) {
    try {
      // Remove extra spaces and split
      final cleanTime = timeStr.trim();
      final parts = cleanTime.split(' ');
      
      if (parts.isEmpty) return null;
      
      // Split time part (e.g., "5:30")
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

  String _getLocalizedPrayerName(String name) {
    switch (name) {
      case 'Fajr': return context.l.fajr;
      case 'Sunrise': return context.l.sunrise;
      case 'Dhuhr': return context.l.dhuhr;
      case 'Asr': return context.l.asr;
      case 'Maghrib': return context.l.maghrib;
      case 'Isha': return context.l.isha;
      default: return name;
    }
  }

  String _getPrayerIcon(String name) {
    switch (name) {
      case 'Fajr': return '🌙';
      case 'Sunrise': return '🌅';
      case 'Dhuhr': return '☀️';
      case 'Asr': return '🌤️';
      case 'Maghrib': return '🌇';
      case 'Isha': return '🌃';
      default: return '🕌';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: AppText(context.l.prayerTimesTitle),
        centerTitle: true,
        elevation: 0,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.tune_rounded),
            tooltip: context.l.calculationMethod,
            onSelected: (value) async {
              setState(() => _selectedMethod = value);
              await _service.saveMethod(value);
              await _loadData(forceRefresh: true);
            },
            itemBuilder: (context) => CalculationMethod.methods.map((method) {
              return PopupMenuItem<int>(
                value: method.id,
                child: Row(
                  children: [
                    if (method.id == _selectedMethod)
                      Icon(Icons.check, color: AppTheme.primaryGreen, size: 18)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method.name,
                            style: const TextStyle(
                              fontFamily: 'Poppins Regular',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            method.description,
                            style: const TextStyle(
                              fontFamily: 'Poppins Regular',
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _error != null && _prayerTimes == null
              ? _buildError()
              : _buildContent(isDark),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryGreen),
          const SizedBox(height: 16),
          AppText(context.l.fetchingPrayerTimes),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            AppText(
              _error ?? context.l.prayerTimesError,
              style: context.textStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadData(forceRefresh: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: AppText(context.l.tryAgain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return RefreshIndicator(
      onRefresh: () => _loadData(forceRefresh: true),
      color: AppTheme.primaryGreen,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Offline badge
          if (_isOffline)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  AppText(
                    context.l.usingCachedData,
                    style: context.textStyle(fontSize: 11, color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
          
          // Next prayer card
          _buildNextPrayerCard(isDark),
          
          const SizedBox(height: 20),
          
          // Prayer times list
          _buildPrayersList(isDark),
          
          const SizedBox(height: 16),
          
          // Calculation method info
          if (_prayerTimes != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: AppText(
                  _prayerTimes!.method,
                  style: context.textStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNextPrayerCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen,
            AppTheme.darkGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Date row
          if (_prayerTimes != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  _prayerTimes!.date,
                  style: context.textStyle(fontSize: 11, color: Colors.white70),
                ),
                AppText(
                  _prayerTimes!.hijriDate,
                  style: context.textStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          
          const SizedBox(height: 16),
          
          // Next prayer
          AppText(
            context.l.nextPrayer,
            style: context.textStyle(fontSize: 12, color: Colors.white60),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
           Text(
                _nextPrayer.isNotEmpty ? _getPrayerIcon(_nextPrayer) : '🕌',
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 10),
              AppText(
                _nextPrayer.isNotEmpty 
                    ? _getLocalizedPrayerName(_nextPrayer)
                    : context.l.loading,
                style: context.textStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Countdown (using English font for time)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  _timeRemaining.isNotEmpty ? _timeRemaining : '--:--:--',
                  style: const TextStyle(
                    fontFamily: 'Poppins Regular',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayersList(bool isDark) {
    if (_prayerTimes == null) return const SizedBox.shrink();
    
    final prayers = [
      ('Fajr', _prayerTimes!.fajr),
      ('Sunrise', _prayerTimes!.sunrise),
      ('Dhuhr', _prayerTimes!.dhuhr),
      ('Asr', _prayerTimes!.asr),
      ('Maghrib', _prayerTimes!.maghrib),
      ('Isha', _prayerTimes!.isha),
    ];
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: prayers.asMap().entries.map((entry) {
          final index = entry.key;
          final prayer = entry.value;
          final isNext = prayer.$1 == _nextPrayer;
          final isLast = index == prayers.length - 1;
          final isSunrise = prayer.$1 == 'Sunrise';
          
          return Column(
            children: [
              _buildPrayerTile(
                name: prayer.$1,
                time: prayer.$2,
                isNext: isNext,
                isDark: isDark,
                showAlarm: !isSunrise, // No alarm for sunrise
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 52,
                  endIndent: 16,
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPrayerTile({
    required String name,
    required String time,
    required bool isNext,
    required bool isDark,
    required bool showAlarm,
  }) {
    final alarm = _alarms[name];
    final hasAlarm = alarm != null;
    
    return InkWell(
      onTap: showAlarm ? () => _showAlarmDialog(name, time) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: isNext ? BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.08),
        ) : null,
        child: Row(
          children: [
            // Icon
            Text(_getPrayerIcon(name), style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    _getLocalizedPrayerName(name),
                    style: context.textStyle(
                      fontSize: 15,
                      fontWeight: isNext ? FontWeight.w600 : FontWeight.w500,
                      color: isNext ? AppTheme.primaryGreen : null,
                    ),
                  ),
                  if (hasAlarm)
                    AppText(
                      alarm.minutesBefore == 0 
                          ? context.l.alarmAtPrayerTime
                          : '${alarm.minutesBefore} ${context.l.alarmMinutesBefore}',
                      style: context.textStyle(
                        fontSize: 10,
                        color: AppTheme.primaryGreen.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
            
            // Alarm button
            if (showAlarm)
              GestureDetector(
                onTap: () => _showAlarmDialog(name, time),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasAlarm 
                        ? AppTheme.primaryGreen.withOpacity(0.1) 
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasAlarm ? Icons.alarm_on_rounded : Icons.alarm_add_rounded,
                    size: 20,
                    color: hasAlarm ? AppTheme.primaryGreen : Colors.grey,
                  ),
                ),
              ),
            
            const SizedBox(width: 8),
            
            // Time (using English font for numbers)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isNext 
                    ? AppTheme.primaryGreen 
                    : (isDark ? Colors.white10 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time,
                style: TextStyle(
                  fontFamily: 'Poppins Regular',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isNext ? Colors.white : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlarmDialog(String prayerName, String prayerTime) {
    final currentAlarm = _alarms[prayerName];
    int? selectedPreset = currentAlarm?.minutesBefore;
    String? selectedSound = currentAlarm?.soundPath ?? 'assets/adhan/azan1.mp3';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Title
                Row(
                  children: [
                    Text(_getPrayerIcon(prayerName), style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            '${_getLocalizedPrayerName(prayerName)} ${context.l.prayerReminder}',
                            style: context.textStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          AppText(
                            prayerTime,
                            style: context.textStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Presets
                ...PrayerAlarmService.presets.map((preset) {
                  final isSelected = selectedPreset == preset.minutes;
                  return InkWell(
                    onTap: () {
                      setSheetState(() => selectedPreset = preset.minutes);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryGreen.withOpacity(0.1)
                            : (isDark ? Colors.white10 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected 
                            ? Border.all(color: AppTheme.primaryGreen)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.alarm_on : Icons.alarm,
                            color: isSelected ? AppTheme.primaryGreen : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          AppText(
                            preset.label,
                            style: context.textStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? AppTheme.primaryGreen : null,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
                
                const SizedBox(height: 16),
                
                // Adhan Sound Selection
                InkWell(
                  onTap: () async {
                    final result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdhanSoundSelectionScreen(
                          currentSoundPath: selectedSound,
                        ),
                      ),
                    );
                    
                    if (result != null) {
                      setSheetState(() => selectedSound = result);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.music_note_rounded,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                context.l.adhanSound,
                                style: context.textStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              AppText(
                                _getSoundName(selectedSound),
                                style: context.textStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryGreen.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.grey,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Buttons
                Row(
                  children: [
                    // Remove alarm button
                    if (currentAlarm != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await PrayerAlarmService.removeAlarm(prayerName);
                            _alarms = await PrayerAlarmService.getAlarms();
                            setState(() {});
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${context.l.alarmRemoved} - ${_getLocalizedPrayerName(prayerName)}'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          icon: const Icon(Icons.alarm_off, size: 18),
                          label: Text(context.l.remove),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red.shade200),
                          ),
                        ),
                      ),
                    
                    if (currentAlarm != null) const SizedBox(width: 12),
                    
                    // Save button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: selectedPreset != null ? () async {
                          await PrayerAlarmService.setAlarm(
                            prayerName: prayerName,
                            minutesBefore: selectedPreset!,
                            prayerTime: prayerTime,
                            soundPath: selectedSound,
                          );
                          _alarms = await PrayerAlarmService.getAlarms();
                          setState(() {});
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${context.l.alarmSet} - ${_getLocalizedPrayerName(prayerName)}'),
                              backgroundColor: AppTheme.primaryGreen,
                            ),
                          );
                        } : null,
                        icon: const Icon(Icons.alarm_add, size: 18),
                        label: Text(context.l.setAlarm),
                      ),
                    ),
                  ],
                ),
                
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  String _getSoundName(String? soundPath) {
    if (soundPath == null) return 'Default';
    if (soundPath.contains('azan1')) return 'Adhan 1 - Traditional';
    if (soundPath.contains('azan2')) return 'Adhan 2 - Melodious';
    if (soundPath.contains('azan3')) return 'Adhan 3 - Classical';
    if (soundPath.contains('azan4')) return 'Adhan 4 - Modern';
    if (soundPath.contains('azan5')) return 'Adhan 5 - Peaceful';
    return 'Custom Sound';
  }
}
