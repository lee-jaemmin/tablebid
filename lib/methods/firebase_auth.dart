import 'package:firebase_auth/firebase_auth.dart';

Future<Map<String, String>> firebaseAuthHeaders() async {
  final user = FirebaseAuth.instance.currentUser;

  if(user == null) {
    throw Exception('로그인이 필요합니다.');
  }
  final token = await user.getIdToken();
  return {
    'Authorization': "Bearer $token",
    'Content-type': 'application/json'
  };
}