import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';

/// A map to hold event handlers.
typedef EventCallback = void Function(dynamic data);

class SocketService extends GetxService {
  WebSocket? _socket;
  String? _token;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  /// Base URL for the WebSocket connection.
  final String _baseUrl = 'ws://10.46.210.83:9502';

  /// Reactive flag to observe connection status across the app.
  final RxBool isConnected = false.obs;

  /// A map to store event listeners. Controllers can subscribe to events they are interested in.
  final Map<String, List<EventCallback>> _eventListeners = {};

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  /// Establishes a connection to the WebSocket server.
  /// It stores the token for automatic reconnection.
  Future<void> connect(String token) async {
    _token = token;
    final url = '$_baseUrl?token=$_token';

    try {
      _socket = await WebSocket.connect(url);
      isConnected.value = true;
      print('WebSocket: Connected successfully.');

      _socket!.listen(
        _onData,
        onDone: _onDone,
        onError: _onError,
        cancelOnError: true,
      );

      // Handle the connection event
      _handleConnected();
    } catch (e) {
      print('WebSocket: Connection error: $e');
      _onError(e);
    }
  }

  /// Closes the WebSocket connection and stops any timers.
  void disconnect() {
    print('WebSocket: Disconnecting...');
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _socket?.close();
    _socket = null;
    isConnected.value = false;
  }

  /// Sends data to the server. The data is encoded as a JSON string.
  void send(Map<String, dynamic> data) {
    if (_socket != null && isConnected.value) {
      final message = json.encode(data);
      print('WebSocket: SEND => $message');
      _socket!.add(message);
    } else {
      print('WebSocket: Cannot send data, socket is not connected.');
    }
  }

  /// Sends a ping message to keep the connection alive.
  void sendPing() {
    send({'type': 'ping'});
  }

  /// Allows other parts of the app to subscribe to a specific event type.
  void on(String event, EventCallback callback) {
    _eventListeners.putIfAbsent(event, () => []).add(callback);
  }

  /// Allows other parts of the app to unsubscribe from an event.
  void off(String event, EventCallback callback) {
    if (_eventListeners.containsKey(event)) {
      _eventListeners[event]!.remove(callback);
    }
  }

  /// Internal handler for incoming data.
  void _onData(dynamic data) {
    print('WebSocket: RECEIVED => $data');
    try {
      final Map<String, dynamic> message = json.decode(data);
      final String eventType = message['type'] ?? 'unknown';

      // Route event to a specific handler if needed, e.g., for global actions.
      _routeEvent(eventType, message);

      // Notify generic listeners for this event type
      if (_eventListeners.containsKey(eventType)) {
        for (var callback in _eventListeners[eventType]!) {
          callback(message);
        }
      }
    } catch (e) {
      print('WebSocket: Error parsing message: $e');
    }
  }

  /// Internal handler for when the connection is closed by the server.
  void _onDone() {
    print('WebSocket: Disconnected by server.');
    isConnected.value = false;
    _pingTimer?.cancel();
    _tryReconnect();
  }

  /// Internal handler for any connection errors.
  void _onError(dynamic error) {
    print('WebSocket: Socket Error: $error');
    isConnected.value = false;
    _pingTimer?.cancel();
    _tryReconnect();
  }

  /// Attempts to reconnect to the server after a delay.
  void _tryReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;

    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      print('WebSocket: Attempting to reconnect...');
      if (_token != null) {
        connect(_token!);
      } else {
        print('WebSocket: Cannot reconnect, token is missing.');
      }
    });
  }

  /// Routes events to internal handlers for global actions.
  void _routeEvent(String eventType, Map<String, dynamic> data) {
    switch (eventType) {
      case 'pong':
        _handlePong();
        break;
      case 'auth_error':
        _handleAuthError(data);
        break;
      // Specific booking events are now handled by listeners,
      // but you could add global handlers here if needed.
      case 'booking_request':
      case 'booking_status':
        break;
      default:
        print('WebSocket: Received unknown event type: $eventType');
    }
  }
  // --- Event Handler Methods ---

  void _handleConnected() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      sendPing();
    });
  }

  void _handleAuthError(Map<String, dynamic> data) {
    print('WebSocket: Authentication error: ${data['message']}');
    disconnect();
    // Optionally, navigate to login screen
  }

  void _handlePong() {
    print('WebSocket: Pong received.');
  }
}