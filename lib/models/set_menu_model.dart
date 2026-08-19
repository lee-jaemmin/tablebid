class SetMenuModel {
  final int id;
  final String companyId;
  final String setName;
  final int setPrice;
  final bool isActive;
  final bool hasMixer;

  SetMenuModel({
    required this.id,
    required this.companyId,
    required this.setName,
    required this.setPrice,
    required this.isActive,
    required this.hasMixer
  });

  factory SetMenuModel.fromJson(Map<String, dynamic> json) {
    return SetMenuModel(
      id: json['id'],
      companyId: json['company_id'],
      setName: json['set_name'],
      setPrice: json['set_price'],
      isActive: json['is_active'],
      hasMixer: json['has_mixer'] ?? true
    );
  }
}
