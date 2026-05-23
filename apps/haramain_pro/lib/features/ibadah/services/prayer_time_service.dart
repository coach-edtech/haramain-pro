import 'package:adhan/adhan.dart';
import 'package:flutter/services.dart';

/// Prayer names enum
enum PrayerName {
  fajr('Fajr', 'Subuh'),
  sunrise('Sunrise', 'Terbit'),
  dhuhr('Dhuhr', 'Zuhur'),
  asr('Asr', 'Asar'),
  maghrib('Maghrib', 'Maghrib'),
  isha('Isha', 'Isya');

  final String english;
  final String indonesian;

  const PrayerName(this.english, this.indonesian);
}

/// Prayer time data model
class PrayerTime {
  final PrayerName name;
  final DateTime time;
  final bool isNext;
  final bool isCurrent;

  const PrayerTime({
    required this.name,
    required this.time,
    this.isNext = false,
    this.isCurrent = false,
  });

  PrayerTime copyWith({
    PrayerName? name,
    DateTime? time,
    bool? isNext,
    bool? isCurrent,
  }) {
    return PrayerTime(
      name: name ?? this.name,
      time: time ?? this.time,
      isNext: isNext ?? this.isNext,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}

/// Next prayer result with countdown
class NextPrayerResult {
  final PrayerTime prayer;
  final Duration timeRemaining;

  const NextPrayerResult({
    required this.prayer,
    required this.timeRemaining,
  });
}

/// Prayer time service for Makkah
/// Uses adhan package for accurate prayer time calculation
class PrayerTimeService {
  static final PrayerTimeService _instance = PrayerTimeService._internal();
  static PrayerTimeService get instance => _instance;

  PrayerTimeService._internal();

  // Makkah coordinates
  static const double _makkahLatitude = 21.4225;
  static const double _makkahLongitude = 39.8262;

  // Cached prayer times for today
  List<PrayerTime>? _cachedPrayerTimes;
  DateTime? _cachedDate;

  /// Get prayer times for a specific date
  List<PrayerTime> getPrayerTimes({DateTime? date}) {
    final targetDate = date ?? DateTime.now();

    // Return cached if same day
    if (_cachedPrayerTimes != null && _cachedDate != null) {
      if (_isSameDay(_cachedDate!, targetDate)) {
        return _cachedPrayerTimes!;
      }
    }

    // Using Umm Al-Qura University method, commonly used in Saudi Arabia
    final params = CalculationParameters(
      fajrAngle: 18.5,
      ishaAngle: 90, // 90 minutes after maghrib for Makkah
      madhab: Madhab.shafi,
    );

    // Create coordinates for Makkah
    final coordinates = Coordinates(_makkahLatitude, _makkahLongitude);

    // Calculate prayer times using the correct adhan API
    final prayerTimes = PrayerTimes(
      coordinates,
      DateComponents.from(targetDate),
      params,
    );

    final now = DateTime.now();
    final fivePrayers = <PrayerName>[
      PrayerName.fajr,
      PrayerName.dhuhr,
      PrayerName.asr,
      PrayerName.maghrib,
      PrayerName.isha,
    ];

    final times = <PrayerTime>[];
    PrayerName? nextPrayer;
    PrayerName? currentPrayer;

    for (final prayer in fivePrayers) {
      DateTime? time;
      switch (prayer) {
        case PrayerName.fajr:
          time = prayerTimes.fajr;
        case PrayerName.dhuhr:
          time = prayerTimes.dhuhr;
        case PrayerName.asr:
          time = prayerTimes.asr;
        case PrayerName.maghrib:
          time = prayerTimes.maghrib;
        case PrayerName.isha:
          time = prayerTimes.isha;
        case PrayerName.sunrise:
          continue; // Skip sunrise for the main 5
      }

      if (time == null) {
        continue;
      }

      // Determine next and current prayers
      if (time.isAfter(now) && nextPrayer == null) {
        nextPrayer = prayer;
      }
      if (time.isBefore(now)) {
        currentPrayer = prayer;
      }

      times.add(PrayerTime(
        name: prayer,
        time: time,
        isNext: prayer == nextPrayer,
        isCurrent: prayer == currentPrayer,
      ));
    }

    // Mark next prayer correctly
    final updatedTimes = times.map((t) {
      if (t.name == nextPrayer) {
        return t.copyWith(isNext: true);
      }
      return t;
    }).toList();

    // Cache the results
    _cachedPrayerTimes = updatedTimes;
    _cachedDate = targetDate;

    return updatedTimes;
  }

  /// Get the next prayer with countdown
  NextPrayerResult? getNextPrayer({DateTime? fromTime}) {
    final now = fromTime ?? DateTime.now();
    final prayerTimes = getPrayerTimes();

    for (final prayer in prayerTimes) {
      if (prayer.time.isAfter(now)) {
        return NextPrayerResult(
          prayer: prayer,
          timeRemaining: prayer.time.difference(now),
        );
      }
    }

    // If all prayers passed, return first prayer (Fajr) for tomorrow
    // Add 24 hours to the first prayer time
    final firstPrayer = prayerTimes.first;
    final tomorrowTime = firstPrayer.time.add(const Duration(days: 1));
    return NextPrayerResult(
      prayer: firstPrayer.copyWith(isNext: true),
      timeRemaining: tomorrowTime.difference(now),
    );
  }

  /// Get current prayer (the one we're in time for)
  PrayerTime? getCurrentPrayer({DateTime? atTime}) {
    final now = atTime ?? DateTime.now();
    final prayerTimes = getPrayerTimes();

    PrayerTime? current;
    PrayerTime? previous;

    for (final prayer in prayerTimes) {
      if (prayer.time.isBefore(now)) {
        previous = prayer;
      }
    }

    if (previous != null) {
      // Check if we're still within the current prayer window
      // A prayer window lasts until the next prayer
      final currentIndex = prayerTimes.indexOf(previous);
      if (currentIndex < prayerTimes.length - 1) {
        final nextPrayer = prayerTimes[currentIndex + 1];
        if (now.isBefore(nextPrayer.time)) {
          current = previous.copyWith(isCurrent: true);
        }
      }
    }

    return current;
  }

  /// Format countdown duration to readable string
  String formatCountdown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Format prayer time to string
  String formatPrayerTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Get Islamic (Hijri) date for a given Gregorian date
  /// Uses simple conversion algorithm
  Map<String, String> getIslamicDate({DateTime? date}) {
    final targetDate = date ?? DateTime.now();
    final hijri = _gregorianToHijri(targetDate);

    return {
      'day': hijri['day'].toString(),
      'month': _getHijriMonthName(hijri['month'] as int),
      'year': hijri['year'].toString(),
      'monthNumber': hijri['month'].toString(),
    };
  }

  /// Convert Gregorian date to Hijri
  /// Using the algorithm from "Astronomical Algorithms" by Jean Meeus
  Map<String, int> _gregorianToHijri(DateTime date) {
    // Julian Day Number
    final jd = _dateToJulianDay(date.year, date.month, date.day);

    // Hijri epoch (Julian Day Number for 1 Muharram 1 AH)
    const hijriEpoch = 1948439.5;

    // Days since Hijri epoch
    final days = jd - hijriEpoch;

    // 30-year cycle days
    const cycleDays = 10631;

    // Number of complete 30-year cycles
    final cycles = (days / cycleDays).floor();

    // Remaining days after cycles
    var remainingDays = (days - cycles * cycleDays).floor();

    // 30-year cycle approximation
    var yearsSinceEpoch = (remainingDays / 354.366627).floor();

    // Refine years
    remainingDays = (remainingDays - (yearsSinceEpoch * 354.366627)).floor();

    var monthsSinceEpoch = (remainingDays / 29.5).floor();

    var day = (remainingDays - (monthsSinceEpoch * 29.5)).floor() + 1;

    // Calculate actual Hijri year
    var year = (cycles * 30) + yearsSinceEpoch + 1;

    // Adjust month and day
    var month = monthsSinceEpoch + 1;
    if (month > 12) {
      month = 12;
    }
    if (day > 30) {
      day = 30;
    }

    return {
      'day': day,
      'month': month,
      'year': year,
    };
  }

  /// Convert Gregorian date to Julian Day Number
  double _dateToJulianDay(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();

    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524.5;
  }

  String _getHijriMonthName(int month) {
    const months = [
      'Muharram', 'Safar', 'Rabiul Awal', 'Rabiul Akhir',
      'Jumadil Awal', 'Jumadil Akhir', 'Rajab', 'Sha\'ban',
      'Ramadan', 'Syawal', 'Dzul Qa\'dah', 'Dzul Hijjah'
    ];
    return months[month - 1];
  }

  /// Trigger haptic feedback for prayer reminder
  Future<void> triggerPrayerReminder() async {
    // Vibrate pattern for prayer reminder
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// Debug print helper
void debugPrint(String message) {
  // ignore: avoid_print
  print('[PrayerTimeService] $message');
}
