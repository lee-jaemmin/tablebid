class ReservationPurchaseModel {
  final int id;
  final int reservationId;
  final int itemId;
  final String itemName;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReservationPurchaseModel({
    required this.id,
    required this.reservationId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReservationPurchaseModel.fromJson(Map<String, dynamic> json) {
    return ReservationPurchaseModel(
      id: json['id'],
      reservationId: json['reservation_id'],
      itemId: json['item_id'],
      itemName: json['item_name'],
      quantity: json['quantity'],
      unitPrice: json['unit_price'],
      totalPrice: json['total_price'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at']),
    );
  }
}
