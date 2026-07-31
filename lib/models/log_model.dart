class LogModel {
  final int id;
  final String tableId;
  final int itemId;
  final String itemName;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final String userId;
  final DateTime createdAt;
  final String batchId;
  

  LogModel({
    required this.id,
    required this.tableId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.userId,
    required this.createdAt,
    required this.batchId,
  });

  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      id: json['id'],
      tableId: json['table_id'],
      itemId: json['item_id'],
      itemName: json['item_name'],
      quantity: json['quantity'],
      unitPrice: json['unit_price'],
      totalPrice: json['total_price'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      batchId: json['batch_id'],
    );
  }
}
