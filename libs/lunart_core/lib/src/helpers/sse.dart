import 'dart:io';
import 'dart:convert';

import '../server/server.dart';

class SSEStream {
  SSEStream(this.socket) {
    socket
        .drain()
        .onError((_, __) {
          // no-op
        })
        .whenComplete(() {
          close();
        });

    socket.done
        .onError((_, __) {
          // no-op
        })
        .whenComplete(() {
          for (final listener in onCloseListeners) {
            listener();
          }
        });
  }

  final Socket socket;

  final onCloseListeners = <Function>[];

  void sendRaw(String data) {
    socket.add(data.codeUnits);
  }

  void sendText(String message, {String? event, String? id, int? retry}) {
    var rawText = '';
    if (event != null) {
      rawText += 'event: $event\n';
    }
    for (final line in message.split('\n')) {
      rawText += 'data: $line\n';
    }
    if (id != null) {
      rawText += 'id: $id\n';
    }
    if (retry != null) {
      rawText += 'retry: $retry\n';
    }
    rawText += '\n\n';
    sendRaw(rawText);
  }

  Future flush() async {
    return socket.flush();
  }

  /// Even though it looks like we're sending json here
  /// but the fact is that we're simply converting it to string and sending it to the client.
  /// The client will receive it as a string and will have to parse it.
  void sendJson(Object data, {String? event, String? id, int? retry}) {
    sendText(json.encode(data), event: event, id: id, retry: retry);
  }

  Future close() {
    return socket.close();
  }

  void onClose(Function cb) {
    onCloseListeners.add(cb);
  }
}

Response streamEvent(Function(SSEStream) callback, [Response? response]) {
  response ??= Response();
  return response.hijack((httpResponse, response) async {
    final socket = await httpResponse.detachSocket(writeHeaders: false);
    final sse = SSEStream(socket);
    var headersStr = 'HTTP/1.1 200 OK\n';
    final headers = {
      ...response.headers,
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    };
    headers.forEach((key, value) {
      headersStr += '$key: $value\n';
    });
    headersStr += '\n\n';
    sse.sendRaw(headersStr);

    callback(sse);
  });
}
