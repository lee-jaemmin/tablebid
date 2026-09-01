import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tablebid/models/reservation_model.dart';
import 'package:tablebid/models/table_model.dart';
import 'package:tablebid/screens/reservation_purchase_screen.dart';
import 'package:tablebid/services/api_client.dart';

class ReservationApi {
  Future<ReservationModel> getReservation(String reservationId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/reservations/$reservationId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return ReservationModel.fromJson(data);
    }
    throw Exception(
      "Failed to get Reservation: ${response.statusCode} ${response.body}",
    );
  }

  Future<List<ReservationModel>> getReservationsByTable(String tableId) async {
    final url = Uri.parse('${ApiClient.baseUrl}/tables/$tableId/reservations');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((elem) => ReservationModel.fromJson(elem)).toList();
    }
    throw Exception(
      "Failed to get Reservations: ${response.statusCode} ${response.body}",
    );
  }

  Future<ReservationModel> updateReservation({
    required int reservationId,
    DateTime? reservationTime,
    String? customerName,
    String? customerPhone,
    int? bidPrice,
    bool? isFixed,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/reservations/$reservationId');

    final body = {
      if (reservationTime != null) 'reservation_time': reservationTime.toUtc().toIso8601String(),
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (bidPrice != null) 'bid_price': bidPrice,
      if (isFixed != null) 'is_fixed': isFixed,
    };

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return ReservationModel.fromJson(data);
    }
    throw Exception(
      'Failed to update Reservation: ${response.statusCode} ${response.body}',
    );
  }

  Future<void> deleteReservation({
    required int reservationId,
    String? idToken,
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/reservations/$reservationId');
    final response = await http.delete(
      url,
      headers: {if (idToken != null) 'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }
    throw Exception(
      'Failed to delete Reservation: ${response.statusCode} ${response.body}',
    );
  }

  Future<ReservationModel> registerReservation({
    DateTime? reservationTime,
    required String tableId,
    required String customerName,
    required String customerPhone,
    List<SelectedItem>? items,
    int? bidPrice,
    String? idToken,
  }) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/tables/${tableId}/register-reservation',
    );

    final body = {
      if (reservationTime != null) 'reservation_time': reservationTime.toUtc().toIso8601String(),
      'customer_name': customerName,
      'customer_phone': customerPhone,
      // if (items != null)
      //   'purchases': items
      //       .map(
      //         (item) => {
      //           'item_id': item.itemId,
      //           'quantity': item.quantity,
      //         },
      //       )
      //       .toList(), //json(map)들의 리스트가 간다.
      'bid_price': bidPrice,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return ReservationModel.fromJson(data);
    }
    throw Exception(
      'Failed to register Reservation: ${response.statusCode} ${response.body}',
    );
  }

  Future<ReservationModel> createReservation({
    DateTime? reservationTime,
    required String tableId,
    required String customerName,
    required String customerPhone,
    int? bidPrice,
  }) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/reservations',
    );

    final body = {
      if (reservationTime != null) 'reservation_time': reservationTime.toUtc().toIso8601String(),
      'customer_name': customerName,
      'customer_phone': customerPhone,
      if (bidPrice != null) 'bid_price': bidPrice,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return ReservationModel.fromJson(data);
    }
    throw Exception(
      'Failed to register Reservation: ${response.statusCode} ${response.body}',
    );
  }


  Future<TableModel> reservationCheckIn({
    required int reservationId,
  }) async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}/reservations/${reservationId}/check-in',
    );
    print("ReservationId: $reservationId");
    print("URl: $url");

    final response = await http.post(
      url,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
       print('check-in response body: ${response.body}');
      final Map<String, dynamic> data = jsonDecode(response.body);
      return TableModel.fromJson(data);
    }
    throw Exception(
      'Failed to check-in Reservation: ${response.statusCode} ${response.body}',
    );
  }
}
