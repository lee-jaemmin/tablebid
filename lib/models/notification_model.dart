class NotificationModel {
  final int id;
  final String companyId;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.companyId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      companyId: json['company_id'],
      title: json['title'],
      body: json['body'],
      type: json['type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
