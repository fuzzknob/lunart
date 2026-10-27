import 'dart:async';
import 'dart:convert';

import 'package:lunart/lunart.dart';

void main() {
  final app = Lunart();
  Message? message;

  final broadcaster = StreamController<Message>.broadcast();

  app.plug(StaticPlugin(route: '*'));

  app.ws('/ws', (socket) {
    StreamSubscription<Message>? sub;

    socket.onOpen((controller) {
      sub = broadcaster.stream.listen((msg) {
        // Send json message
        controller.sendJson(msg);
      });

      if (message != null) {
        broadcaster.add(message!);
      }
    });

    socket.onMessage((data, controller) {
      message = Message.fromJson(json.decode(data as String));

      broadcaster.add(message!);
    });

    socket.onError((e, controller) {
      print(e);
    });

    socket.onClose((_) {
      sub?.cancel();
    });
  });

  app.serve();
}

class Message({
  required final int id,
  required final String content,
}) implements ToJson {
  @override
  String toString() {
    return 'Message(id = $id, message = $content)';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
    };
  }

  factory fromJson(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      content: map['content'] ?? '',
    );
  }
}
