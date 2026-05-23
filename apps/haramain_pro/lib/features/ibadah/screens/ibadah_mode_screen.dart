import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/prayer_time_service.dart';
import '../services/ibadah_mode_service.dart';
import '../services/geofence_service.dart';
import '../../panic/panic_button_widget.dart';
import '../../../services/location_service.dart';
import '../../../models/user_model.dart';

class IbadahModeScreen extends StatefulWidget {
  const IbadahModeScreen({super.key});

  @override
  State<IbadahModeScreen> createState() => _IbadahModeScreenState();
}

class _IbadahModeScreenState extends State<IbadahModeScreen> {
  final PrayerTimeService _prayerService = PrayerTimeService.instance;
  final IbadahModeService _ibadahService = IbadahModeService.instance;
  final GeofenceService _geofenceService = GeofenceService.instance;

  Timer? _countdownTimer;
  Duration _countdown = Duration.zero;
  NextPrayerResult? _nextPrayer;
  PrayerTime? _currentPrayer;
  Map<String, String> _hijriDate = {};

  String _jamaaahId = '';
  String _grupId = '';
  LocationData? _currentLocation;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startCountdownTimer();
    _getCurrentLocation();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response != null && mounted) {
      final profile = UserProfile.fromJson(response as Map<String, dynamic>);
      setState(() {
        _profile = profile;
        _jamaaahId = profile.id;
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _prayerTimes = _prayerService.getPrayerTimes();
      _nextPrayer = _prayerService.getNextPrayer();
      _currentPrayer = _prayerService.getCurrentPrayer();
      _hijriDate = _prayerService.getIslamicDate();
    });
  }

  List<PrayerTime> _prayerTimes = [];

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

      // Trigger haptic at key moments
      if (_countdown.inMinutes == 5 && _countdown.inSeconds == 0) {
        HapticFeedback.mediumImpact();
      } else if (_countdown.inMinutes == 1 && _countdown.inSeconds == 0) {
        HapticFeedback.heavyImpact();
      } else if (_countdown.inSeconds <= 10 && _countdown.inSeconds > 0) {
        HapticFeedback.lightImpact();
      } else if (_countdown.inSeconds == 0) {
        // Prayer time reached
        HapticFeedback.heavyImpact();
        _prayerService.triggerPrayerReminder();
        _loadData(); // Refresh prayer times
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    final location = await LocationService.instance.getCurrentLocation();
    if (mounted) {
      setState(() => _currentLocation = location);
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

  Future<void> _endIbadahMode() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Akhiri режим Ibadah?'),
        content: const Text(
          'Apakah Anda yakin ingin mengakhiri режим Ibadah? '
          'Notifikasi akan dikembalikan seperti biasa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Akhiri'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _ibadahService.disableIbadahMode();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.mosque, size: 24),
            const SizedBox(width: 8),
            const Text('Ibadah Mode'),
          ],
        ),
        actions: [
          // Current location indicator
          if (_currentLocation != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getNearbyMosque(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => Navigator.of(context).pushNamed('/map'),
            tooltip: 'Buka Peta',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _endIbadahMode,
            tooltip: 'Akhiri Ibadah Mode',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Islamic date
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF2E7D32),
                child: Column(
                  children: [
                    Text(
                      '${_hijriDate['day'] ?? ''} ${_hijriDate['month'] ?? ''} ${_hijriDate['year'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatGregorianDate(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Current prayer (if any)
              if (_currentPrayer != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sedang: ${_currentPrayer!.name.indonesian}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _prayerService.formatPrayerTime(
                            _currentPrayer!.time,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Next prayer countdown - large display
              if (_nextPrayer != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'MENJELANG',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white60,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _nextPrayer!.prayer.name.indonesian,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            _formatCountdownLarge(_countdown),
                            style: const TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w200,
                              color: Colors.white,
                              fontFeatures: [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _nextPrayer!.prayer.name.english,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _prayerService.formatPrayerTime(
                            _nextPrayer!.prayer.time,
                          ),
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Prayer times list - compact
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Jadwal Sholat',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _prayerTimes.length,
                        itemBuilder: (context, index) {
                          final prayer = _prayerTimes[index];
                          final isNext = prayer.isNext;
                          final isCurrent = prayer.isCurrent;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? Colors.green.shade50
                                  : isNext
                                      ? const Color(0xFF1B5E20)
                                          .withValues(alpha: 0.1)
                                      : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCurrent
                                    ? Colors.green
                                    : isNext
                                        ? const Color(0xFF1B5E20)
                                        : Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  prayer.name.indonesian,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isCurrent || isNext
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isCurrent
                                        ? Colors.green.shade800
                                        : isNext
                                            ? const Color(0xFF1B5E20)
                                            : Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _prayerService.formatPrayerTime(
                                    prayer.time,
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
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
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),

          // Mini Panic button - always visible
          Positioned(
            bottom: 220,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 70,
                height: 70,
                child: PanicButtonWidget(
                  jamaaahId: _jamaaahId,
                  grupId: _grupId,
                  initialLocation: _currentLocation,
                  onPanicSent: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Panic alert sent!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  onPanicFailed: (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getNearbyMosque() {
    if (_currentLocation == null) return '...';

    for (final mosque in GeofenceService.mosques) {
      final distance = _geofenceService.distanceToMosque(
        mosque.id,
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );

      if (distance <= mosque.radiusInMeters) {
        return mosque.name;
      }
    }

    return 'Luar Masjid';
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
