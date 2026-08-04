class BidListModel {
  final int id;
  final String companyId;
  final String companyName;
  final String tableId;
  final String userId;
  final String userName;
  final String userPhoneNumber;
  final int bidPrice;

  BidListModel({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.tableId,
    required this.userId,
    required this.userName,
    required this.userPhoneNumber,
    required this.bidPrice,
  });

  factory BidListModel.fromJson(Map<String, dynamic> json) {
    return BidListModel(
      id: json['id'],
      companyId: json['company_id'],
      companyName: json['company_name'],
      tableId: json['table_id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userPhoneNumber: json['user_phonenumber'],
      bidPrice: json['bid_price'],
    );
  }
}
