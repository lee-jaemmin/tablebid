class PublicReservationModel {
  final int id;
  final String tableId;
  final int bidPrice;
  final bool isFixed;
  final DateTime fixedAt;
  final DateTime reservationTime;

  PublicReservationModel({
    required this.id,
    required this.tableId,
    required this.bidPrice,
    required this.isFixed,
    required this.fixedAt,
    required this.reservationTime,
  });

  factory PublicReservationModel.fromJson(Map<String, dynamic> json) {
    return PublicReservationModel(
      id: json['id'],
      tableId: json['table_id'],
      bidPrice: json['bid_price'],
      isFixed: json['is_fixed'],
      fixedAt: json['fixed_at'],
      reservationTime: json['reservation_time'] == null ? null : json['reservation_time']
    );
  }
}
