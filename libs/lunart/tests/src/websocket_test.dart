import 'dart:io';

import 'package:lunart/lunart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// import 'package:lunart/src/response.dart';
// import 'package:lunart/src/enums/method.dart';
// import 'package:lunart/src/request.dart';
// import 'package:lunart/src/exceptions/bad_request_exception.dart';
//
// import 'package:lunart/src/websocket.dart';

class _MockHttpRequest extends Mock implements HttpRequest {}

void main() {
  group('WebSocketListener', () {
    late WebSocketListener listener;

    setUp(() {
      final controller = WebSocketController(
        handleClose: () {},
        handleSend: (_) {},
      );
      listener = WebSocketListener(
        wsController: controller,
      );
    });

    test('listeners registers and triggered on events', () async {
      var isOpenCalled = false;
      var isMessageCalled = false;
      var isCloseCalled = false;
      var isErrorCalled = false;

      listener.onOpen((_) {
        isOpenCalled = true;
      });
      listener.onMessage((_, _) {
        isMessageCalled = true;
      });
      listener.onClose((_) {
        isCloseCalled = true;
      });
      listener.onError((_, _) {
        isErrorCalled = true;
      });

      listener.eventController.add((WebSocketEvent.open, null));
      listener.eventController.add((WebSocketEvent.message, null));
      listener.eventController.add((WebSocketEvent.error, null));
      listener.eventController.add((WebSocketEvent.close, null));

      // Wait till the future queue is run
      await Future.delayed(Duration.zero);

      expect(isOpenCalled, true);
      expect(isMessageCalled, true);
      expect(isCloseCalled, true);
      expect(isErrorCalled, true);
    });

    test('onError is triggered when error thrown in listeners', () async {
      var errorCallCount = 0;

      listener.onError((_, _) {
        errorCallCount += 1;
      });
      listener.onOpen((_) {
        throw '';
      });
      listener.onMessage((_, _) {
        throw '';
      });
      listener.onClose((_) {
        throw '';
      });

      listener.eventController.add((WebSocketEvent.open, null));
      listener.eventController.add((WebSocketEvent.message, null));
      listener.eventController.add((WebSocketEvent.close, null));

      // Wait till the future queue is run
      await Future.delayed(Duration.zero);

      expect(errorCallCount, 3);
    });

    test("If there's an error in onError itself. It doesn't call onError and create infinite loop", () async {
      var callCount = 0;

      listener.onError((_, _) {
        callCount += 1;

        if (callCount == 1) {
          throw '';
        }
      });

      listener.eventController.add((WebSocketEvent.error, null));

      // Wait till the future queue is run
      await Future.delayed(Duration.zero);

      expect(callCount, 1);
    });
  });

  group('WebSocketController', () {
    test('send method calls the handleSend callback', () {
      var isHandleSendCalled = false;

      final controller = WebSocketController(
        handleSend: (_) {
          isHandleSendCalled = true;
        },
        handleClose: () {
          //
        },
      );

      controller.send('');

      expect(isHandleSendCalled, true);
    });

    test('close method calls the handleClose callback', () {
      var isHandleCloseCalled = false;

      final controller = WebSocketController(
        handleSend: (_) {},
        handleClose: () {
          isHandleCloseCalled = true;
        },
      );

      controller.close();

      expect(isHandleCloseCalled, true);
    });

    test(
      'sendJson method normalize json to string before calling handleSend',
      () {
        Object? output;

        final controller = WebSocketController(
          handleSend: (data) {
            output = data;
          },
          handleClose: () {},
        );

        controller.sendJson({
          'message': 'This is a test json',
        });

        expect(output.runtimeType, String);
        expect(output, '{"message":"This is a test json"}');
      },
    );
  });

  group('IOWebSocketResponse', () {
    // TODO: write integration testing for IOWebSocketResponse
    // use dart websocket
  });

  group('WebSocketRequestHandler', () {
    test('creates upgrade response', () async {
      final wsHandler = WebSocketRequestHandler();

      final handler = wsHandler.handleWebsocket((_) {});

      var response = await handler(
        Request(
          headers: {
            'connection': 'upgrade',
            'upgrade': 'websocket',
            'sec-websocket-key': 'dGhlIHNhbXBsZSBub25jZQ==',
            'sec-websocket-version': '13',
          },
          path: 'ws',
          method: Method.get,
          nativeRequest: _MockHttpRequest(),
          queries: {},
        ),
      );

      expect(response, isNotNull);
      expect(response.runtimeType, Response);

      response = response as Response;

      expect(
        response.headers,
        equals({
          'Connection': 'Upgrade',
          'Upgrade': 'websocket',
          'Sec-WebSocket-Version': 13,
          'Content-Length': 0,
          'Sec-WebSocket-Accept': 's3pPLMBiTxaQ9kYGzzhZRbK+xOo=',
        }),
      );
      expect(response.statusCode, 101);
    });

    test('throws NotFoundException if connection header is missing', () {
      final wsHandler = WebSocketRequestHandler();
      final handler = wsHandler.handleWebsocket((_) {});

      final badRequest = Request(
        headers: {
          'upgrade': 'websocket',
          'sec-websocket-key': 'dGhlIHNhbXBsZSBub25jZQ==',
          'sec-websocket-version': '13',
        },
        path: 'ws',
        method: Method.get,
        nativeRequest: _MockHttpRequest(),
        queries: {},
      );

      expect(
        () => handler(badRequest),
        throwsA(isA<NotFoundException>()),
      );
    });

    test(
      'throws BadRequest if upgrade header is not passed',
      () {
        final wsHandler = WebSocketRequestHandler();
        final handler = wsHandler.handleWebsocket((_) {});

        final badRequest = Request(
          headers: {
            'connection': 'upgrade',
            'sec-websocket-key': 'dGhlIHNhbXBsZSBub25jZQ==',
            'sec-websocket-version': '13',
          },
          path: 'ws',
          method: Method.get,
          nativeRequest: _MockHttpRequest(),
          queries: {},
        );

        expect(
          () => handler(badRequest),
          throwsA(isA<BadRequestException>()),
        );
      },
    );

    test('throws BadRequest if sec-websocket-version header is not passed', () {
      final wsHandler = WebSocketRequestHandler();
      final handler = wsHandler.handleWebsocket((_) {});

      final badRequest = Request(
        headers: {
          'connection': 'upgrade',
          'upgrade': 'websocket',
          'sec-websocket-key': 'dGhlIHNhbXBsZSBub25jZQ==',
        },
        path: 'ws',
        method: Method.get,
        nativeRequest: _MockHttpRequest(),
        queries: {},
      );

      expect(
        () => handler(badRequest),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('throws BadRequest if sec-websocket-key header is not passed', () {
      final wsHandler = WebSocketRequestHandler();
      final handler = wsHandler.handleWebsocket((_) {});

      final badRequest = Request(
        headers: {
          'connection': 'upgrade',
          'upgrade': 'websocket',
          'sec-websocket-version': '13',
        },
        path: 'ws',
        method: Method.get,
        nativeRequest: _MockHttpRequest(),
        queries: {},
      );

      expect(
        () => handler(badRequest),
        throwsA(isA<BadRequestException>()),
      );
    });

    test('send correct response if version is not supported', () async {
      final wsHandler = WebSocketRequestHandler();

      final handler = wsHandler.handleWebsocket((_) {});

      var response = await handler(
        Request(
          headers: {
            'connection': 'upgrade',
            'upgrade': 'websocket',
            'sec-websocket-key': 'dGhlIHNhbXBsZSBub25jZQ==',
            'sec-websocket-version': '99',
          },
          path: 'ws',
          method: Method.get,
          nativeRequest: _MockHttpRequest(),
          queries: {},
        ),
      );

      response = response as Response;

      expect(response.statusCode, 426);
      expect(
        response.headers['Sec-WebSocket-Version'],
        '13',
      );
    });
  });
}
