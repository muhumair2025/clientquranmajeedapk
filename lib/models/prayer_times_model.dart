class PrayerTimes {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String date;
  final String hijriDate;
  final String method;
  final String timezone;

  PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
    required this.hijriDate,
    required this.method,
    required this.timezone,
  });

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    final timings = json['timings'] as Map<String, dynamic>;
    final date = json['date'] as Map<String, dynamic>;
    final hijri = date['hijri'] as Map<String, dynamic>;
    final meta = json['meta'] as Map<String, dynamic>;

    // Clean time string - if already in 12-hour format, keep as is
    // If in 24-hour format, convert to 12-hour
    String cleanTime(String time) {
      final cleaned = time.trim();
      
      // If already has AM/PM, return as is
      if (cleaned.toUpperCase().contains('AM') || cleaned.toUpperCase().contains('PM')) {
        return cleaned;
      }
      
      // Otherwise, convert 24-hour to 12-hour
      final timePart = cleaned.split(' ').first;
      final parts = timePart.split(':');
      if (parts.length != 2) return cleaned;
      
      int hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts[1].padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      
      return '$hour:$minute $period';
    }

    return PrayerTimes(
      fajr: cleanTime(timings['Fajr'] ?? '5:30 AM'),
      sunrise: cleanTime(timings['Sunrise'] ?? '6:45 AM'),
      dhuhr: cleanTime(timings['Dhuhr'] ?? '12:30 PM'),
      asr: cleanTime(timings['Asr'] ?? '3:45 PM'),
      maghrib: cleanTime(timings['Maghrib'] ?? '6:15 PM'),
      isha: cleanTime(timings['Isha'] ?? '7:30 PM'),
      date: date['readable'] ?? '',
      hijriDate: '${hijri['day']} ${hijri['month']?['en'] ?? 'Unknown'} ${hijri['year']}',
      method: meta['method']?['name'] ?? '',
      timezone: meta['timezone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final hijriParts = hijriDate.split(' ');
    return {
      'timings': {
        'Fajr': fajr,
        'Sunrise': sunrise,
        'Dhuhr': dhuhr,
        'Asr': asr,
        'Maghrib': maghrib,
        'Isha': isha,
      },
      'date': {
        'readable': date,
        'hijri': {
          'day': hijriParts.isNotEmpty ? hijriParts[0] : '1',
          'month': {
            'en': hijriParts.length > 1 ? hijriParts[1] : 'Unknown',
          },
          'year': hijriParts.length > 2 ? hijriParts[2] : '1446',
        },
      },
      'meta': {
        'method': {
          'name': method.isNotEmpty ? method : 'Unknown',
        },
        'timezone': timezone.isNotEmpty ? timezone : 'Local',
      },
    };
  }

  /// Get prayer time by name
  String getTimeByName(String name) {
    switch (name.toLowerCase()) {
      case 'fajr': return fajr;
      case 'sunrise': return sunrise;
      case 'dhuhr': return dhuhr;
      case 'asr': return asr;
      case 'maghrib': return maghrib;
      case 'isha': return isha;
      default: return '';
    }
  }

  /// Get list of all prayers with names
  List<PrayerInfo> get allPrayers => [
    PrayerInfo(name: 'Fajr', time: fajr, icon: '🌙'),
    PrayerInfo(name: 'Sunrise', time: sunrise, icon: '🌅'),
    PrayerInfo(name: 'Dhuhr', time: dhuhr, icon: '☀️'),
    PrayerInfo(name: 'Asr', time: asr, icon: '🌤️'),
    PrayerInfo(name: 'Maghrib', time: maghrib, icon: '🌇'),
    PrayerInfo(name: 'Isha', time: isha, icon: '🌃'),
  ];
}

class PrayerInfo {
  final String name;
  final String time;
  final String icon;

  PrayerInfo({required this.name, required this.time, required this.icon});
}

/// Calculation methods for prayer times
class CalculationMethod {
  final int id;
  final String name;
  final String description;

  const CalculationMethod({
    required this.id,
    required this.name,
    required this.description,
  });

  static const List<CalculationMethod> methods = [
    CalculationMethod(id: 1, name: 'University of Islamic Sciences, Karachi', description: 'Pakistan, Bangladesh, India, Afghanistan'),
    CalculationMethod(id: 2, name: 'Islamic Society of North America (ISNA)', description: 'USA, Canada'),
    CalculationMethod(id: 3, name: 'Muslim World League', description: 'Europe, Far East'),
    CalculationMethod(id: 4, name: 'Umm Al-Qura University, Makkah', description: 'Saudi Arabia'),
    CalculationMethod(id: 5, name: 'Egyptian General Authority', description: 'Africa, Syria, Lebanon'),
    CalculationMethod(id: 7, name: 'Institute of Geophysics, Tehran', description: 'Iran'),
    CalculationMethod(id: 8, name: 'Gulf Region', description: 'UAE, Kuwait, Qatar'),
    CalculationMethod(id: 9, name: 'Kuwait', description: 'Kuwait'),
    CalculationMethod(id: 10, name: 'Qatar', description: 'Qatar'),
    CalculationMethod(id: 11, name: 'Majlis Ugama Islam Singapura', description: 'Singapore'),
    CalculationMethod(id: 12, name: 'Union des Organisations Islamiques de France', description: 'France'),
    CalculationMethod(id: 13, name: 'Diyanet İşleri Başkanlığı', description: 'Turkey'),
    CalculationMethod(id: 14, name: 'Spiritual Administration of Muslims of Russia', description: 'Russia'),
  ];

  static CalculationMethod getById(int id) {
    return methods.firstWhere((m) => m.id == id, orElse: () => methods[0]);
  }
}

