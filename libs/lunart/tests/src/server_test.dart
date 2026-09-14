import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:lunart/src/enums/method.dart';
import 'package:lunart/src/exceptions/exception.dart';
import 'package:lunart/src/interfaces/request_handler.dart';
import 'package:lunart/src/request.dart';
import 'package:lunart/src/response.dart';
import 'package:lunart/src/server.dart';

class _CallbackRequestHandler implements RequestHandler {
  _CallbackRequestHandler(this.callback);

  final FutureOr<Object?> Function(Request request) callback;

  @override
  Future handleRequest(Request request) async {
    return await callback(request);
  }
}

Future<({HttpClientResponse response, String body})> _sendToIncomingHandler({
  required Future<void> Function(HttpRequest request) onRequest,
  String method = 'GET',
  String path = '/',
  Map<String, String> headers = const {},
  List<int>? bodyBytes,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final handledCompleter = Completer<void>();

  server.listen((request) async {
    try {
      await onRequest(request);
      if (!handledCompleter.isCompleted) {
        handledCompleter.complete();
      }
    } catch (error, stackTrace) {
      if (!handledCompleter.isCompleted) {
        handledCompleter.completeError(error, stackTrace);
      }
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  });

  final parsedPath = Uri.parse(path.startsWith('/') ? path : '/$path');
  final uri = Uri(
    scheme: 'http',
    host: InternetAddress.loopbackIPv4.address,
    port: server.port,
    path: parsedPath.path,
    query: parsedPath.hasQuery ? parsedPath.query : null,
  );

  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    headers.forEach(request.headers.set);
    if (bodyBytes != null && bodyBytes.isNotEmpty) {
      request.add(bodyBytes);
    }

    final response = await request.close();
    final body = await convert.utf8.decodeStream(response);
    await handledCompleter.future;

    return (response: response, body: body);
  } finally {
    client.close(force: true);
    await server.close(force: true);
  }
}

void main() {
  group('Server.makeLunartRequest', () {
    test('maps native request fields to Request', () async {
      final server = Server();
      late Request lunartRequest;

      await _sendToIncomingHandler(
        path: '/users',
        method: 'POST',
        headers: {
          'x-token': 'abc123',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        bodyBytes: convert.utf8.encode('{"ok":true}'),
        onRequest: (nativeRequest) async {
          lunartRequest = await server.makeLunartRequest(nativeRequest);
          nativeRequest.response.statusCode = HttpStatus.ok;
          await nativeRequest.response.close();
        },
      );

      expect(lunartRequest.path, '/users');
      expect(lunartRequest.method, Method.post);
      expect(lunartRequest.queries, isEmpty);
      expect(lunartRequest.headers['x-token'], 'abc123');
      expect(
        lunartRequest.headers[HttpHeaders.contentTypeHeader],
        contains('application/json'),
      );
      expect(lunartRequest.nativeRequest, isA<HttpRequest>());
    });

    test('maps query parameters from uri', () async {
      final server = Server();
      late Request lunartRequest;

      await _sendToIncomingHandler(
        path: '/search?query=dart&page=2',
        onRequest: (nativeRequest) async {
          lunartRequest = await server.makeLunartRequest(nativeRequest);
          nativeRequest.response.statusCode = HttpStatus.ok;
          await nativeRequest.response.close();
        },
      );

      expect(lunartRequest.path, '/search');
      expect(lunartRequest.queries, {'query': 'dart', 'page': '2'});
    });
  });

  group('Server.getStreamedResponse', () {
    test('returns Stream<List<int>> unchanged', () async {
      final server = Server();
      final source = Stream<List<int>>.fromIterable([
        [65, 66],
        [67],
      ]);

      final stream = server.getStreamedResponse(source);
      final chunks = await stream.toList();

      expect(chunks, [
        [65, 66],
        [67],
      ]);
    });

    test('converts Stream<String> to Stream<List<int>>', () async {
      final server = Server();
      final source = Stream<String>.fromIterable(['A', 'BC']);

      final stream = server.getStreamedResponse(source);
      final chunks = await stream.toList();

      expect(chunks, [
        [65],
        [66, 67],
      ]);
    });

    test('converts Stream<Uint8List> to Stream<List<int>>', () async {
      final server = Server();
      final source = Stream<Uint8List>.fromIterable([
        Uint8List.fromList([1, 2]),
        Uint8List.fromList([3]),
      ]);

      final stream = server.getStreamedResponse(source);
      final chunks = await stream.toList();

      expect(chunks, [
        [1, 2],
        [3],
      ]);
    });

    test('throws LunartException for unsupported stream type', () {
      final server = Server();
      final source = Stream<int>.fromIterable([1, 2, 3]);

      expect(
        () => server.getStreamedResponse(source),
        throwsA(isA<LunartException>()),
      );
    });
  });

  group('Server.writeResponse', () {
    test('writes status, headers, body, and closes response', () async {
      final server = Server();
      final lunartResponse = Res.status(HttpStatus.created)
          .header('x-trace', 'trace-id')
          .text('created');

      final result = await _sendToIncomingHandler(
        onRequest: (request) async {
          await server.writeResponse(lunartResponse, request.response);
        },
      );

      expect(result.response.statusCode, HttpStatus.created);
      expect(result.response.headers.value('x-trace'), 'trace-id');
      expect(
        result.response.headers.contentType?.toString(),
        'text/plain; charset=utf-8',
      );
      expect(result.body, 'created');
    });

    test('writes stream body through addStream', () async {
      final server = Server();
      final lunartResponse = Res.stream(
        Stream<String>.fromIterable(['A', 'B', 'C']),
      );

      final result = await _sendToIncomingHandler(
        onRequest: (request) async {
          await server.writeResponse(lunartResponse, request.response);
        },
      );

      expect(result.response.statusCode, HttpStatus.ok);
      expect(result.body, 'ABC');
    });

    test('writes cookies with configured attributes', () async {
      final server = Server();
      final expiresAt = DateTime.utc(2030, 1, 1);
      final lunartResponse = Res.cookie(
        'session',
        'abc123',
        httpOnly: true,
        secure: false,
        path: '/api',
        domain: 'localhost',
        maxAge: Duration(minutes: 5),
        expires: expiresAt,
        sameSite: SameSite.strict,
      ).text('ok');

      final result = await _sendToIncomingHandler(
        onRequest: (request) async {
          await server.writeResponse(lunartResponse, request.response);
        },
      );

      final setCookieHeader =
          result.response.headers[HttpHeaders.setCookieHeader]?.join(';') ?? '';

      expect(setCookieHeader, contains('session=abc123'));
      expect(setCookieHeader, contains('HttpOnly'));
      expect(setCookieHeader, contains('Path=/api'));
      expect(setCookieHeader, contains('Max-Age=300'));
      expect(setCookieHeader, contains('SameSite=Strict'));
    });

    test('throws when signed cookie has not been signed', () async {
      final server = Server();
      final lunartResponse = Res.signedCookie(
        'token',
        'raw',
      ).text('will-not-write');
      Object? capturedError;

      final result = await _sendToIncomingHandler(
        onRequest: (request) async {
          try {
            await server.writeResponse(lunartResponse, request.response);
          } catch (error) {
            capturedError = error;
            request.response.statusCode = HttpStatus.internalServerError;
            request.response.write('error');
            await request.response.close();
          }
        },
      );

      expect(capturedError, isA<Exception>());
      expect(capturedError.toString(), contains('wasn\'t signed'));
      expect(result.response.statusCode, HttpStatus.internalServerError);
      expect(result.body, 'error');
    });
  });

  group('Server.handleRequest integration', () {
    test('runs global middlewares then router and resolves output', () async {
      final calls = <String>[];
      final server = Server()
        ..use((request, next) async {
          calls.add('mw-before');
          request.context['trace'] = 'ok';
          final value = await next();
          calls.add('mw-after');
          return value;
        });

      server.router = _CallbackRequestHandler((request) {
        calls.add('handler');
        expect(request.context['trace'], 'ok');
        return 'hello';
      });

      final result = await _sendToIncomingHandler(
        path: '/greet',
        onRequest: (request) async {
          server.handleRequest(request);
        },
      );

      expect(result.response.statusCode, HttpStatus.ok);
      expect(result.body, 'hello');
      expect(
        result.response.headers.contentType?.toString(),
        'text/plain; charset=utf-8',
      );
      expect(calls, ['mw-before', 'handler', 'mw-after']);
    });

    test('uses custom registered response resolver in handleRequest', () async {
      final server = Server()
        ..registerResponseResolver<String>(
          (value) => Res.status(HttpStatus.created).text('custom:$value'),
        );

      server.router = _CallbackRequestHandler((_) => 'payload');

      final result = await _sendToIncomingHandler(
        onRequest: (request) async {
          server.handleRequest(request);
        },
      );

      expect(result.response.statusCode, HttpStatus.created);
      expect(result.body, 'custom:payload');
      expect(
        result.response.headers.contentType?.toString(),
        'text/plain; charset=utf-8',
      );
    });
  });
}
