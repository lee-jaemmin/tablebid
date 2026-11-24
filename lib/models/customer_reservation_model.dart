class CustomerReservationModel {
  final int id;
  final String tableId;
  final int bidPrice;
  final bool isFixed;
  final DateTime fixedAt;
  final DateTime reservationTime;
  final DateTime? arriavalAt;

  CustomerReservationModel({
    required this.id,
    required this.tableId,
    required this.bidPrice,
    required this.isFixed,
    required this.fixedAt,
    required this.reservationTime,
    this.arriavalAt,
  });

  factory CustomerReservationModel.fromJson(Map<String, dynamic> json) {
    return CustomerReservationModel(
      id: json['id'],
      tableId: json['table_id'],
      bidPrice: json['bid_price'],
      isFixed: json['is_fixed'],
      fixedAt: json['fixed_at'],
      reservationTime: json['reservation_time'] == null ? null : json['reservation_time'],
      arriavalAt: json['arriavalAt'] == null ? null : json['arriavalAt']
    );
  }
}
