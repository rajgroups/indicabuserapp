import 'dart:convert';
import 'dart:io';

class SocketService {
  WebSocket? _socket;

  Future<void> connect(String token) async {
    final url = 'ws://10.46.210.83:9502?token=$token';

    _socket = await WebSocket.connect(url);

    print('Connected');

    _socket!.listen(
      (data) {
        print('RECEIVED => $data');
      },
      onDone: () {
        print('Disconnected');
      },
      onError: (e) {
        print('Socket Error: $e');
      },
    );
  }
}