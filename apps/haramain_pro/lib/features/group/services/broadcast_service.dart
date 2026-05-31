import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/group_model.dart';
import '../../../../supabase/supabase_client.dart';

/// Result of broadcast operation
class BroadcastResult {
  final bool success;
  final String? error;
  final String? broadcastId;
  final DateTime? nextAllowedTime;

  const BroadcastResult({
    required this.success,
    this.error,
    this.broadcastId,
    this.nextAllowedTime,
  });
}

/// Broadcast service — history and rate-limit stored in Supabase `broadcast_logs`
/// FCM sending requires a backend Edge Function (not called directly from client)
class BroadcastService {
  static final BroadcastService _instance = BroadcastService._internal();
  static BroadcastService get instance => _instance;

  BroadcastService._internal();

  SupabaseClient get _sb => SupabaseClientWrapper.instance.client;

  static const int _rateLimitMinutes = 5; // 1 broadcast per 5 minutes

  /// Check if user can broadcast (rate limit check via broadcast_logs)
  Future<bool> canBroadcast(String muthawifId, String groupId) async {
    final lastBroadcast = await _getLastBroadcastTime(muthawifId, groupId);
    if (lastBroadcast == null) return true;

    final nextAllowed = lastBroadcast.add(const Duration(minutes: _rateLimitMinutes));
    return DateTime.now().isAfter(nextAllowed);
  }

  /// Get time remaining until next broadcast is allowed
  Future<Duration> getTimeUntilNextBroadcast(String muthawifId, String groupId) async {
    final lastBroadcast = await _getLastBroadcastTime(muthawifId, groupId);
    if (lastBroadcast == null) return Duration.zero;

    final nextAllowed = lastBroadcast.add(const Duration(minutes: _rateLimitMinutes));
    final remaining = nextAllowed.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get remaining seconds until next broadcast
  Future<int> getRemainingSeconds(String muthawifId, String groupId) async {
    final remaining = await getTimeUntilNextBroadcast(muthawifId, groupId);
    return remaining.inSeconds;
  }

  /// Send broadcast to all group members
  Future<BroadcastResult> sendBroadcast({
    required String muthawifId,
    required String senderName,
    required String groupId,
    required List<MemberModel> members,
    required String message,
    String? imageUrl,
  }) async {
    try {
      // Rate limit check
      if (!await canBroadcast(muthawifId, groupId)) {
        final remaining = await getTimeUntilNextBroadcast(muthawifId, groupId);
        return BroadcastResult(
          success: false,
          error: 'Rate limit active. Next broadcast in ${remaining.inMinutes}m ${remaining.inSeconds % 60}s',
          nextAllowedTime: DateTime.now().add(remaining),
        );
      }

      // Validate message
      if (message.trim().isEmpty) {
        return BroadcastResult(
          success: false,
          error: 'Message cannot be empty',
        );
      }

      if (message.length > 1000) {
        return BroadcastResult(
          success: false,
          error: 'Message too long. Maximum 1000 characters.',
        );
      }

      // Insert broadcast into Supabase
      final broadcastId = const Uuid().v4();
      await _sb.from('broadcast_logs').insert({
        'id': broadcastId,
        'group_id': groupId,
        'sender_id': muthawifId,
        'sender_name': senderName,
        'message': message.trim(),
        'image_url': imageUrl,
      });

      broadcastDebugPrint('Broadcast saved: $broadcastId to ${members.length} members');

      return BroadcastResult(
        success: true,
        broadcastId: broadcastId,
      );
    } catch (e) {
      broadcastDebugPrint('Error sending broadcast: $e');
      return BroadcastResult(
        success: false,
        error: 'Failed to send broadcast: $e',
      );
    }
  }

  /// Get broadcast history for a group (newest first)
  Future<List<BroadcastModel>> getBroadcastHistory(String groupId) async {
    final result = await _sb
        .from('broadcast_logs')
        .select()
        .eq('group_id', groupId)
        .order('sent_at', ascending: false)
        .limit(50);

    return (result as List)
        .map((e) => BroadcastModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // Private helpers

  /// Get the most recent broadcast time for a sender in a group
  Future<DateTime?> _getLastBroadcastTime(String muthawifId, String groupId) async {
    final result = await _sb
        .from('broadcast_logs')
        .select('sent_at')
        .eq('group_id', groupId)
        .eq('sender_id', muthawifId)
        .order('sent_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (result == null) return null;
    return DateTime.parse(result['sent_at'] as String);
  }
}

// Debug print helper
void broadcastDebugPrint(String message) {
  // ignore: avoid_print
  print('[BroadcastService] $message');
}
