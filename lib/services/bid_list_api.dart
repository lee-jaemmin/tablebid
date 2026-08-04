import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:tablebid/models/bid_list_model.dart';
import 'api_client.dart';

class BidListApi {
  Future<List<BidListModel>> getBidListByTable(String tableId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/tables/$tableId/bid-lists');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => BidListModel.fromJson(json)).toList();
    }
    throw Exception(
      'Failed to get BidLists: ${response.statusCode} ${response.body}',
    );
  }

  Future<BidListModel> getBidList(int bidId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/bid-lists/$bidId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return BidListModel.fromJson(data);
    }
    throw Exception(
      'Failed to get Bid: ${response.statusCode} ${response.body}',
    );
  }

  Future<BidListModel> createBidList({
    required String companyId,
    required String companyName,
    required String tableId,
    required String userId,
    required String userName,
    required String userPhoneNumber,
    required int bidPrice
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/bid-lists');

    final body = {
      'company_name': companyName,
      'user_name': userName,
      'user_phonenumber': userPhoneNumber,
      'bid_price': bidPrice,
      'company_id': companyId,
      'table_id': tableId,
      'user_id': userId,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return BidListModel.fromJson(data);
    }
    throw Exception(
      'Failed to create BidList: ${response.statusCode} ${response.body}',
    );
  }

  Future<BidListModel> updateBidList({
    required int bidId,
    String? userPhoneNumber,
    int? bidPrice,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/bid-lists/$bidId');

    final body = {
      'user_phonenumber': userPhoneNumber,
      'bid_price': bidPrice
    };

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return BidListModel.fromJson(data);
    }
    throw Exception(
      'Failed to update BidList: ${response.statusCode} ${response.body}',
    );
  }
}
