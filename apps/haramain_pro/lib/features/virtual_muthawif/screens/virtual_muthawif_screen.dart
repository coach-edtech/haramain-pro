import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haramain_pro/features/virtual_muthawif/services/virtual_muthawif_service.dart';
import 'package:haramain_pro/features/virtual_muthawif/widgets/prayer_card.dart';
import 'package:haramain_pro/features/virtual_muthawif/widgets/zone_indicator.dart';

class VirtualMuthawifScreen extends ConsumerStatefulWidget {
  const VirtualMuthawifScreen({super.key});

  @override
  ConsumerState<VirtualMuthawifScreen> createState() => _VirtualMuthawifScreenState();
}

class _VirtualMuthawifScreenState extends ConsumerState<VirtualMuthawifScreen> {
  final VirtualMuthawifService _service = VirtualMuthawifService.instance;
  String? _currentZone;
  String? _prayerSuggestion;

  @override
  void initState() {
    super.initState();
    _service.startTracking();
    _service.onZoneChanged.listen((zone) {
      setState(() {
        _currentZone = zone;
        _prayerSuggestion = _service.getPrayerSuggestion();
      });
    });
  }

  @override
  void dispose() {
    _service.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Muthawif'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone indicator
            ZoneIndicator(
              currentZone: _currentZone,
              onZoneChanged: (zone) {
                setState(() {
                  _currentZone = zone;
                });
              },
            ),
            const SizedBox(height: 24),

            // Current location prayer card
            if (_currentZone != null) ...[
              Text(
                'Doa untuk Zona Anda',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              PrayerCard(
                zoneId: _currentZone!,
                compact: false,
              ),
            ] else ...[
              // No zone detected
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak Ada di Zona Suci',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Datanglah ke Ka\'bah, Masjid Nabawi, atau zona suci lainnya untuk mendapatkan doa yang sesuai.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Prayer suggestion
            if (_prayerSuggestion != null) ...[
              Text(
                'Saran Ibadah',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _prayerSuggestion!,
                    style: const TextStyle(height: 1.6),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Zone list
            Text(
              'Zona Suci Tersedia',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildZoneList(),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneList() {
    final zones = _service.getAllZones();
    
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: zones.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final zone = zones[index];
          final isActive = _currentZone == zone['id'];
          
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive ? Colors.green[100] : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  zone['arabic'] ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    color: isActive ? Colors.green[700] : Colors.grey[600],
                  ),
                ),
              ),
            ),
            title: Text(
              zone['name'] ?? '',
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.green[700] : null,
              ),
            ),
            subtitle: Text(
              zone['description'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: isActive
                ? Icon(Icons.check_circle, color: Colors.green[600])
                : null,
            onTap: () {
              setState(() {
                _currentZone = zone['id'];
                _prayerSuggestion = _service.getPrayerSuggestion();
              });
            },
          );
        },
      ),
    );
  }
}
