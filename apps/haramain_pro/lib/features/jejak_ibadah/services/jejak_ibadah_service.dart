import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:haramain_pro/services/photo_queue_service.dart';
import 'package:haramain_pro/services/storage_service.dart';
import 'package:haramain_pro/services/location_service.dart';

class JejakIbadahService {
  static final JejakIbadahService _instance = JejakIbadahService._internal();
  static JejakIbadahService get instance => _instance;
  JejakIbadahService._internal();

  final PhotoQueueService _queueService = PhotoQueueService.instance;
  final StorageService _storageService = StorageService.instance;

  /// Initialize the service
  Future<void> initialize() async {
    await _queueService.initialize();
  }

  /// Capture and queue a photo
  Future<bool> capturePhoto({
    required Uint8List imageBytes,
    required double lat,
    required double lng,
    String? caption,
  }) async {
    try {
      // Compress if needed
      final compressedBytes = await _compressImage(imageBytes);
      
      // Add to queue
      await _queueService.addToQueue(
        localPath: 'pending_${DateTime.now().millisecondsSinceEpoch}',
        imageData: compressedBytes,
        lat: lat,
        lng: lng,
        caption: caption,
      );

      return true;
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      return false;
    }
  }

  /// Capture with current location
  Future<bool> capturePhotoWithLocation({
    required Uint8List imageBytes,
    String? caption,
  }) async {
    try {
      final locationData = await LocationService.instance.getCurrentLocation();
      
      if (locationData == null) {
        // Use default coordinates if location unavailable
        return await capturePhoto(
          imageBytes: imageBytes,
          lat: 0,
          lng: 0,
          caption: caption,
        );
      }

      return await capturePhoto(
        imageBytes: imageBytes,
        lat: locationData.latitude,
        lng: locationData.longitude,
        caption: caption,
      );
    } catch (e) {
      debugPrint('Error capturing photo with location: $e');
      return false;
    }
  }

  /// Process pending queue (sync with server)
  Future<void> syncPendingPhotos() async {
    await _queueService.processQueue();
  }

  /// Get queue status
  Future<Map<String, int>> getQueueStatus() async {
    return await _queueService.getQueueStatus();
  }

  /// Get pending count
  Future<int> getPendingCount() async {
    final items = await _queueService.getPendingItems();
    return items.length;
  }

  /// Retry failed uploads
  Future<void> retryFailedUploads() async {
    await _queueService.retryFailedItems();
  }

  /// Clear synced items
  Future<void> clearSyncedItems() async {
    await _queueService.clearSyncedItems();
  }

  /// Compress image for upload
  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    // In production, use image package or flutter_image_compress
    // For now, return as-is (already compressed by camera)
    const maxSize = 1024 * 1024; // 1MB max
    
    if (imageBytes.length <= maxSize) {
      return imageBytes;
    }

    // Placeholder for compression
    // In production, use:
    // final compressed = await FlutterImageCompress.compressWithList(
    //   imageBytes,
    //   quality: 85,
    //   minWidth: 1024,
    //   minHeight: 1024,
    // );
    // return Uint8List.fromList(compressed);
    
    return imageBytes;
  }

  /// Get all synced photos from server
  Future<List<Map<String, dynamic>>> getSyncedPhotos() async {
    try {
      final userId = _storageService.getCurrentUserId();
      if (userId == null) return [];

      return await _storageService.getUserPhotos(userId);
    } catch (e) {
      debugPrint('Error getting synced photos: $e');
      return [];
    }
  }

  /// Delete a photo
  Future<bool> deletePhoto(String photoPath) async {
    try {
      return await _storageService.deleteJejakIbadahPhoto(photoPath);
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      return false;
    }
  }
}
