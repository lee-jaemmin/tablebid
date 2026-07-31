class ApiClient {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static String getWebSocketUrl(String companyId) {
    final apiUri = Uri.parse(baseUrl);

    final wsScheme = apiUri.scheme == 'https' ? 'wss' : 'ws';

    return Uri(
      scheme: wsScheme,
      host: apiUri.host,
      port: apiUri.hasPort ? apiUri.port : null,
      path: '/ws/companies/$companyId',
    ).toString();
  }
}
