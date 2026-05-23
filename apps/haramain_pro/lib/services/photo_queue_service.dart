import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
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
}

class PhotoQueueService {
  static final PhotoQueueService _instance = PhotoQueueService._internal();
  static PhotoQueueService get instance => _instance;
  PhotoQueueService._internal();

  static const String _queueKey = 'photo_queue';
  bool _isInitialized = false;

  Future<void> initialize() async {
    _isInitialized = true;
  }

  Future<List<PhotoQueueItem>> _loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_queueKey);
    if (queueJson == null) return [];

    final List<dynamic> decoded = jsonDecode(queueJson);
    return decoded.map((e) => PhotoQueueItem.fromJson(e)).toList();
  }

  Future<void> _saveQueue(List<PhotoQueueItem> queue) async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = jsonEncode(queue.map((e) => e.toJson()).toList());
    await prefs.setString(_queueKey, queueJson);
  }

  Future<void> addToQueue({
    required String localPath,
    required Uint8List imageData,
    required double lat,
    required double lng,
    String? caption,
  }) async {
    if (!_isInitialized) await initialize();

    final item = PhotoQueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      localPath: localPath,
      imageData: imageData,
      lat: lat,
      lng: lng,
      createdAt: DateTime.now(),
      caption: caption,
      isSynced: false,
    );

    final queue = await _loadQueue();
    queue.add(item);
    await _saveQueue(queue);
  }

  Future<void> processQueue() async {
    if (!_isInitialized) await initialize();

    final queue = await _loadQueue();
    final unsyncedItems = queue.where((item) => !item.isSynced).toList();

    for (final item in unsyncedItems) {
      await _syncItem(item);
    }
  }

  Future<void> _syncItem(PhotoQueueItem item) async {
    try {
      final storage = StorageService.instance;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        item.errorMessage = 'User not authenticated';
        await _updateItem(item);
        return;
      }

      final remoteUrl = await storage.uploadJejakIbadahPhoto(
        userId: userId,
        fileBytes: item.imageData!,
        lat: item.lat,
        lng: item.lng,
      );

      if (remoteUrl != null) {
        item.isSynced = true;
        item.remoteUrl = remoteUrl;
        await _updateItem(item);
        debugPrint('Photo synced: $remoteUrl');
      }
    } catch (e) {
      item.errorMessage = e.toString();
      await _updateItem(item);
      debugPrint('Photo sync failed: $e');
    }
  }

  Future<void> _updateItem(PhotoQueueItem updatedItem) async {
    final queue = await _loadQueue();
    final index = queue.indexWhere((item) => item.id == updatedItem.id);
    if (index >= 0) {
      queue[index] = updatedItem;
      await _saveQueue(queue);
    }
  }

  Future<Map<String, int>> getQueueStatus() async {
    final queue = await _loadQueue();
    final total = queue.length;
    final synced = queue.where((item) => item.isSynced).length;
    final pending = total - synced;

    return {
      'total': total,
      'synced': synced,
      'pending': pending,
    };
  }

  Future<List<PhotoQueueItem>> getPendingItems() async {
    final queue = await _loadQueue();
    return queue.where((item) => !item.isSynced).toList();
  }

  Future<void> clearSyncedItems() async {
    final queue = await _loadQueue();
    queue.removeWhere((item) => item.isSynced);
    await _saveQueue(queue);
  }

  Future<void> retryFailedItems() async {
    final queue = await _loadQueue();
    final failedItems = queue.where((item) => !item.isSynced && item.errorMessage != null).toList();

    for (final item in failedItems) {
      item.errorMessage = null;
      await _updateItem(item);
      await _syncItem(item);
    }
  }
}
