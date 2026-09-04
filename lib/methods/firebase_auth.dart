import 'package:firebase_auth/firebase_auth.dart';

Future<Map<String, String>> firebaseAuthHeaders({
  bool forceRefresh = false,
  bool includeContentType = true,
  // 이미지 업로드에서는 얘가 false여야함.
  // multipart가 알아서 보내게 둬야하기 때문.
  // 'Content-type': 'application/json' 여부를 결정하는 파라미터
}) async {
  final user = FirebaseAuth.instance.currentUser;

  if(user == null) {
    throw Exception('로그인이 필요합니다.');
  }
  final token = await user.getIdToken(forceRefresh);
  return {
    'Authorization': "Bearer $token",
    if (includeContentType) 'Content-type': 'application/json'
  };
}
