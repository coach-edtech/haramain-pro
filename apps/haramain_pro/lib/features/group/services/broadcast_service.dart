import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/group_model.dart';

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

/// Broadcast service for sending group announcements
class BroadcastService {
  static final BroadcastService _instance = BroadcastService._internal();
  static BroadcastService get instance => _instance;

  BroadcastService._internal();

  static const String _broadcastHistoryKey = 'haramain_broadcast_history';
  static const String _lastBroadcastKey = 'haramain_last_broadcast';
  static const int _rateLimitMinutes = 5; // 1 broadcast per 5 minutes

  /// Check if user can broadcast (rate limit check)
  Future<bool> canBroadcast(String muthawifId, String groupId) async {
    final key = '${_lastBroadcastKey}_${groupId}_$muthawifId';
    final prefs = await SharedPreferences.getInstance();
    final lastBroadcastStr = prefs.getString(key);

    if (lastBroadcastStr == null) return true;

    final lastBroadcast = DateTime.parse(lastBroadcastStr);
    final nextAllowed = lastBroadcast.add(const Duration(minutes: _rateLimitMinutes));
    
    return DateTime.now().isAfter(nextAllowed);
  }

  /// Get time remaining until next broadcast is allowed
  Future<Duration> getTimeUntilNextBroadcast(String muthawifId, String groupId) async {
    final key = '${_lastBroadcastKey}_${groupId}_$muthawifId';
    final prefs = await SharedPreferences.getInstance();
    final lastBroadcastStr = prefs.getString(key);

    if (lastBroadcastStr == null) return Duration.zero;

    final lastBroadcast = DateTime.parse(lastBroadcastStr);
    final nextAllowed = lastBroadcast.add(const Duration(minutes: _rateLimitMinutes));
    final remaining = nextAllowed.difference(DateTime.now());

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Send broadcast to all group members
  Future<BroadcastResult> sendBroadcast({
    required String muthawifId,
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

      // Create broadcast
      final broadcast = BroadcastModel(
        id: const Uuid().v4(),
        groupId: groupId,
        senderId: muthawifId,
        senderName: 'Muthawif', // Will be updated with actual name
        message: message.trim(),
        imageUrl: imageUrl,
        sentAt: DateTime.now(),
      );

      // Store broadcast history
      await _saveBroadcast(groupId, broadcast);

      // Update last broadcast time
      await _updateLastBroadcastTime(muthawifId, groupId);

      // Send FCM to all members (except sender)
      await _sendFcmToMembers(broadcast, members);

      broadcastDebugPrint('Broadcast sent: ${broadcast.id} to ${members.length} members');

      return BroadcastResult(
        success: true,
        broadcastId: broadcast.id,
      );
    } catch (e) {
      broadcastDebugPrint('Error sending broadcast: $e');
      return BroadcastResult(
        success: false,
        error: 'Failed to send broadcast: $e',
      );
    }
  }

  /// Get broadcast history for a group
  Future<List<BroadcastModel>> getBroadcastHistory(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('${_broadcastHistoryKey}_$groupId');

    if (historyJson == null) return [];

    final List<dynamic> decoded = jsonDecode(historyJson);
    final broadcasts = decoded.map((e) => BroadcastModel.fromJson(e)).toList();
    
    // Sort by sent time, newest first
    broadcasts.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    
    return broadcasts;
  }

  /// Get remaining seconds until next broadcast
  Future<int> getRemainingSeconds(String muthawifId, String groupId) async {
    final remaining = await getTimeUntilNextBroadcast(muthawifId, groupId);
    return remaining.inSeconds;
  }

  // Private helper methods

  Future<void> _saveBroadcast(String groupId, BroadcastModel broadcast) async {
    final broadcasts = await getBroadcastHistory(groupId);
    broadcasts.insert(0, broadcast);

    // Keep only last 50 broadcasts
    final trimmed = broadcasts.take(50).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_broadcastHistoryKey}_$groupId',
      jsonEncode(trimmed.map((b) => b.toJson()).toList()),
    );
  }

  Future<void> _updateLastBroadcastTime(String muthawifId, String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_lastBroadcastKey}_${groupId}_$muthawifId';
    await prefs.setString(key, DateTime.now().toIso8601String());
  }

  /// Send FCM notification to all group members
  Future<void> _sendFcmToMembers(BroadcastModel broadcast, List<MemberModel> members) async {
    // TODO: Integrate with Firebase Cloud Messaging
    // For now, simulate sending
    
    for (final member in members) {
      if (member.userId == broadcast.senderId) continue; // Skip sender
      
      try {
        // In production, call FCM API to send notification to member's device
        // FCM payload would be:
        // {
        //   'notification': {
        //     'title': 'Jadwal Baru dari Muthawif',
        //     'body': broadcast.message,
        //   },
        //   'data': {
        //     'type': 'broadcast',
        //     'broadcast_id': broadcast.id,
        //     'group_id': broadcast.groupId,
        //     'image_url': broadcast.imageUrl ?? '',
        //   },
        //   'token': member_fcm_token
        // }
        
        broadcastDebugPrint('FCM sent to ${member.userId} for broadcast ${broadcast.id}');
      } catch (e) {
        broadcastDebugPrint('Failed to send FCM to ${member.userId}: $e');
      }
    }
  }
}

// Debug print helper
void broadcastDebugPrint(String message) {
  // ignore: avoid_print
  print('[BroadcastService] $message');
}
