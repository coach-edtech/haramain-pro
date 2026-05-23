import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haramain_pro/features/jejak_ibadah/screens/camera_screen.dart';
import 'package:haramain_pro/features/jejak_ibadah/widgets/photo_card.dart';
import 'package:haramain_pro/features/jejak_ibadah/widgets/sync_status_bar.dart';
import 'package:haramain_pro/features/jejak_ibadah/services/jejak_ibadah_service.dart';

class JejakIbadahScreen extends ConsumerStatefulWidget {
  const JejakIbadahScreen({super.key});

  @override
  ConsumerState<JejakIbadahScreen> createState() => _JejakIbadahScreenState();
}

class _JejakIbadahScreenState extends ConsumerState<JejakIbadahScreen> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    await JejakIbadahService.instance.initialize();
  }

  Future<void> _syncPhotos() async {
    setState(() => _isSyncing = true);
    try {
      await JejakIbadahService.instance.syncPendingPhotos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photos synced successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  void _openCamera() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          onPhotoCaptured: () {
            Navigator.of(context).pop();
            setState(() {}); // Refresh
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queueStatus = ref.watch(queueStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jejak Ibadah'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          queueStatus.when(
            data: (status) {
              final pending = status['pending'] as int? ?? 0;
              if (pending > 0) {
                return IconButton(
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.sync),
                  onPressed: _isSyncing ? null : _syncPhotos,
                  tooltip: 'Sync $pending photos',
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sync status bar
          queueStatus.when(
            data: (status) {
              final pending = status['pending'] as int? ?? 0;
              final synced = status['synced'] as int? ?? 0;
              if (pending > 0) {
                return SyncStatusBar(
                  pendingCount: pending,
                  syncedCount: synced,
                  onSync: _syncPhotos,
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Photo grid
          Expanded(
            child: queueStatus.when(
              data: (status) {
                final pending = status['pending'] as int? ?? 0;
                final synced = status['synced'] as int? ?? 0;
                final total = pending + synced;

                if (total == 0) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: total,
                  itemBuilder: (context, index) {
                    // Show pending first, then synced
                    if (index < pending) {
                      return PhotoCard(
                        isSynced: false,
                        timestamp: DateTime.now().subtract(
                          Duration(minutes: pending - index),
                        ),
                        location: 'Pending sync...',
                      );
                    } else {
                      return PhotoCard(
                        isSynced: true,
                        timestamp: DateTime.now().subtract(
                          Duration(minutes: total - index),
                        ),
                        location: 'Synced',
                      );
                    }
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCamera,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Capture'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No photos yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start capturing your pilgrimage journey',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take First Photo'),
          ),
        ],
      ),
    );
  }
}

// Provider for queue status
final queueStatusProvider = FutureProvider<Map<String, int>>((ref) async {
  return await JejakIbadahService.instance.getQueueStatus();
});
