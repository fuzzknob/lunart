import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:lunart/src/enums/method.dart';
import 'package:lunart/src/exceptions/bad_request_exception.dart';
import 'package:lunart/src/exceptions/exception.dart';
import 'package:lunart/src/request.dart';

class _MockHttpRequest extends Mock implements HttpRequest {}

Request _buildRequest(HttpRequest nativeRequest) {
  return Request(
    nativeRequest: nativeRequest,
    path: '/',
    method: Method.post,
    headers: {},
    queries: {},
  );
}

Future<T> _withNativeRequest<T>({
  required String method,
  String? contentTypeHeader,
  List<int>? bodyBytes,
  String path = '/',
  required Future<T> Function(HttpRequest nativeRequest) onRequest,
}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final resultCompleter = Completer<T>();
  final requestHandledCompleter = Completer<void>();

  server.listen((nativeRequest) async {
    try {
      final result = await onRequest(nativeRequest);

      if (!resultCompleter.isCompleted) {
        resultCompleter.complete(result);
      }

      nativeRequest.response.statusCode = HttpStatus.ok;
    } catch (error, stackTrace) {
      if (!resultCompleter.isCompleted) {
        resultCompleter.completeError(error, stackTrace);
      }

      nativeRequest.response.statusCode = HttpStatus.internalServerError;
    } finally {
      await nativeRequest.response.close();

      if (!requestHandledCompleter.isCompleted) {
        requestHandledCompleter.complete();
      }
    }
  });

  final uri = Uri(
    scheme: 'http',
    host: InternetAddress.loopbackIPv4.address,
    port: server.port,
    path: path,
  );

  final client = HttpClient();

  try {
    final request = await client.openUrl(method, uri);
    if (contentTypeHeader != null) {
      request.headers.set(HttpHeaders.contentTypeHeader, contentTypeHeader);
    }
    if (bodyBytes != null && bodyBytes.isNotEmpty) {
      request.add(bodyBytes);
    }

    final response = await request.close();
    await response.drain<void>();
    await requestHandledCompleter.future;

    return await resultCompleter.future;
  } finally {
    client.close(force: true);
    await server.close(force: true);
  }
}

