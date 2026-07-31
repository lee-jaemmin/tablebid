class WebSocketEvent {
  final String type;
  final Map<String, dynamic> payload;

  const WebSocketEvent({
    required this.type,
    required this.payload,
  });

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    return WebSocketEvent(
      type: json['type'] as String,
      payload: payload is Map<String, dynamic> ? payload : const {},
    );
  }
}
