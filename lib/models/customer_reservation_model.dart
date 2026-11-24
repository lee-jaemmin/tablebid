class CustomerReservationModel {
  final int id;
  final String tableId;
  final int? bidPrice;
  final bool? isFixed;
  final DateTime? fixedAt;
  final DateTime? reservationTime;
  final DateTime? arrivalAt;

  CustomerReservationModel({
    required this.id,
    required this.tableId,
    required this.bidPrice,
    required this.isFixed,
    required this.fixedAt,
    required this.reservationTime,
    this.arrivalAt,
  });

  factory CustomerReservationModel.fromJson(Map<String, dynamic> json) {
    return CustomerReservationModel(
      id: json['id'],
      tableId: json['table_id'],
      bidPrice: json['bid_price'],
      isFixed: json['is_fixed'],
      fixedAt: json['fixed_at'] == null ? null : DateTime.parse(json['fixed_at']).toLocal(),
      reservationTime: json['reservation_time'] == null ? null : DateTime.parse(json['reservation_time']).toLocal(),
      arrivalAt: json['arrival_at'] == null ? null : DateTime.parse(json['arrival_at']).toLocal()
    );
  }
}
