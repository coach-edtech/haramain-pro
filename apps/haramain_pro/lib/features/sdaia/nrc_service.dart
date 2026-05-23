import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'nrc_model.dart';

class NrcService {
  static final NrcService _instance = NrcService._internal();
  static NrcService get instance => _instance;
  NrcService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  Future<NrcRegistration?> getCurrentUserNrc() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('nrc_registrations')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) return null;

      return NrcRegistration.fromJson(response);
    } catch (e) {
      print('Error getting NRC: $e');
      return null;
    }
  }

  Future<NrcRegistration> saveDraft(NrcRegistration registration) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final existing = await getCurrentUserNrc();

      if (existing != null) {
        final updated = registration.copyWith(
          id: existing.id,
          status: NrcStatus.draft,
        );

        await _client
            .from('nrc_registrations')
            .update(updated.toJson())
            .eq('id', existing.id);

        return updated;
      } else {
        final newReg = registration.copyWith(
          userId: user.id,
          status: NrcStatus.draft,
        );

        final response = await _client
            .from('nrc_registrations')
            .insert(newReg.toJson())
            .select()
            .single();

        return NrcRegistration.fromJson(response);
      }
    } catch (e) {
      print('Error saving NRC draft: $e');
      rethrow;
    }
  }

  Future<NrcRegistration> submitNrc(String registrationId) async {
    try {
      final response = await _client
          .from('nrc_registrations')
          .update({
            'status': 'submitted',
            'submitted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', registrationId)
          .select()
          .single();

      return NrcRegistration.fromJson(response);
    } catch (e) {
      print('Error submitting NRC: $e');
      rethrow;
    }
  }

  Future<String?> uploadPassportImage(String registrationId, Uint8List imageBytes) async {
    try {
      final path = '$registrationId/passport_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _client.storage
          .from('nrc_documents')
          .uploadBinary(path, imageBytes);

      final url = _client.storage
          .from('nrc_documents')
          .getPublicUrl(path);

      await _client
          .from('nrc_registrations')
          .update({'passport_image_url': url})
          .eq('id', registrationId);

      return url;
    } catch (e) {
      print('Error uploading passport image: $e');
      return null;
    }
  }

  Future<String?> uploadVisaImage(String registrationId, Uint8List imageBytes) async {
    try {
      final path = '$registrationId/visa_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _client.storage
          .from('nrc_documents')
          .uploadBinary(path, imageBytes);

      final url = _client.storage
          .from('nrc_documents')
          .getPublicUrl(path);

      await _client
          .from('nrc_registrations')
          .update({'visa_image_url': url})
          .eq('id', registrationId);

      return url;
    } catch (e) {
      print('Error uploading visa image: $e');
      return null;
    }
  }

  Future<bool> hasCompletedNrc() async {
    final nrc = await getCurrentUserNrc();
    return nrc != null && nrc.status == NrcStatus.approved;
  }

  Future<bool> isNrcRequired() async {
    final nrc = await getCurrentUserNrc();
    if (nrc == null) return true;
    return nrc.status != NrcStatus.approved;
  }
}

void _print(String message) {
  print('[NrcService] $message');
}
