class CompanyModel {
  final String id;
  final String name;
  final String inviteCode;
  final String region;
  final String address;
  final List<String> sections;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompanyModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.region,
    required this.address,
    required this.sections,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'],
      name: json['name'],
      inviteCode: json['invite_code'],
      region: json['region'],
      address: json['address'],
      sections: List<String>.from(
        json['sections'] ?? [],
      ), // FastApi에서 Dart로 처음 넘어오면 List<dynamic>으로 넘어옴.
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
