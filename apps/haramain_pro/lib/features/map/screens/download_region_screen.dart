import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/map_region_model.dart';
import '../services/offline_tile_service.dart';

/// Screen for downloading and managing offline map regions
class DownloadRegionScreen extends StatefulWidget {
  const DownloadRegionScreen({super.key});

  @override
  State<DownloadRegionScreen> createState() => _DownloadRegionScreenState();
}

class _DownloadRegionScreenState extends State<DownloadRegionScreen> {
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};
  final Set<String> _downloadedRegions = {};
  final Set<String> _selectedForDeletion = {};
  bool _isWifiAvailable = false;
  double _totalDownloadedSize = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await OfflineTileService.instance.initialize();
    await _checkConnectivity();
    await _loadDownloadedRegions();
    _loadTotalSize();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isWifiAvailable = connectivityResult.contains(ConnectivityResult.wifi);
    });
  }

  Future<void> _loadDownloadedRegions() async {
    final downloaded = await OfflineTileService.instance.getDownloadedRegions();
    setState(() {
      _downloadedRegions.clear();
      for (final region in downloaded) {
        _downloadedRegions.add(region.code);
      }
    });
  }

  Future<void> _loadTotalSize() async {
    final size = await OfflineTileService.instance.getTotalDownloadedSizeMb();
    setState(() {
      _totalDownloadedSize = size;
    });
  }

  Future<void> _downloadRegion(MapRegionModel region) async {
    // Check WiFi if not available
    if (!_isWifiAvailable) {
      final shouldContinue = await _showWifiWarning();
      if (!shouldContinue) return;
    }

    setState(() {
      _isDownloading[region.code] = true;
      _downloadProgress[region.code] = 0.0;
    });

    try {
      await for (final progress in OfflineTileService.instance.downloadRegion(region)) {
        if (mounted) {
          setState(() {
            _downloadProgress[region.code] = progress;
          });
        }
      }

      if (mounted) {
        setState(() {
          _downloadedRegions.add(region.code);
          _isDownloading[region.code] = false;
          _downloadProgress.remove(region.code);
        });
        _loadTotalSize();
        _showSnackBar('${region.displayName} berhasil diunduh');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading[region.code] = false;
          _downloadProgress.remove(region.code);
        });
        _showSnackBar('Gagal mengunduh ${region.displayName}: $e');
      }
    }
  }

  Future<void> _deleteRegion(MapRegionModel region) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Region'),
        content: Text(
          'Hapus peta offline ${region.displayName}? Data yang sudah diunduh akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await OfflineTileService.instance.deleteRegion(region);
        if (mounted) {
          setState(() {
            _downloadedRegions.remove(region.code);
            _selectedForDeletion.remove(region.code);
          });
          _loadTotalSize();
          _showSnackBar('${region.displayName} berhasil dihapus');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Gagal menghapus ${region.displayName}: $e');
        }
      }
    }
  }

  Future<bool> _showWifiWarning() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Peringatan'),
          ],
        ),
        content: const Text(
          'WiFi tidak tersedia. Mengunduh peta offline menggunakan data seluler '
          'dapat memakan biaya mahal dan waktu yang lama.\n\n'
          'Disarankan untuk mengunduh melalui WiFi sebelum keberangkatan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tetap Unduh'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<double> _getRegionSize(MapRegionModel region) async {
    return OfflineTileService.instance.calculateRegionSizeMb(region);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unduh Peta Offline'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WiFi status banner
          if (!_isWifiAvailable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'WiFi tidak terhubung. Download menggunakan data seluler.',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
          // Total downloaded size
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total ukuran download:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_totalDownloadedSize.toStringAsFixed(1)} MB',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Info card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Unduh peta sebelum keberangkatan via WiFi untuk pengalaman offline 100%. '
                    'Ukuran maksimal 300MB.',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // Region list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: MapRegions.all.length,
              itemBuilder: (context, index) {
                final region = MapRegions.all[index];
                return _buildRegionCard(region);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionCard(MapRegionModel region) {
    final isDownloaded = _downloadedRegions.contains(region.code);
    final isDownloading = _isDownloading[region.code] ?? false;
    final progress = _downloadProgress[region.code] ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.map,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        region.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FutureBuilder<double>(
                        future: _getRegionSize(region),
                        builder: (context, snapshot) {
                          final size = snapshot.data ?? 0;
                          return Text(
                            'Estimasi: ${size.toStringAsFixed(1)} MB',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (isDownloaded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Tersedia',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Download progress bar
            if (isDownloading)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mengunduh... ${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  if (!isDownloaded)
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Unduh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _downloadRegion(region),
                      ),
                    ),
                  if (isDownloaded) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Hapus'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        onPressed: () => _deleteRegion(region),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.offline_pin, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Offline Ready',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