void main() {
  group('Request.bytes', () {
    test('returns all raw chunks in order', () async {
      final chunks = await _withNativeRequest<List<List<int>>>(
        method: 'POST',
        bodyBytes: convert.utf8.encode('hello world'),
        onRequest: (nativeRequest) async {
          final request = _buildRequest(nativeRequest);
          final rawChunks = await request.bytes();

          return rawChunks.map((chunk) => chunk.toList()).toList();
        },
      );

      final flattened = chunks.expand((chunk) => chunk).toList();

      expect(flattened, convert.utf8.encode('hello world'));
      expect(chunks, isNotEmpty);
    });

    test('returns empty list when body is empty', () async {
      final chunks = await _withNativeRequest<List<List<int>>>(
        method: 'POST',
        onRequest: (nativeRequest) async {
          final request = _buildRequest(nativeRequest);
          final rawChunks = await request.bytes();

          return rawChunks.map((chunk) => chunk.toList()).toList();
        },
      );

      expect(chunks, isEmpty);
    });

    test('preserves binary payload bytes', () async {
      final payload = <int>[0, 255, 10, 42, 128, 64];

      final chunks = await _withNativeRequest<List<List<int>>>(
        method: 'POST',
        bodyBytes: payload,
        onRequest: (nativeRequest) async {
          final request = _buildRequest(nativeRequest);
          final rawChunks = await request.bytes();

          return rawChunks.map((chunk) => chunk.toList()).toList();
        },
      );

      final flattened = chunks.expand((chunk) => chunk).toList();

      expect(flattened, payload);
    });
  });

  group('Request.body', () {
    test('returns null when content type is missing', () async {
      final body = await _withNativeRequest<Map<String, dynamic>?>(
        method: 'GET',
        onRequest: (nativeRequest) async {
          final request = _buildRequest(nativeRequest);
          return await request.body();
        },
      );

      expect(body, isNull);
    });

    test('parses JSON body for application/json', () async {
      final body = await _withNativeRequest<Map<String, dynamic>?>(
        method: 'POST',
        contentTypeHeader: 'application/json; charset=utf-8',
        bodyBytes: convert.utf8.encode('{"name":"lunart","version":1}'),
        onRequest: (nativeRequest) async {
          final request = _buildRequest(nativeRequest);
          return await request.body();
        },
      );

      expect(body, {'name': 'lunart', 'version': 1});
    });

    test('throws BadRequestException when JSON body is invalid', () async {
      final result = await _withNativeRequest<Object?>(
        method: 'POST',
        contentTypeHeader: 'application/json',
        bodyBytes: convert.utf8.encode('{"name":'),
        onRequest: (nativeRequest) async {
          final request = _buildRequest(nativeRequest);
          try {
            return await request.body();
          } catch (error) {
            return error;
          }
        },
      );

      expect(result, isA<BadRequestException>());
    });

    test(
      'parses URL encoded form body and decodes values for application/x-www-form-urlencoded',
      () async {
        final body = await _withNativeRequest<Map<String, dynamic>?>(
          method: 'POST',
          contentTypeHeader: 'application/x-www-form-urlencoded',
          bodyBytes: convert.utf8.encode(
            'name=hello%20world&empty=&encoded%2Fkey=value%2Bplus&flag',
          ),
          onRequest: (nativeRequest) async {
            final request = _buildRequest(nativeRequest);
            return await request.body();
          },
        );

        expect(body, {
          'name': 'hello world',
          'empty': '',
          'encoded/key': 'value+plus',
          'flag': '',
        });
      },
    );

    test('parses multipart form-data fields and file uploads', () async {
      const boundary = 'test-boundary';
      final multipartBody = [
        '--$boundary\r\n'
            'Content-Disposition: form-data; name="title"\r\n\r\n'
            'My upload\r\n',
        '--$boundary\r\n'
            'Content-Disposition: form-data; name="file"; filename="hello.txt"\r\n'
            'Content-Type: text/plain\r\n\r\n'
            'ABC\r\n',
        '--$boundary--\r\n',
      ].join();

      final body = await _withNativeRequest<Map<String, dynamic>?>(
        method: 'POST',
        contentTypeHeader: 'multipart/form-data; boundary=$boundary',
        bodyBytes: convert.utf8.encode(multipartBody),
        onRequest: (nativeRequest) async {
          final request = _buildRequest(nativeRequest);
          return await request.body();
        },
      );

      expect(body, isNotNull);
      expect(body!['title'], 'My upload');
      expect(body['file'], isA<MultipartFileUpload>());

      final file = body['file']! as MultipartFileUpload;
      expect(file.name, 'hello.txt');
      expect(file.mime, 'text/plain');
      expect(file.bytes, convert.utf8.encode('ABC'));
    });

    test('parses text for text/plain', () async {
      final body = await _withNativeRequest<String?>(
        method: 'POST',
        contentTypeHeader: 'text/plain',
        bodyBytes: convert.utf8.encode('hello'),
        onRequest: (nativeRequest) async {
          final request = _buildRequest(nativeRequest);
          return await request.body();
        },
      );

      expect(body, 'hello');
    });

    test(
      'returns null for multipart/form-data when boundary is missing',
      () async {
        final body = await _withNativeRequest<Map<String, dynamic>?>(
          method: 'POST',
          contentTypeHeader: 'multipart/form-data',
          bodyBytes: convert.utf8.encode('field=value'),
          onRequest: (nativeRequest) async {
            final request = _buildRequest(nativeRequest);
            return await request.body();
          },
        );

        expect(body, isNull);
      },
    );

    test('returns null for unsupported content type', () async {
      final body = await _withNativeRequest<Map<String, dynamic>?>(
        method: 'POST',
        contentTypeHeader: 'unsupported-body',
        bodyBytes: null,
        onRequest: (nativeRequest) async {
          final request = _buildRequest(nativeRequest);
          return await request.body();
        },
      );

      expect(body, isNull);
    });
  });

  group('Request cookie helpers', () {
    test(
      'getCookie returns cookie value when cookie exists and is not expired',
      () {
        final nativeRequest = _MockHttpRequest();
        when(() => nativeRequest.cookies).thenReturn([
          Cookie('session', 'abc123')
            ..expires = DateTime.now().add(Duration(minutes: 30)),
        ]);

        final request = _buildRequest(nativeRequest);

        expect(request.getCookie('session'), 'abc123');
      },
    );

    test('getCookie returns null when cookie is missing or expired', () {
      final nativeRequest = _MockHttpRequest();
      when(() => nativeRequest.cookies).thenReturn([
        Cookie('session', 'abc123')
          ..expires = DateTime.now().subtract(Duration(minutes: 1)),
      ]);

      final request = _buildRequest(nativeRequest);

      expect(request.getCookie('missing'), isNull);
      expect(request.getCookie('session'), isNull);
    });

    test(
      'getSignedCookie throws when signed cookie parser is not set',
      () async {
        final nativeRequest = _MockHttpRequest();
        when(() => nativeRequest.cookies).thenReturn([Cookie('token', 'raw')]);

        final request = _buildRequest(nativeRequest);

        await expectLater(
          request.getSignedCookie('token'),
          throwsA(isA<LunartException>()),
        );
      },
    );

    test('getSignedCookie returns decoded parsed value', () async {
      final nativeRequest = _MockHttpRequest();
      when(() => nativeRequest.cookies).thenReturn([
        Cookie('token', 'raw-token'),
      ]);

      final request = _buildRequest(nativeRequest);
      request.signedCookieParser = (cookie, {maxAge}) async =>
          'hello%20world%2Ftoken';

      final cookieValue = await request.getSignedCookie('token');

      expect(cookieValue, 'hello world/token');
    });

    test('getSignedCookie returns null when cookie is missing or parser returns null', () async {
      final nativeRequest = _MockHttpRequest();
      when(() => nativeRequest.cookies).thenReturn([
        Cookie('token', 'raw-token'),
      ]);

      final request = _buildRequest(nativeRequest);
      request.signedCookieParser = (cookie, {maxAge}) async => null;

      final missingCookieValue = await request.getSignedCookie('missing');
      final parsedNullValue = await request.getSignedCookie('token');

      expect(missingCookieValue, isNull);
      expect(parsedNullValue, isNull);
    });
  });
}
