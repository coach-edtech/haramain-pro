import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;
  StorageService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  Future<String?> uploadAgencyLogo({
    required String agencyId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final extension = p.extension(fileName).toLowerCase();
      final validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      if (!validExtensions.contains(extension)) {
        throw Exception('Invalid file type. Allowed: jpg, png, webp');
      }

      if (fileBytes.length > 10 * 1024 * 1024) {
        throw Exception('File too large. Max 10MB');
      }

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/upload_$fileName');
      await tempFile.writeAsBytes(fileBytes);

      final path = '$agencyId/logo$extension';
      
      await _client.storage
        .from('agency_logos')
        .upload(path, tempFile);

      await tempFile.delete();

      final url = _client.storage
        .from('agency_logos')
        .getPublicUrl(path);
      return url;
    } catch (e) {
      debugPrint('Error uploading agency logo: $e');
      return null;
    }
  }

  Future<String?> uploadJejakIbadahPhoto({
    required String userId,
    required Uint8List fileBytes,
    required double lat,
    required double lng,
  }) async {
    try {
      if (fileBytes.length > 5 * 1024 * 1024) {
        throw Exception('File too large. Max 5MB');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${timestamp}_${lat.toStringAsFixed(6)}_${lng.toStringAsFixed(6)}.webp';
      final path = '$userId/$fileName';
      
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/upload_$fileName');
      await tempFile.writeAsBytes(fileBytes);

      await _client.storage
        .from('jejak_ibadah_media')
        .upload(path, tempFile);

      await tempFile.delete();

      final url = _client.storage
        .from('jejak_ibadah_media')
        .getPublicUrl(path);
      return url;
    } catch (e) {
      debugPrint('Error uploading jejak ibadah photo: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUserPhotos(String userId) async {
    try {
      final response = await _client.storage
        .from('jejak_ibadah_media')
        .list(path: userId);
      return response.map((f) => {'name': f.name, 'id': f.id}).toList();
    } catch (e) {
      debugPrint('Error listing user photos: $e');
      return [];
    }
  }

  Future<bool> deleteJejakIbadahPhoto(String fullPath) async {
    try {
      await _client.storage
        .from('jejak_ibadah_media')
        .remove([fullPath]);
      return true;
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      return false;
    }
  }

  Future<Uint8List?> getMapTile(String region, int z, int x, int y) async {
    try {
      final path = '$region/$z/$x/$y.png';
      final data = await _client.storage
        .from('offline_maps')
        .download(path);
      return data;
    } catch (e) {
      debugPrint('Error downloading map tile: $e');
      return null;
    }
  }

  Future<bool> uploadMapTile({
    required String region,
    required int z,
    required int x,
    required int y,
    required Uint8List tileBytes,
  }) async {
    try {
      final path = '$region/$z/$x/$y.png';
      
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/tile_$x-$y.png');
      await tempFile.writeAsBytes(tileBytes);

      await _client.storage
        .from('offline_maps')
        .upload(path, tempFile);

      await tempFile.delete();
      return true;
    } catch (e) {
      debugPrint('Error uploading map tile: $e');
      return false;
    }
  }

  Future<bool> mapRegionExists(String region) async {
    try {
      final response = await _client.storage
        .from('offline_maps')
        .list(path: region);
      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking map region: $e');
      return false;
    }
  }

  Future<bool> deleteMapRegion(String region) async {
    try {
      final files = await _client.storage
        .from('offline_maps')
        .list(path: region);
      
      if (files.isEmpty) return true;
      
      final paths = files.map((f) => '$region/${f.name}').toList();
      await _client.storage
        .from('offline_maps')
        .remove(paths);
      return true;
    } catch (e) {
      debugPrint('Error deleting map region: $e');
      return false;
    }
  }
}
