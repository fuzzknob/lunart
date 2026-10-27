import 'dart:async';
import 'dart:io';
import 'dart:convert' as convert;

import 'package:crypto/crypto.dart';

import 'types.dart';
import 'exceptions/not_found_exception.dart';
import 'exceptions/bad_request_exception.dart';
import 'interfaces/to_json.dart';
import 'interfaces/response_thief.dart';
import 'exceptions/exception.dart';
import 'response.dart';

class IOWebSocketResponse implements ResponseThief {
  final Duration? pingInterval;
  late final WebSocketController wsController;
  late final WebSocketListener wsListener;
  WebSocket? _ioWS;

  IOWebSocketResponse({
    this.pingInterval,
  }) {
    wsController = WebSocketController(
      handleClose: _handleClose,
      handleSend: _handleSend,
    );
    wsListener = WebSocketListener(wsController: wsController);
  }

  @override
  Future<void> writeResponse(
    HttpResponse httpResponse,
    Response _,
  ) async {
    final socket = await httpResponse.detachSocket();

    final ws = WebSocket.fromUpgradedSocket(socket, serverSide: true);

    _ioWS = ws;

    ws.pingInterval = pingInterval ?? Duration(seconds: 120);

    wsListener.eventController.add((WebSocketEvent.open, null));

    final eventController = wsListener.eventController;

    ws.listen(
      (data) {
        eventController.add((WebSocketEvent.message, data));
      },
      onDone: () async {
        wsListener.eventController.add((WebSocketEvent.close, null));

        await wsListener.eventController.close();

        ws.close();
      },
      onError: (error) {
        wsListener.eventController.add((WebSocketEvent.error, error));
      },
    );

    await ws.done;
  }

  WebSocket _getIoWS() {
    if (_ioWS == null) {
      throw LunartException(message: 'Websocket is not open yet.');
    }

    return _ioWS!;
  }

  void _handleSend(Object? data) {
    // TODO: Backpressured send
    try {
      final io = _getIoWS();

      if (data is Stream) {
        io.addStream(data);
        return;
      }

      io.add(data);
    } catch (e) {
      print(e);
    }
  }

  Future<void> _handleClose() async {
    final io = _getIoWS();

    await io.close();
  }
}

enum WebSocketEvent {
  open,
  message,
  close,
  error,
}

class WebSocketListener {
  final WebSocketController wsController;
  final eventController =
      StreamController<(WebSocketEvent event, Object? data)>.broadcast();

  WebSocketListener({
    required this.wsController,
  });

  WebSocketListener onOpen(Function(WebSocketController) listener) {
    eventController.stream.listen((r) {
      final (event, _) = r;

      try {
        if (event == WebSocketEvent.open) {
          listener(wsController);
        }
      } catch (e) {
        eventController.add((WebSocketEvent.error, e));
      }
    });

    return this;
  }

  WebSocketListener onClose(Function(WebSocketController controller) listener) {
    eventController.stream.listen((r) async {
      final (event, _) = r;

      try {
        if (event == WebSocketEvent.close) {
          listener(wsController);
        }
      } catch (e) {
        eventController.add((WebSocketEvent.error, e));
      }
    });

    return this;
  }

  WebSocketListener onMessage(
    Function(Object? data, WebSocketController controller) listener,
  ) {
    eventController.stream.listen(
      (r) {
        final (event, data) = r;
        try {
          if (event == WebSocketEvent.message) {
            listener(data, wsController);
          }
        } catch (e) {
          eventController.add((WebSocketEvent.error, e));
        }
      },
    );

    return this;
  }

  WebSocketListener onError(
    Function(Object? data, WebSocketController controller) listener,
  ) {
    eventController.stream.listen((r) {
      final (event, error) = r;
      try {
        if (event == WebSocketEvent.error) {
          listener(error, wsController);
        }
      } catch (e) {
        // We basically ignore the error and don't create another error event as it can lead to infinite loop
        print(e);
      }
    });

    return this;
  }
}

class WebSocketController {
  final Function() _handleClose;
  final Function(Object? data) _handleSend;

  WebSocketController({
    required this._handleClose,
    required this._handleSend,
  });

  void send(Object? data) {
    _handleSend(data);
  }

  void sendText(String text) {
    send(text);
  }

  void sendJson(Object object) {
    var json = object;

    if (object is ToJson) {
      json = object.toJson();
    } else if (object is Iterable<ToJson>) {
      json = object.map((o) => o.toJson()).toList();
    }

    send(convert.jsonEncode(json));
  }

  void close() {
    _handleClose();
  }
}

class WebSocketRequestHandler {
  static const String websocketGUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

  final Duration? pingInterval;

  WebSocketRequestHandler({
    this.pingInterval,
  });

  Handler handleWebsocket(void Function(WebSocketListener) wsHandler) {
    return (req) {
      final connectionHeader = req.headers['connection'];

      if (connectionHeader == null ||
          connectionHeader.toLowerCase() != 'upgrade') {
        throw NotFoundException();
      }

      final upgradeHeader = req.headers['upgrade'];

      if (upgradeHeader == null || upgradeHeader != 'websocket') {
        throw BadRequestException();
      }

      final versionHeader = req.headers['sec-websocket-version'];

      if (versionHeader == null) throw BadRequestException();

      if (versionHeader != '13') {
        return Res.status(426).header('Sec-WebSocket-Version', '13');
      }

      final key = req.headers['sec-websocket-key'];

      if (key == null) return throw BadRequestException();

      final webSocketResponse = IOWebSocketResponse(pingInterval: pingInterval);

      wsHandler(webSocketResponse.wsListener);

      return Res.status(101)
          .header('Connection', 'Upgrade')
          .header('Upgrade', 'websocket')
          .header('Sec-WebSocket-Version', 13)
          .header('Content-Length', 0)
          .header('Sec-WebSocket-Accept', hashWebsocketKey(key))
          .setBody(webSocketResponse);
    };
  }

  String hashWebsocketKey(String key) {
    final shaHash = sha1.convert(
      convert.utf8.encode(key + websocketGUID),
    );

    return convert.base64Encode(shaHash.bytes);
  }
}
