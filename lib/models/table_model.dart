class TableModel {
  final String id;
  final String tablename;
  final String section;
  final String status;
  final String customer;
  final String phonenumber;
  final int persons;
  final String remark;
  final int totalPrice;
  final DateTime? registeredAt;
  final bool isMaster;
  final String? masterTableId;
  final DateTime? timerStartedAt; // 바뀌면 아예 새 모델로 바꾸는 게 깔끔
  final DateTime? timerEndAt;
  final DateTime? timerAlertSentAt; 
  final DateTime createdAt;
  final DateTime updatedAt;
  final String companyId;
  final String? userId;
  final String? userName;
  final String? groupId;
  final List<String>? purchaseSummary;
  bool? isReserved;
  DateTime? reservedAt;
  DateTime? bidEndAt;
  bool bidAvailable;
  int? leastBidPrice;
  bool hasReservations;

  TableModel({
    required this.id,
    required this.tablename,
    required this.section,
    required this.status,
    required this.customer,
    required this.phonenumber,
    required this.persons,
    required this.remark,
    required this.totalPrice,
    this.registeredAt,
    required this.isMaster,
    this.masterTableId,
    this.timerStartedAt,
    this.timerEndAt, 
    this.timerAlertSentAt,
    required this.createdAt,
    required this.updatedAt,
    required this.companyId,
    this.userId,
    this.userName,
    this.groupId,
    this.purchaseSummary,
    this.isReserved,
    this.reservedAt,
    this.bidEndAt,
    required this.bidAvailable,
    this.leastBidPrice,
    required this.hasReservations,
  });

  static DateTime? _parseUtcDateTime(dynamic value) {
    if (value == null) return null;

    final text = value.toString();
    final hasTimezone = RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(text);

    return DateTime.parse(hasTimezone ? text : '${text}Z').toLocal();
  }

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'],
      tablename: json['tablename'],
      section: json['section'],
      status: json['status'],
      customer: json['customer'] ?? '',
      phonenumber: json['phonenumber'] ?? '',
      persons: json['persons'] ?? 0,
      remark: json['remark'] ?? '',
      totalPrice: json['total_price'] ?? 0,
      registeredAt: json['registered_at'] == null ? null : DateTime.parse(json['registered_at']),
      isMaster: json['ismaster'] ?? false,
      masterTableId: json['mastertable_id'],
      timerStartedAt: _parseUtcDateTime(json['timer_started_at']),
      timerEndAt: _parseUtcDateTime(json['timer_end_at']),
      timerAlertSentAt: _parseUtcDateTime(json['timer_alert_sent_at']),
      reservedAt: _parseUtcDateTime(json['reserved_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      companyId: json['company_id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? '',
      groupId: json['group_id'],
      purchaseSummary: (json['purchase_summary'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isReserved: json['is_reserved'],
      bidAvailable: json['bid_available'],
      bidEndAt: json['bid_end_at'] == null ? null : _parseUtcDateTime(json['bid_end_at']),
      leastBidPrice: json['least_bid_price'],
      hasReservations: json['has_reservations'] ?? false
    );
  }
}
