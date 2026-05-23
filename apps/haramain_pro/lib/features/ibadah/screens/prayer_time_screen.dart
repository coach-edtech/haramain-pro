import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/prayer_time_service.dart';
import '../widgets/ibadah_mode_toggle.dart';

/// Prayer time screen showing all prayer times and countdown
class PrayerTimeScreen extends StatefulWidget {
  const PrayerTimeScreen({super.key});

  @override
  State<PrayerTimeScreen> createState() => _PrayerTimeScreenState();
}

class _PrayerTimeScreenState extends State<PrayerTimeScreen> {
  final PrayerTimeService _prayerService = PrayerTimeService.instance;
  Timer? _countdownTimer;
  Duration _countdown = Duration.zero;
  NextPrayerResult? _nextPrayer;
  List<PrayerTime> _prayerTimes = [];
  Map<String, String> _hijriDate = {};

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _loadPrayerTimes() {
    setState(() {
      _prayerTimes = _prayerService.getPrayerTimes();
      _nextPrayer = _prayerService.getNextPrayer();
      _hijriDate = _prayerService.getIslamicDate();
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  void _updateCountdown() {
    if (!mounted) return;

    final nextPrayer = _prayerService.getNextPrayer();
    if (nextPrayer != null) {
      setState(() {
        _nextPrayer = nextPrayer;
        _countdown = nextPrayer.timeRemaining;
      });

      // Trigger haptic when countdown reaches certain thresholds
      if (_countdown.inMinutes == 5 && _countdown.inSeconds % 60 == 0) {
        HapticFeedback.mediumImpact();
      } else if (_countdown.inMinutes == 1 && _countdown.inSeconds % 30 == 0) {
        HapticFeedback.heavyImpact();
      } else if (_countdown.inSeconds <= 10 && _countdown.inSeconds > 0) {
        HapticFeedback.lightImpact();
      }
    }
  }

  String _formatCountdownLarge(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20), // Dark green theme
      appBar: AppBar(
        title: const Text('Waktu Sholat'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IbadahModeToggle(
            compact: true,
            onToggle: (enabled) {
              if (enabled) {
                Navigator.of(context).pushNamed('/ibadah/mode');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Islamic date header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2E7D32),
            child: Column(
              children: [
                Text(
                  _hijriDate['day'] ?? '',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_hijriDate['month'] ?? ''} ${_hijriDate['year'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatGregorianDate(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),

          // Next prayer countdown
          if (_nextPrayer != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Text(
                    'Menjelang',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _nextPrayer!.prayer.name.indonesian,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _formatCountdownLarge(_countdown),
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _prayerService.formatPrayerTime(_nextPrayer!.prayer.time),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

          // Prayer times list
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    'Jadwal Sholat Hari Ini',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _prayerTimes.length,
                      itemBuilder: (context, index) {
                        final prayer = _prayerTimes[index];
                        return _PrayerTimeCard(
                          prayer: prayer,
                          formattedTime: _prayerService.formatPrayerTime(
                            prayer.time,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatGregorianDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Card widget for individual prayer time
class _PrayerTimeCard extends StatelessWidget {
  final PrayerTime prayer;
  final String formattedTime;

  const _PrayerTimeCard({
    required this.prayer,
    required this.formattedTime,
  });

  @override
  Widget build(BuildContext context) {
    final isNext = prayer.isNext;
    final isCurrent = prayer.isCurrent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent
            ? Colors.green.shade50
            : isNext
                ? const Color(0xFF1B5E20).withValues(alpha: 0.1)
                : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? Colors.green
              : isNext
                  ? const Color(0xFF1B5E20)
                  : Colors.grey.shade200,
          width: isCurrent || isNext ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Prayer icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCurrent
                  ? Colors.green
                  : isNext
                      ? const Color(0xFF1B5E20)
                      : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getPrayerIcon(prayer.name),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Prayer name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      prayer.name.indonesian,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isCurrent || isNext ? FontWeight.bold : FontWeight.w500,
                        color: isCurrent
                            ? Colors.green.shade800
                            : isNext
                                ? const Color(0xFF1B5E20)
                                : Colors.black87,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SAAT INI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (isNext && !isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEXT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  prayer.name.english,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Time
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isCurrent
                  ? Colors.green.shade800
                  : isNext
                      ? const Color(0xFF1B5E20)
                      : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPrayerIcon(PrayerName name) {
    switch (name) {
      case PrayerName.fajr:
        return Icons.wb_twilight;
      case PrayerName.dhuhr:
        return Icons.wb_sunny;
      case PrayerName.asr:
        return Icons.sunny_snowing;
      case PrayerName.maghrib:
        return Icons.nights_stay;
      case PrayerName.isha:
        return Icons.bedtime;
      case PrayerName.sunrise:
        return Icons.wb_sunny;
    }
  }
}
