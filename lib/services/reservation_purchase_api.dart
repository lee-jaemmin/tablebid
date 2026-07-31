import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tablebid/models/reservation_purchase_model.dart';
import 'package:tablebid/services/api_client.dart';

class ReservationPurchaseApi {
  Future<ReservationPurchaseModel> getResPurchase(int resPurchaseId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/res-purchases/$resPurchaseId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return ReservationPurchaseModel.fromJson(data);
    }
    throw Exception(
      "Failed to get Reservation Purchase: ${response.statusCode} ${response.body}",
    );
  }

  Future<List<ReservationPurchaseModel>> getResPurchasesByTable(
    String tableId,
  ) async {
    final url = Uri.parse('${ApiClient.baseUrl}/tables/$tableId/res-purchases');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((elem) => ReservationPurchaseModel.fromJson(elem))
          .toList();
    }
    throw Exception(
      "Failed to get Reservation Purchases: ${response.statusCode} ${response.body}",
    );
  }

  Future<List<ReservationPurchaseModel>> getResPurchasesByReservation(
    int reservationId,
  ) async {
    final url = Uri.parse('${ApiClient.baseUrl}/reservations/$reservationId/res-purchases');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((elem) => ReservationPurchaseModel.fromJson(elem))
          .toList();
    }
    throw Exception(
      "Failed to get Reservation Purchases by Reservation: ${response.statusCode} ${response.body}",
    );
  }

  Future<ReservationPurchaseModel> createResPurchase({
    required int reservationId,
    required int itemId,
    required int quantity,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/res-purchases');

    final body = {
      'reservation_id': reservationId,
      'item_id': itemId,
      'quantity': quantity,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return ReservationPurchaseModel.fromJson(data);
    }
    throw Exception(
      'Failed to create Reservation Purchase: ${response.statusCode} ${response.body}',
    );
  }

  Future<ReservationPurchaseModel> updateResPurchase({
    required int resPurchaseId,
    int? itemId,
    String? itemName,
    int? quantity,
    int? unit_price,
    int? total_price,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/res-purchases/$resPurchaseId');

    final body = {
      if (itemId != null) 'item_id': itemId,
      if (itemName != null) 'item_name': itemName,
      if (quantity != null) 'quantity': quantity,
      if (unit_price != null) 'unit_price': unit_price,
      if (total_price != null) 'total_price': total_price,
    };

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return ReservationPurchaseModel.fromJson(data);
    }
    throw Exception(
      'Failed to update Reservation Purchase: ${response.statusCode} ${response.body}',
    );
  }

  Future<void> deleteResPurchase({
    required String resPurchaseId,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/res-purchases/$resPurchaseId');
    final response = await http.delete(url);

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }
    throw Exception(
      'Failed to delete Reservation Purchase: ${response.statusCode} ${response.body}',
    );
  }
}
