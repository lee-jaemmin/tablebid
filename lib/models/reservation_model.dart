class ReservationModel {
  final int id;
  final String tableId;
  final String customerName;
  final String customerPhone;
  final DateTime? reservationTime;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReservationModel({
    required this.id,
    required this.tableId,
    required this.customerName,
    required this.customerPhone,
    this.reservationTime,
    required this.createdAt,
    this.updatedAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'],
      tableId: json['table_id'],
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      reservationTime: json['reservation_time'] == null ? null : DateTime.parse(json['reservation_time']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at']),
    );
  }
}
