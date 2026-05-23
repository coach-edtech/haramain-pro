import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/group_model.dart';

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

/// Group service for managing Jamaah groups
class GroupService {
  static final GroupService _instance = GroupService._internal();
  static GroupService get instance => _instance;

  GroupService._internal();

  static const String _groupsKey = 'haramain_groups';
  static const String _membersKey = 'haramain_group_members';

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

      // Create group model
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

      // Create initial member (Muthawif)
      final member = MemberModel(
        userId: muthawifId,
        userName: muthawifName,
        role: GroupRole.owner,
        joinedAt: DateTime.now(),
      );

      // Store group
      await _saveGroup(group);

      // Store member
      await _saveMember(groupId, member);

      groupDebugPrint('Group created: ${group.id} with PIN: ${group.pin}');
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
      // Find group by PIN
      final group = await _findGroupByPin(pin);
      if (group == null) {
        return ServiceResult.fail('Invalid PIN. Please check and try again.');
      }

      if (group.isFull) {
        return ServiceResult.fail('Group is full. Maximum 100 members reached.');
      }

      // Check if already a member
      final members = await getGroupMembers(group.id);
      if (members.any((m) => m.userId == jamaahId)) {
        return ServiceResult.fail('You are already a member of this group.');
      }

      // Add member
      final member = MemberModel(
        userId: jamaahId,
        userName: jamaahName,
        role: GroupRole.member,
        joinedAt: DateTime.now(),
      );

      await _saveMember(group.id, member);

      // Update member count
      final updatedGroup = group.copyWith(memberCount: group.memberCount + 1);
      await _saveGroup(updatedGroup);

      groupDebugPrint('Jamaah $jamaahId joined group ${group.id}');
      return ServiceResult.ok(updatedGroup);
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
      final group = await _getGroup(groupId);
      if (group == null) {
        return ServiceResult.fail('Group not found.');
      }

      if (group.pin != pin) {
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
      await _removeMember(groupId, jamaahId);

      // Update member count
      final updatedGroup = group.copyWith(memberCount: group.memberCount - 1);
      await _saveGroup(updatedGroup);

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
      await _removeMember(groupId, memberId);

      // Update member count
      final updatedGroup = group.copyWith(memberCount: group.memberCount - 1);
      await _saveGroup(updatedGroup);

      groupDebugPrint('Member $memberId removed from group $groupId by Muthawif $muthawifId');
      return ServiceResult.ok(null);
    } catch (e) {
      groupDebugPrint('Error removing member: $e');
      return ServiceResult.fail('Failed to remove member: $e');
    }
  }

  /// Get all members of a group
  Future<List<MemberModel>> getGroupMembers(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final membersJson = prefs.getString('${_membersKey}_$groupId');

    if (membersJson == null) return [];

    final List<dynamic> decoded = jsonDecode(membersJson);
    return decoded.map((e) => MemberModel.fromJson(e)).toList();
  }

  /// Get a group by ID
  Future<GroupModel?> getGroup(String groupId) async {
    return _getGroup(groupId);
  }

  /// Get all groups for a user (where they are a member)
  Future<List<GroupModel>> getUserGroups(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getString(_groupsKey);

    if (groupsJson == null) return [];

    final List<dynamic> decoded = jsonDecode(groupsJson);
    final groups = decoded.map((e) => GroupModel.fromJson(e)).toList();

    // Filter groups where user is a member
    final userGroups = <GroupModel>[];
    for (final group in groups) {
      final members = await getGroupMembers(group.id);
      if (members.any((m) => m.userId == userId)) {
        userGroups.add(group);
      }
    }

    return userGroups;
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

      // Remove all members
      await _removeAllMembers(groupId);

      // Remove group
      await _deleteGroup(groupId);

      groupDebugPrint('Group $groupId deleted by Muthawif $muthawifId');
      return ServiceResult.ok(null);
    } catch (e) {
      groupDebugPrint('Error deleting group: $e');
      return ServiceResult.fail('Failed to delete group: $e');
    }
  }

  // Private helper methods

  Future<GroupModel?> _getGroup(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getString(_groupsKey);

    if (groupsJson == null) return null;

    final List<dynamic> decoded = jsonDecode(groupsJson);
    final groups = decoded.map((e) => GroupModel.fromJson(e)).toList();

    try {
      return groups.firstWhere((g) => g.id == groupId);
    } catch (_) {
      return null;
    }
  }

  Future<GroupModel?> _findGroupByPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getString(_groupsKey);

    if (groupsJson == null) return null;

    final List<dynamic> decoded = jsonDecode(groupsJson);
    final groups = decoded.map((e) => GroupModel.fromJson(e)).toList();

    try {
      return groups.firstWhere((g) => g.pin == pin);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveGroup(GroupModel group) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getString(_groupsKey);

    List<GroupModel> groups = [];
    if (groupsJson != null) {
      final List<dynamic> decoded = jsonDecode(groupsJson);
      groups = decoded.map((e) => GroupModel.fromJson(e)).toList();
    }

    // Update or add
    final index = groups.indexWhere((g) => g.id == group.id);
    if (index >= 0) {
      groups[index] = group;
    } else {
      groups.add(group);
    }

    await prefs.setString(
      _groupsKey,
      jsonEncode(groups.map((g) => g.toJson()).toList()),
    );
  }

  Future<void> _deleteGroup(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = prefs.getString(_groupsKey);

    if (groupsJson == null) return;

    final List<dynamic> decoded = jsonDecode(groupsJson);
    final groups = decoded.map((e) => GroupModel.fromJson(e)).toList();
    groups.removeWhere((g) => g.id == groupId);

    await prefs.setString(
      _groupsKey,
      jsonEncode(groups.map((g) => g.toJson()).toList()),
    );
  }

  Future<void> _saveMember(String groupId, MemberModel member) async {
    final members = await getGroupMembers(groupId);

    // Update or add
    final index = members.indexWhere((m) => m.userId == member.userId);
    if (index >= 0) {
      members[index] = member;
    } else {
      members.add(member);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_membersKey}_$groupId',
      jsonEncode(members.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> _removeMember(String groupId, String userId) async {
    final members = await getGroupMembers(groupId);
    members.removeWhere((m) => m.userId == userId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_membersKey}_$groupId',
      jsonEncode(members.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> _removeAllMembers(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_membersKey}_$groupId');
  }
}

// Debug print helper
void groupDebugPrint(String message) {
  // ignore: avoid_print
  print('[GroupService] $message');
}
