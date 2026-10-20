class MyBidModel {
  final int id;
  final String tableId; 
  final String tableName; 
  final String companyId;
  final String companyName;
  final int rank;
  final int? bidPrice;
  final bool isFixed;

  MyBidModel({
    required this.id,
    required this.tableId,
    required this.tableName,
    required this.companyId,
    required this.companyName,
    required this.rank,
    required this.isFixed,
    this.bidPrice,
  });

  factory MyBidModel.fromJson(Map<String, dynamic> json) {
    return MyBidModel(
      id: json['id'] as int,
      tableId: json['table_id'] as String,
      tableName: json['table_name'] as String,
      bidPrice: json['bid_price'] as int?,
      isFixed: json['is_fixed'] as bool? ?? false,
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String,
      rank: json['rank'] as int,
    );
  }
}
