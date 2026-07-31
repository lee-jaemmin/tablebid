class TablePurchasesModel {
  final int id;
  final String tableId;
  final int itemId;
  final String itemName;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TablePurchasesModel({
    required this.id,
    required this.tableId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TablePurchasesModel.fromJson(Map<String, dynamic> json) {
    return TablePurchasesModel(
      id: json['id'],
      tableId: json['table_id'],
      itemId: json['item_id'],
      itemName: json['item_name'],
      quantity: json['quantity'],
      unitPrice: json['unit_price'],
      totalPrice: json['total_price'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
