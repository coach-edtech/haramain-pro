import 'dart:convert';
import 'package:uuid/uuid.dart';

enum NrcStatus {
  draft,
  submitted,
  underReview,
  approved,
  rejected,
}

class NrcRegistration {
  final String id;
  final String userId;
  final String passportNumber;
  final String passportExpiryDate;
  final String passportCountry;
  final String fullName;
  final String nationality;
  final String birthDate;
  final String birthPlace;
  final String gender;
  final String visaNumber;
  final String visaType;
  final String visaExpiryDate;
  final String accommodationName;
  final String accommodationAddress;
  final String accommodationCity;
  final String accommodationPhone;
  final List<String> itineraryDays;
  final String? passportImageUrl;
  final String? visaImageUrl;
  final NrcStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  const NrcRegistration({
    required this.id,
    required this.userId,
    required this.passportNumber,
    required this.passportExpiryDate,
    required this.passportCountry,
    required this.fullName,
    required this.nationality,
    required this.birthDate,
    required this.birthPlace,
    required this.gender,
    required this.visaNumber,
    required this.visaType,
    required this.visaExpiryDate,
    required this.accommodationName,
    required this.accommodationAddress,
    required this.accommodationCity,
    required this.accommodationPhone,
    required this.itineraryDays,
    this.passportImageUrl,
    this.visaImageUrl,
    this.status = NrcStatus.draft,
    this.rejectionReason,
    required this.createdAt,
    this.submittedAt,
    this.reviewedAt,
  });

  factory NrcRegistration.create({
    required String userId,
    required String passportNumber,
    required String passportExpiryDate,
    required String passportCountry,
    required String fullName,
    required String nationality,
    required String birthDate,
    required String birthPlace,
    required String gender,
    required String visaNumber,
    required String visaType,
    required String visaExpiryDate,
    required String accommodationName,
    required String accommodationAddress,
    required String accommodationCity,
    required String accommodationPhone,
    required List<String> itineraryDays,
  }) {
    return NrcRegistration(
      id: const Uuid().v4(),
      userId: userId,
      passportNumber: passportNumber,
      passportExpiryDate: passportExpiryDate,
      passportCountry: passportCountry,
      fullName: fullName,
      nationality: nationality,
      birthDate: birthDate,
      birthPlace: birthPlace,
      gender: gender,
      visaNumber: visaNumber,
      visaType: visaType,
      visaExpiryDate: visaExpiryDate,
      accommodationName: accommodationName,
      accommodationAddress: accommodationAddress,
      accommodationCity: accommodationCity,
      accommodationPhone: accommodationPhone,
      itineraryDays: itineraryDays,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'passport_number': passportNumber,
      'passport_expiry_date': passportExpiryDate,
      'passport_country': passportCountry,
      'full_name': fullName,
      'nationality': nationality,
      'birth_date': birthDate,
      'birth_place': birthPlace,
      'gender': gender,
      'visa_number': visaNumber,
      'visa_type': visaType,
      'visa_expiry_date': visaExpiryDate,
      'accommodation_name': accommodationName,
      'accommodation_address': accommodationAddress,
      'accommodation_city': accommodationCity,
      'accommodation_phone': accommodationPhone,
      'itinerary_days': itineraryDays,
      'passport_image_url': passportImageUrl,
      'visa_image_url': visaImageUrl,
      'status': status.name,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'submitted_at': submittedAt?.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
    };
  }

  factory NrcRegistration.fromJson(Map<String, dynamic> json) {
    return NrcRegistration(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      passportNumber: json['passport_number'] as String,
      passportExpiryDate: json['passport_expiry_date'] as String,
      passportCountry: json['passport_country'] as String,
      fullName: json['full_name'] as String,
      nationality: json['nationality'] as String,
      birthDate: json['birth_date'] as String,
      birthPlace: json['birth_place'] as String,
      gender: json['gender'] as String,
      visaNumber: json['visa_number'] as String,
      visaType: json['visa_type'] as String,
      visaExpiryDate: json['visa_expiry_date'] as String,
      accommodationName: json['accommodation_name'] as String,
      accommodationAddress: json['accommodation_address'] as String,
      accommodationCity: json['accommodation_city'] as String,
      accommodationPhone: json['accommodation_phone'] as String,
      itineraryDays: List<String>.from(json['itinerary_days'] as List),
      passportImageUrl: json['passport_image_url'] as String?,
      visaImageUrl: json['visa_image_url'] as String?,
      status: NrcStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => NrcStatus.draft,
      ),
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory NrcRegistration.fromJsonString(String jsonString) {
    return NrcRegistration.fromJson(jsonDecode(jsonString));
  }

  NrcRegistration copyWith({
    String? id,
    String? userId,
    String? passportNumber,
    String? passportExpiryDate,
    String? passportCountry,
    String? fullName,
    String? nationality,
    String? birthDate,
    String? birthPlace,
    String? gender,
    String? visaNumber,
    String? visaType,
    String? visaExpiryDate,
    String? accommodationName,
    String? accommodationAddress,
    String? accommodationCity,
    String? accommodationPhone,
    List<String>? itineraryDays,
    String? passportImageUrl,
    String? visaImageUrl,
    NrcStatus? status,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? submittedAt,
    DateTime? reviewedAt,
  }) {
    return NrcRegistration(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      passportNumber: passportNumber ?? this.passportNumber,
      passportExpiryDate: passportExpiryDate ?? this.passportExpiryDate,
      passportCountry: passportCountry ?? this.passportCountry,
      fullName: fullName ?? this.fullName,
      nationality: nationality ?? this.nationality,
      birthDate: birthDate ?? this.birthDate,
      birthPlace: birthPlace ?? this.birthPlace,
      gender: gender ?? this.gender,
      visaNumber: visaNumber ?? this.visaNumber,
      visaType: visaType ?? this.visaType,
      visaExpiryDate: visaExpiryDate ?? this.visaExpiryDate,
      accommodationName: accommodationName ?? this.accommodationName,
      accommodationAddress: accommodationAddress ?? this.accommodationAddress,
      accommodationCity: accommodationCity ?? this.accommodationCity,
      accommodationPhone: accommodationPhone ?? this.accommodationPhone,
      itineraryDays: itineraryDays ?? this.itineraryDays,
      passportImageUrl: passportImageUrl ?? this.passportImageUrl,
      visaImageUrl: visaImageUrl ?? this.visaImageUrl,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case NrcStatus.draft:
        return 'Draft';
      case NrcStatus.submitted:
        return 'Submitted';
      case NrcStatus.underReview:
        return 'Under Review';
      case NrcStatus.approved:
        return 'Approved';
      case NrcStatus.rejected:
        return 'Rejected';
    }
  }

  bool get isDraft => status == NrcStatus.draft;
  bool get isSubmitted => status == NrcStatus.submitted;
  bool get isApproved => status == NrcStatus.approved;
  bool get isRejected => status == NrcStatus.rejected;
  bool get canEdit => isDraft || isRejected;
}
