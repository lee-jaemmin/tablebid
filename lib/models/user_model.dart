class UserModel {
  final String id;
  final String userName;
  final String email;
  String? role;
  final String? fcmToken;
  final List<String> cardfields;
  final DateTime createdAt;
  final String? companyId;
  bool isPushOn = true;
  final String? phonenumber;
  final bool phoneVerified;
  final int noShowCount;

  UserModel({
    required this.id,
    required this.userName,
    required this.email,
    this.role,
    this.fcmToken,
    required this.cardfields,
    required this.createdAt,
    this.companyId,
    required this.isPushOn,
    this.phonenumber,
    required this.phoneVerified,
    this.noShowCount = 0,
  });

  UserModel copyWith({
    String? id,
    String? userName,
    String? email,
    String? role,
    String? fcmToken,
    List<String>? cardfields,
    DateTime? createdAt,
    String? companyId,
    bool? isPushOn,
    String? phonenumber,
    bool? phoneVerified,
    int? noShowCount,
  }) {
    return UserModel(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
      cardfields: cardfields ?? this.cardfields,
      createdAt: createdAt ?? this.createdAt,
      companyId: companyId ?? this.companyId,
      isPushOn: isPushOn ?? this.isPushOn,
      phonenumber: phonenumber ?? this.phonenumber,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      noShowCount: noShowCount ?? this.noShowCount
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      userName: json['username'] ?? "이름 미지정",
      email: json['email'],
      role: json['role'] == null ? null : json['role'],
      fcmToken: json['fcmtoken'],
      cardfields: List<String>.from(
        json['tablecardfields'] ?? ['purchases', 'persons'],
      ),
      createdAt: DateTime.parse(json['created_at']),
      companyId: json['company_id'],
      isPushOn: json['is_push_on'],
      phonenumber: json['phonenumber'],
      phoneVerified: json['phone_verified'] ?? json['phoneVerified'] ?? false,
      noShowCount: json['no_show_count'] ?? json['noShowCount'] ?? 0
    );
  }
}
