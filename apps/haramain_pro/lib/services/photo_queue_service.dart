import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'storage_service.dart';

class PhotoQueueItem {
  final String id;
  final String localPath;
  final Uint8List? imageData;
  final double lat;
  final double lng;
  final DateTime createdAt;
  final String? caption;
  bool isSynced;
  String? remoteUrl;
  String? errorMessage;

  PhotoQueueItem({
    required this.id,
    required this.localPath,
    this.imageData,
    required this.lat,
    required this.lng,
    required this.createdAt,
    this.caption,
    this.isSynced = false,
    this.remoteUrl,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'localPath': localPath,
      'imageData': imageData != null ? base64Encode(imageData!) : null,
      'lat': lat,
      'lng': lng,
      'createdAt': createdAt.toIso8601String(),
      'caption': caption,
      'isSynced': isSynced,
      'remoteUrl': remoteUrl,
      'errorMessage': errorMessage,
    };
  }

  factory PhotoQueueItem.fromJson(Map<String, dynamic> json) {
    return PhotoQueueItem(
      id: json['id'] as String,
      localPath: json['localPath'] as String,
      imageData: json['imageData'] != null ? base64Decode(json['imageData'] as String) : null,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      caption: json['caption'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      remoteUrl: json['remoteUrl'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Create from Supabase row (no local imageData — fetched from localPath)
  factory PhotoQueueItem.fromSupabase(Map<String, dynamic> row) {
    return PhotoQueueItem(
      id: row['id'] as String,
      localPath: '', // not stored in Supabase
      imageData: null,
      lat: (row['lat'] as num).toDouble(),
      lng: (row['lng'] as num).toDouble(),
      createdAt: DateTime.parse(row['created_at'] as String),
      caption: null,
      isSynced: false,
      remoteUrl: null,
      errorMessage: null,
    );
  }
}

class PhotoQueueService {
  static final PhotoQueueService _instance = PhotoQueueService._internal();
  static PhotoQueueService get instance => _instance;
  PhotoQueueService._internal();

  SupabaseClient get _sb => Supabase.instance.client;
  bool _isInitialized = false;

  Future<void> initialize() async {
    _isInitialized = true;
  }

  /// Load all photo queue items for current user from Supabase
  Future<List<PhotoQueueItem>> _loadQueue() async {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) return [];

    final result = await _sb
        .from('photo_queue')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return (result as List)
        .map((e) => PhotoQueueItem.fromSupabase(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Add photo to queue — insert into Supabase
  Future<void> addToQueue({
    required String localPath,
    required Uint8List imageData,
    required double lat,
    required double lng,
    String? caption,
  }) async {
    if (!_isInitialized) await initialize();

    final userId = _sb.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('PhotoQueueService: No authenticated user');
      return;
    }

    // Store base64 in Supabase for offline sync
    final itemId = const Uuid().v4();
    await _sb.from('photo_queue').insert({
      'id': itemId,
      'user_id': userId,
      'base64': base64Encode(imageData),
      'lat': lat,
      'lng': lng,
    });

    debugPrint('PhotoQueueService: Added to queue $itemId');
  }

  /// Process all pending items — upload to storage then delete from queue
  Future<void> processQueue() async {
    if (!_isInitialized) await initialize();

    final queue = await _loadQueue();
    final unsyncedItems = queue.where((item) => !item.isSynced).toList();

    for (final item in unsyncedItems) {
      await _syncItem(item);
    }
  }

  /// Sync single item: upload photo to storage then delete from queue
  Future<void> _syncItem(PhotoQueueItem item) async {
    try {
      final userId = _sb.auth.currentUser?.id;
      if (userId == null) {
        item.errorMessage = 'User not authenticated';
        return;
      }

      // Fetch base64 from Supabase since we don't have imageData locally
      final row = await _sb
          .from('photo_queue')
          .select('base64')
          .eq('id', item.id)
          .maybeSingle();

      if (row == null) {
        item.errorMessage = 'Item not found in queue';
        return;
      }

      final base64Str = row['base64'] as String?;
      if (base64Str == null || base64Str.isEmpty) {
        item.errorMessage = 'No image data found';
        return;
      }

      final imageData = base64Decode(base64Str);

      final storage = StorageService.instance;
      final remoteUrl = await storage.uploadJejakIbadahPhoto(
        userId: userId,
        fileBytes: imageData,
        lat: item.lat,
        lng: item.lng,
      );

      if (remoteUrl != null) {
        // Delete from Supabase queue after successful upload
        await _sb.from('photo_queue').delete().eq('id', item.id);
        debugPrint('PhotoQueueService: Synced and removed ${item.id}');
      }
    } catch (e) {
      item.errorMessage = e.toString();
      debugPrint('PhotoQueueService: Sync failed for ${item.id}: $e');
    }
  }

  Future<Map<String, int>> getQueueStatus() async {
    final queue = await _loadQueue();
    final total = queue.length;
    // Since we don't track sync status in Supabase, pending = all
    final pending = total;
    return {'total': total, 'synced': 0, 'pending': pending};
  }

  Future<List<PhotoQueueItem>> getPendingItems() async {
    return _loadQueue();
  }

  Future<void> clearSyncedItems() async {
    // No-op: synced items are already deleted from Supabase
    debugPrint('PhotoQueueService: clearSyncedItems — no action needed');
  }

  Future<void> retryFailedItems() async {
    // Re-process all items
    await processQueue();
  }
}
