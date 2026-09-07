import 'package:http/http.dart' as http;
import 'package:tablebid/methods/firebase_auth.dart';
import 'package:tablebid/services/api_client.dart';

class NoShowApi {
  Future<void> noShow ({
    required int reservationId
  }) async {
    final url = Uri.parse('${ApiClient.baseUrl}/reservations/$reservationId/no-show');
    final response = await http.patch(
      url,
      headers: await firebaseAuthHeaders(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }
    throw Exception(
      "Failed to progress no show: ${response.statusCode} ${response.body}"
    );
  }
}