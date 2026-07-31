class TableHistoryPurchaseModel {
  final int id;
  final int historyId;
  final int itemId;
  final String itemName;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final DateTime createdAt;

  TableHistoryPurchaseModel({
    required this.id,
    required this.historyId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
  });

  factory TableHistoryPurchaseModel.fromJson(Map<String, dynamic> json) {
    return TableHistoryPurchaseModel(
      id: json['id'],
      historyId: json['history_id'],
      itemId: json['item_id'],
      itemName: json['item_name'],
      quantity: json['quantity'],
      unitPrice: json['unit_price'],
      totalPrice: json['total_price'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
