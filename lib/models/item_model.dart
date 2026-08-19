class ItemModel {
  final int id;
  final String itemName;
  final int itemPrice;
  final bool isActive;
  final bool hasMixer;
  final String companyId;
  final int categoryId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ItemModel({
    required this.id,
    required this.itemName,
    required this.itemPrice,
    required this.isActive,
    required this.hasMixer,
    required this.companyId,
    required this.categoryId,
    this.createdAt,
    this.updatedAt,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'],
      itemName: json['item_name'],
      itemPrice: json['item_price'],
      isActive: json['is_active'],
      hasMixer: json['has_mixer'] ?? true,
      companyId: json['company_id'],
      categoryId: json['category_id'],
      createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at']),
      updatedAt: json['created_at'] == null ? null : DateTime.parse(json['updated_at']),
    );
  }
}
