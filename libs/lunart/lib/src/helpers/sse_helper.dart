import 'dart:async';
import 'dart:convert';

enum SSEEvents {
  close,
}

class SSEHelper {
  late final StreamController<String> _controller;
  final _internalEventsController = StreamController<SSEEvents>();

  Stream<String> get stream => _controller.stream;

  SSEHelper() {
    _controller = StreamController<String>(
      onCancel: _handleCancel,
    );
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

    _controller.add(rawText);
  }

  /// Even though it looks like we're sending json here
  /// but the fact is that we're simply converting it to string and sending it to the client.
  /// The client will receive it as a string and will have to parse it.
  void sendJson(Object data, {String? event, String? id, int? retry}) {
    sendText(json.encode(data), event: event, id: id, retry: retry);
  }

  Future close() {
    return _controller.close();
  }

  void onClose(Function cb) {
    _internalEventsController.stream.listen(
      (event) => event == SSEEvents.close ? cb() : null,
    );
  }

  void _handleCancel() {
    _internalEventsController.add(SSEEvents.close);
    _internalEventsController.close();
  }
}
