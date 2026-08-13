class SetMenuModel {
  final int id;
  final String companyId;
  final String setName;
  final String setPrice;
  final bool isActive;
  final int categoryId;

  SetMenuModel({
    required this.id,
    required this.companyId,
    required this.setName,
    required this.setPrice,
    required this.isActive,
    required this.categoryId,
  });

  factory SetMenuModel.fromJson(Map<String, dynamic> json) {
    return SetMenuModel(
      id: json['id'],
      companyId: json['company_id'],
      setName: json['set_name'],
      setPrice: json['set_price'],
      isActive: json['is_active'],
      categoryId: json['category_id'],
    );
  }
}
