import 'dart:async';
import 'dart:convert';

import 'package:tablebid/models/web_socket_event.dart';
import 'package:tablebid/services/api_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class WebsocketService {
  WebsocketService._();

  static final WebsocketService instance = WebsocketService._();

  final StreamController<WebSocketEvent> _eventController =
      StreamController<WebSocketEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;
  Timer? _reconnectTimer;
  String? _companyId;
  int _reconnectAttempts = 0;
  int _connectionGeneration = 0; // 같은 회사에서 빠르게 재연결 시 구분자 역할.
  bool _manuallyDisconnected = false;
  WebSocketConnectionState _state = WebSocketConnectionState.disconnected;

  Stream<WebSocketEvent> get events => _eventController.stream;
  WebSocketConnectionState get state => _state;

  Future<void> connect(String companyId) async {
    if (_companyId == companyId &&
        (_state == WebSocketConnectionState.connected ||
            _state == WebSocketConnectionState.connecting ||
            _state == WebSocketConnectionState.reconnecting)) {
              // 옮은 회사에 잘 연결되어있으면
      return; // 함수 종료
    }

    await disconnect();
    _companyId = companyId;
    _manuallyDisconnected = false;
    final generation = _connectionGeneration;
    await _openConnection(companyId, generation);
  }

  Future<void> _openConnection(String companyId, int generation) async {
    if (_manuallyDisconnected ||
        _companyId != companyId ||
        generation != _connectionGeneration) {
      return;
    }

    _state = WebSocketConnectionState.connecting;
    try {
      final channel = WebSocketChannel.connect(
        Uri.parse(ApiClient.getWebSocketUrl(companyId)),
      );
      _channel = channel;
      await channel.ready;

      if (_manuallyDisconnected ||
          _companyId != companyId ||
          generation != _connectionGeneration) {
        await channel.sink.close();
        return;
      }

      _state = WebSocketConnectionState.connected;
      _socketSubscription = channel.stream.listen(
        _handleMessage,
        onError: (_) => _handleDisconnection(companyId, generation),
        onDone: () => _handleDisconnection(companyId, generation),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect(companyId, generation);
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      _reconnectAttempts = 0;
      _eventController.add(WebSocketEvent.fromJson(data));
    } catch (error, stackTrace) {
      _eventController.addError(error, stackTrace);
    }
  }

  void _handleDisconnection(String companyId, int generation) {
    if (generation != _connectionGeneration) return;
    _socketSubscription = null;
    _channel = null;
    _scheduleReconnect(companyId, generation);
  }

  void _scheduleReconnect(String companyId, int generation) {
    if (_manuallyDisconnected ||
        _companyId != companyId ||
        generation != _connectionGeneration ||
        _reconnectTimer != null) {
      return;
    }

    _state = WebSocketConnectionState.reconnecting;
    final seconds = switch (_reconnectAttempts) {
      0 => 1,
      1 => 2,
      2 => 4,
      3 => 8,
      _ => 15,
    };
    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      _reconnectTimer = null;
      _openConnection(companyId, generation);
    });
  }

  Future<void> disconnect() async {
    _manuallyDisconnected = true;
    _connectionGeneration++;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    final subscription = _socketSubscription;
    final channel = _channel;
    _socketSubscription = null;
    _channel = null;
    _companyId = null;
    _reconnectAttempts = 0;
    _state = WebSocketConnectionState.disconnected;

    await subscription?.cancel();
    await channel?.sink.close();
  }
}
