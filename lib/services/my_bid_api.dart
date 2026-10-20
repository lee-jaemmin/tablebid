import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tablebid/methods/firebase_auth.dart';
import 'package:tablebid/models/my_bid_model.dart';
import 'package:tablebid/services/api_client.dart';

class MyBidApi {
  Future<List<MyBidModel>> getMyBids() async {
    final url = Uri.parse('${ApiClient.baseUrl}/mybids');
    final response = await http.get(url, headers: await firebaseAuthHeaders());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((json) => MyBidModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
      'Failed to get my bids: ${response.statusCode} ${response.body}',
    );
  }
}
