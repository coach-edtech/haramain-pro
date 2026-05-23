import 'package:uuid/uuid.dart';

/// Role of member in a group
/// Maps to `group_members.role` DB column: 'owner', 'member'
enum GroupRole {
  owner,   // Creator/organizer of the group (muthawif or agency)
  member,  // Regular member (jamaah, muthawif joining another group, etc.)
}

/// Member model for group
class MemberModel {
  final String userId;
  final String userName;
  final GroupRole role;
  final DateTime joinedAt;

  const MemberModel({
    required this.userId,
    required this.userName,
    required this.role,
    required this.joinedAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    // DB stores 'muthawif' for owner, 'jamaah' for member
    final dbRole = json['role'] as String? ?? 'member';
    final groupRole = dbRole == 'muthawif' ? GroupRole.owner : GroupRole.member;
    return MemberModel(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? '',
      role: groupRole,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    // Serialize to DB-friendly values: 'muthawif' for owner, 'member' for member
    final dbRole = role == GroupRole.owner ? 'muthawif' : 'member';
    return {
      'user_id': userId,
      'user_name': userName,
      'role': dbRole,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  bool get isOwner => role == GroupRole.owner;

  MemberModel copyWith({
    String? userId,
    String? userName,
    GroupRole? role,
    DateTime? joinedAt,
  }) {
    return MemberModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

/// Group model for Jamaah groups
class GroupModel {
  final String id;
  final String name;
  final String pin;
  final String qrData;
  final String muthawifId;
  final int maxMembers;
  final DateTime createdAt;
  final int memberCount;

  const GroupModel({
    required this.id,
    required this.name,
    required this.pin,
    required this.qrData,
    required this.muthawifId,
    this.maxMembers = 100,
    required this.createdAt,
    this.memberCount = 1,
  });

  /// Create a new group with generated ID, PIN, and QR data
  factory GroupModel.create({
    required String muthawifId,
    required String muthawifName,
    required String name,
  }) {
    final id = const Uuid().v4();
    final pin = _generatePin();
    final qrData = _generateQrData(id, pin);

    return GroupModel(
      id: id,
      name: name,
      pin: pin,
      qrData: qrData,
      muthawifId: muthawifId,
      maxMembers: 100,
      createdAt: DateTime.now(),
      memberCount: 1,
    );
  }

  /// Generate 6-character alphanumeric PIN
  static String _generatePin() {
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

  /// Generate QR code payload containing group ID and PIN
  static String _generateQrData(String groupId, String pin) {
    // QR contains JSON with group info for easy scanning
    return 'haramain://group/join?id=$groupId&pin=$pin';
  }

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      pin: json['pin'] as String,
      qrData: json['qr_data'] as String? ?? '',
      muthawifId: json['muthawif_id'] as String,
      maxMembers: json['max_members'] as int? ?? 100,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      memberCount: json['member_count'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pin': pin,
      'qr_data': qrData,
      'muthawif_id': muthawifId,
      'max_members': maxMembers,
      'created_at': createdAt.toIso8601String(),
      'member_count': memberCount,
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? pin,
    String? qrData,
    String? muthawifId,
    int? maxMembers,
    DateTime? createdAt,
    int? memberCount,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      pin: pin ?? this.pin,
      qrData: qrData ?? this.qrData,
      muthawifId: muthawifId ?? this.muthawifId,
      maxMembers: maxMembers ?? this.maxMembers,
      createdAt: createdAt ?? this.createdAt,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  bool get isFull => memberCount >= maxMembers;

  @override
  String toString() {
    return 'GroupModel(id: $id, name: $name, pin: $pin, memberCount: $memberCount/$maxMembers)';
  }
}

/// Broadcast message model
class BroadcastModel {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String message;
  final String? imageUrl;
  final DateTime sentAt;

  const BroadcastModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.imageUrl,
    required this.sentAt,
  });

  factory BroadcastModel.fromJson(Map<String, dynamic> json) {
    return BroadcastModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String? ?? '',
      message: json['message'] as String,
      imageUrl: json['image_url'] as String?,
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'sender_id': senderId,
      'sender_name': senderName,
      'message': message,
      'image_url': imageUrl,
      'sent_at': sentAt.toIso8601String(),
    };
  }
}
