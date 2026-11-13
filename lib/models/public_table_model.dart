class PublicTableModel {
  final String id;
  final String tablename;
  final String section;
  final String status;
  final String companyId;
  final bool isReserved;
  final bool bidAvailable;
  final bool hasReservations;
  DateTime? bidEndAt;
  DateTime? reservedAt;
  DateTime? registeredAt;
  int? leastBidPrice;
  String? offerProducts;

  PublicTableModel({
    required this.id,
    required this.tablename,
    required this.section,
    required this.status,
    required this.companyId,
    required this.isReserved,
    required this.bidAvailable,
    required this.hasReservations,
    this.bidEndAt,
    this.reservedAt,
    this.registeredAt,
    this.leastBidPrice,
    this.offerProducts
  });

  static DateTime? _parseUtcDateTime(dynamic value) {
    if (value == null) return null;

    final text = value.toString();
    final hasTimezone = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(text);

    return DateTime.parse(hasTimezone ? text : '${text}Z').toLocal();
  }

  factory PublicTableModel.fromJson(Map<String, dynamic> json) {
    return PublicTableModel(
      id: json['id'],
      tablename: json['tablename'],
      section: json['section'],
      status: json['status'],
      registeredAt: json['registered_at'] == null ? null : DateTime.parse(json['registered_at']),
      reservedAt: _parseUtcDateTime(json['reserved_at']),
      companyId: json['company_id'],
      bidEndAt:  _parseUtcDateTime(json['bid_end_at']),
      isReserved: json['is_reserved'],
      bidAvailable: json['bid_available'],
      hasReservations: json['has_reservations'],
      leastBidPrice: json['least_bid_price'] ?? 0,
      offerProducts: json['offer_products']
    );
  }
}
