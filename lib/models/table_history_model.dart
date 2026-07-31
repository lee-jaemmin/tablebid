class TableHistoryModel {
  final int id;
  final String tableId;
  final String tableName;
  final String section;
  final String customerName;
  final String customerPhone;
  final int persons;
  final String remark;
  final String userId; // 아웃 스태프!
  final String userName;
  final String companyId;
  final DateTime? registeredAt;
  final DateTime outAt;
  final DateTime createdAt;

  TableHistoryModel({
    required this.id,
    required this.tableId,
    required this.tableName,
    required this.section,
    required this.customerName,
    required this.customerPhone,
    required this.persons,
    required this.remark,
    required this.userId,
    required this.userName,
    required this.companyId,
    this.registeredAt,
    required this.outAt,
    required this.createdAt,
  });

  factory TableHistoryModel.fromJson(Map<String, dynamic> json) {
    print(json);
    return TableHistoryModel(
      id: json['id'],
      tableId: json['table_id'],
      tableName: json['tablename'],
      section: json['section'],
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      persons: json['persons'] ?? 0,
      remark: json['remark'] ?? '',
      userId: json['user_id'],
      userName: json['user_name'],
      companyId: json['company_id'],
      registeredAt: json['registered_at'] == null
          ? null
          : DateTime.parse(json['registered_at']),
      outAt: DateTime.parse(json['out_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
