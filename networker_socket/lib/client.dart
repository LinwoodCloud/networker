import 'dart:async';
import 'dart:convert';

import 'package:networker/networker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class SocketClient extends NetworkingClient {
  WebSocketChannel? _channel;
  final Uri uri;

  @override
  String get identifier => uri.toString();

  SocketClient(this.uri);

  @override
  bool isConnected() => _channel != null && _channel?.closeCode == null;

  @override
  FutureOr<void> send(
      {required String service,
      required String event,
      required String data}) async {
    _channel?.sink
        .add(json.encode({'service': service, 'event': event, 'data': data}));
    await _channel?.sink.close();
  }

  @override
  FutureOr<void> start() async {
    await stop();
    _channel = WebSocketChannel.connect(uri);
    _channel?.stream.listen(_handleData);
  }

  @override
  FutureOr<void> stop() {
    _channel?.sink.close(0, "disconnect");
    _channel = null;
  }

  void _handleData(dynamic event) {
    final message = json.decode(event);
    if (message is! Map) {
      _channel?.sink.close(status.protocolError);
      return;
    }
    handle(message);
  }
}
