import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/group_model.dart';
import '../../../../supabase/supabase_client.dart';

/// Service result wrapper
class ServiceResult<T> {
  final bool success;
  final T? data;
  final String? error;

  const ServiceResult({
    required this.success,
    this.data,
    this.error,
  });

  factory ServiceResult.ok(T data) => ServiceResult(success: true, data: data);
  factory ServiceResult.fail(String error) =>
      ServiceResult(success: false, error: error);
}

/// Group service — all group data stored in Supabase
/// Tables: groups, group_members, broadcast_logs
class GroupService {
  static final GroupService _instance = GroupService._internal();
  static GroupService get instance => _instance;

  GroupService._internal();

  SupabaseClient get _sb => SupabaseClientWrapper.instance.client;

  /// Generate a 6-character alphanumeric PIN
  String generatePin() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed ambiguous chars
    final random = DateTime.now().millisecondsSinceEpoch;
    String pin = '';
    int seed = random;
    for (int i = 0; i < 6; i++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      pin += chars[seed % chars.length];
    }
    return pin;
  }

  /// Generate QR code payload for a group
  String generateQRCode(String groupId, String pin) {
    return 'haramain://group/join?id=$groupId&pin=$pin';
  }

  /// Create a new group (Muthawif creates group)
  Future<ServiceResult<GroupModel>> createGroup({
    required String muthawifId,
    required String muthawifName,
    required String name,
  }) async {
    try {
      // Generate PIN and QR data
      final pin = generatePin();
      final groupId = const Uuid().v4();
      final qrData = generateQRCode(groupId, pin);

      // Insert group into Supabase
      await _sb.from('groups').insert({
        'id': groupId,
        'name': name,
        'pin': pin,
        'qr_data': qrData,
        'muthawif_id': muthawifId,
        'max_members': 100,
      });

      // Insert owner as first member
      await _sb.from('group_members').insert({
        'group_id': groupId,
        'user_id': muthawifId,
        'user_name': muthawifName,
        'role': 'owner',
      });

      final group = GroupModel(
        id: groupId,
        name: name,
        pin: pin,
        qrData: qrData,
        muthawifId: muthawifId,
        maxMembers: 100,
        createdAt: DateTime.now(),
        memberCount: 1,
      );

      groupDebugPrint('Group created: $groupId with PIN: $pin');
      return ServiceResult.ok(group);
    } catch (e) {
      groupDebugPrint('Error creating group: $e');
      return ServiceResult.fail('Failed to create group: $e');
    }
  }

  /// Join a group using PIN (Jamaah joins)
  Future<ServiceResult<GroupModel>> joinGroup({
    required String jamaahId,
    required String jamaahName,
    required String pin,
  }) async {
    try {
      // Find group by PIN — query by exact pin
      final pinUpper = pin.toUpperCase();
      final groupResult = await _sb
          .from('groups')
          .select()
          .eq('pin', pinUpper)
          .maybeSingle();

      if (groupResult == null) {
        return ServiceResult.fail('Invalid PIN. Please check and try again.');
      }

      final groupData = Map<String, dynamic>.from(groupResult);
      final groupId = groupData['id'] as String;

      // Check member count
      final membersResult = await _sb
          .from('group_members')
          .select('id')
          .eq('group_id', groupId);
      final memberCount = (membersResult as List).length;
      final maxMembers = groupData['max_members'] as int? ?? 100;

      if (memberCount >= maxMembers) {
        return ServiceResult.fail('Group is full. Maximum $maxMembers members reached.');
      }

      // Check if already a member
      final existingMember = await _sb
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', jamaahId)
          .maybeSingle();

      if (existingMember != null) {
        return ServiceResult.fail('You are already a member of this group.');
      }

      // Add member
      await _sb.from('group_members').insert({
        'group_id': groupId,
        'user_id': jamaahId,
        'user_name': jamaahName,
        'role': 'member',
      });

      final group = GroupModel(
        id: groupId,
        name: groupData['name'] as String,
        pin: groupData['pin'] as String,
        qrData: groupData['qr_data'] as String? ?? '',
        muthawifId: groupData['muthawif_id'] as String,
        maxMembers: maxMembers,
        createdAt: DateTime.parse(groupData['created_at'] as String),
        memberCount: memberCount + 1,
      );

      groupDebugPrint('Jamaah $jamaahId joined group $groupId');
      return ServiceResult.ok(group);
    } catch (e) {
      groupDebugPrint('Error joining group: $e');
      return ServiceResult.fail('Failed to join group: $e');
    }
  }

  /// Join a group using QR scan data
  Future<ServiceResult<GroupModel>> joinGroupViaQR({
    required String jamaahId,
    required String jamaahName,
    required String qrData,
  }) async {
    try {
      // Parse QR data: haramain://group/join?id=xxx&pin=xxx
      final uri = Uri.parse(qrData);
      if (uri.host != 'group.join') {
        return ServiceResult.fail('Invalid QR code format.');
      }

      final groupId = uri.queryParameters['id'];
      final pin = uri.queryParameters['pin'];

      if (groupId == null || pin == null) {
        return ServiceResult.fail('Invalid QR code data.');
      }

      // Verify group exists and PIN matches
      final groupResult = await _sb
          .from('groups')
          .select()
          .eq('id', groupId)
          .maybeSingle();

      if (groupResult == null) {
        return ServiceResult.fail('Group not found.');
      }

      final groupData = Map<String, dynamic>.from(groupResult);
      if (groupData['pin'] != pin) {
        return ServiceResult.fail('Invalid PIN in QR code.');
      }

      // Join using the PIN
      return joinGroup(
        jamaahId: jamaahId,
        jamaahName: jamaahName,
        pin: pin,
      );
    } catch (e) {
      groupDebugPrint('Error joining via QR: $e');
      return ServiceResult.fail('Failed to parse QR code: $e');
    }
  }

  /// Leave a group
  Future<ServiceResult<void>> leaveGroup({
    required String jamaahId,
    required String groupId,
  }) async {
    try {
      final group = await _getGroup(groupId);
      if (group == null) {
        return ServiceResult.fail('Group not found.');
      }

      // Muthawif cannot leave their own group
      if (group.muthawifId == jamaahId) {
        return ServiceResult.fail('Muthawif cannot leave their own group. Delete the group instead.');
      }

      // Remove member
      await _sb
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', jamaahId);

      groupDebugPrint('Jamaah $jamaahId left group $groupId');
      return ServiceResult.ok(null);
    } catch (e) {
      groupDebugPrint('Error leaving group: $e');
      return ServiceResult.fail('Failed to leave group: $e');
    }
  }

  /// Remove a member (Muthawif only)
  Future<ServiceResult<void>> removeMember({
    required String muthawifId,
    required String memberId,
    required String groupId,
  }) async {
    try {
      final group = await _getGroup(groupId);
      if (group == null) {
        return ServiceResult.fail('Group not found.');
      }

      if (group.muthawifId != muthawifId) {
        return ServiceResult.fail('Only Muthawif can remove members.');
      }

      if (memberId == muthawifId) {
        return ServiceResult.fail('Cannot remove yourself from the group.');
      }

      // Remove member
      await _sb
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', memberId);

      groupDebugPrint('Member $memberId removed from group $groupId by Muthawif $muthawifId');
      return ServiceResult.ok(null);
    } catch (e) {
      groupDebugPrint('Error removing member: $e');
      return ServiceResult.fail('Failed to remove member: $e');
    }
  }

  /// Get all members of a group
  Future<List<MemberModel>> getGroupMembers(String groupId) async {
    final result = await _sb
        .from('group_members')
        .select()
        .eq('group_id', groupId);

    return (result as List)
        .map((e) => MemberModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Get a group by ID
  Future<GroupModel?> getGroup(String groupId) async {
    return _getGroup(groupId);
  }

  /// Get all groups for a user (where they are a member or owner)
  Future<List<GroupModel>> getUserGroups(String userId) async {
    // Get groups where user is owner
    final ownedResult = await _sb
        .from('groups')
        .select()
        .eq('muthawif_id', userId);

    // Get groups where user is a member
    final membershipResult = await _sb
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId);

    final memberGroupIds = (membershipResult as List)
        .map((e) => e['group_id'] as String)
        .toSet();

    // Get member groups
    List<GroupModel> memberGroups = [];
    if (memberGroupIds.isNotEmpty) {
      // Use `in` filter — Supabase Flutter uses `in()` method
      final memberGroupsResult = await _sb
          .from('groups')
          .select()
          .inFilter('id', memberGroupIds.toList());

      memberGroups = (memberGroupsResult as List)
          .map((e) => _groupFromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    // Combine with owned groups, avoiding duplicates
    final ownedGroups = (ownedResult as List)
        .map((e) => _groupFromMap(Map<String, dynamic>.from(e)))
        .toList();

    final allGroupsMap = <String, GroupModel>{};
    for (final g in [...ownedGroups, ...memberGroups]) {
      allGroupsMap[g.id] = g;
    }

    return allGroupsMap.values.toList();
  }

  /// Delete a group (Muthawif only)
  Future<ServiceResult<void>> deleteGroup({
    required String muthawifId,
    required String groupId,
  }) async {
    try {
      final group = await _getGroup(groupId);
      if (group == null) {
        return ServiceResult.fail('Group not found.');
      }

      if (group.muthawifId != muthawifId) {
        return ServiceResult.fail('Only Muthawif can delete the group.');
      }

      // CASCADE will delete group_members and broadcast_logs
      await _sb.from('groups').delete().eq('id', groupId);

      groupDebugPrint('Group $groupId deleted by Muthawif $muthawifId');
      return ServiceResult.ok(null);
    } catch (e) {
      groupDebugPrint('Error deleting group: $e');
      return ServiceResult.fail('Failed to delete group: $e');
    }
  }

  // Private helpers

  Future<GroupModel?> _getGroup(String groupId) async {
    final result = await _sb
        .from('groups')
        .select()
        .eq('id', groupId)
        .maybeSingle();

    if (result == null) return null;
    return _groupFromMap(Map<String, dynamic>.from(result));
  }

  GroupModel _groupFromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] as String,
      name: map['name'] as String,
      pin: map['pin'] as String,
      qrData: map['qr_data'] as String? ?? '',
      muthawifId: map['muthawif_id'] as String,
      maxMembers: map['max_members'] as int? ?? 100,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      memberCount: map['member_count'] as int? ?? 1,
    );
  }
}

// Debug print helper
void groupDebugPrint(String message) {
  // ignore: avoid_print
  print('[GroupService] $message');
}
