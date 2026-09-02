class UserModel {
  final String id;
  final String userName;
  final String email;
  String role;
  final String? fcmToken;
  final List<String> cardfields;
  final DateTime createdAt;
  final String? companyId;
  bool isPushOn = true;
  final String? phonenumber;
  final bool phoneVerified;

  UserModel({
    required this.id,
    required this.userName,
    required this.email,
    required this.role,
    this.fcmToken,
    required this.cardfields,
    required this.createdAt,
    this.companyId,
    required this.isPushOn,
    this.phonenumber,
    required this.phoneVerified,
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
      phoneVerified: phoneVerified ?? this.phoneVerified
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      userName: json['username'] ?? "이름 미지정",
      email: json['email'],
      role: json['role'],
      fcmToken: json['fcmtoken'],
      cardfields: List<String>.from(
        json['tablecardfields'] ?? ['purchases', 'persons'],
      ),
      createdAt: DateTime.parse(json['created_at']),
      companyId: json['company_id'],
      isPushOn: json['is_push_on'],
      phonenumber: json['phonenumber'],
      phoneVerified: json['phoneVerified'] ?? false
    );
  }
}
