enum UserRole {
  pilgrim,
  muthawif,
  agency,
  admin,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.pilgrim:
        return 'pilgrim';
      case UserRole.muthawif:
        return 'muthawif';
      case UserRole.agency:
        return 'agency';
      case UserRole.admin:
        return 'admin';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.pilgrim:
        return 'Jamaah';
      case UserRole.muthawif:
        return 'Muthawif';
      case UserRole.agency:
        return 'Travel Admin';
      case UserRole.admin:
        return 'Admin';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pilgrim':
        return UserRole.pilgrim;
      case 'muthawif':
        return UserRole.muthawif;
      case 'agency':
        return UserRole.agency;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.pilgrim;
    }
  }
}

class UserProfile {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? subscriptionTier;
  final DateTime? consentGivenAt;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.subscriptionTier,
    this.consentGivenAt,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? '',
      role: UserRoleExtension.fromString(json['role'] as String? ?? 'pilgrim'),
      subscriptionTier: json['subscription_tier'] as String?,
      consentGivenAt: json['consent_given_at'] != null
          ? DateTime.parse(json['consent_given_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.value,
      'subscription_tier': subscriptionTier,
      'consent_given_at': consentGivenAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? subscriptionTier,
    DateTime? consentGivenAt,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      consentGivenAt: consentGivenAt ?? this.consentGivenAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
