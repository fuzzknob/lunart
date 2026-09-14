import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:lunart/src/enums/method.dart';
import 'package:lunart/src/middlewares/cors.dart';
import 'package:lunart/src/request.dart';
import 'package:lunart/src/response.dart';

class _MockHttpRequest extends Mock implements HttpRequest {}

Request _buildRequest({
  required Method method,
  Map<String, String> headers = const {},
}) {
  return Request(
    nativeRequest: _MockHttpRequest(),
    path: '/resource',
    method: method,
    headers: headers,
    queries: const {},
  );
}

void main() {
  group('cors middleware non-preflight', () {
    test(
      'sets wildcard allow-origin and delegates to next by default',
      () async {
        final middleware = cors();
        final request = _buildRequest(method: Method.get);
        var wasNextCalled = false;

        final result = await middleware(request, () {
          wasNextCalled = true;
          return 'ok';
        });

        expect(wasNextCalled, isTrue);
        expect(result, isA<Response>());
        final response = result as Response;
        expect(response.body, 'ok');
        expect(response.headers['Access-Control-Allow-Origin'], '*');
      },
    );

    test(
      'echoes allowed origin and sets vary origin when origin is allowed',
      () async {
        final middleware = cors(origins: ['https://app.test']);
        final request = _buildRequest(
          method: Method.get,
          headers: const {
            'origin': 'https://app.test',
          },
        );

        final result = await middleware(request, () => 'ok');

        final response = result as Response;
        expect(
          response.headers['Access-Control-Allow-Origin'],
          'https://app.test',
        );
        expect(response.headers['Vary'], 'Origin');
      },
    );

    test('does not set allow-origin when origin is not allowed', () async {
      final middleware = cors(origins: ['https://app.test']);
      final request = _buildRequest(
        method: Method.get,
        headers: const {
          'origin': 'https://other.test',
        },
      );

      final result = await middleware(request, () => 'ok');

      final response = result as Response;
      expect(
        response.headers.containsKey('Access-Control-Allow-Origin'),
        isFalse,
      );
    });

    test('sets credentials and expose headers when configured', () async {
      final middleware = cors(
        credentials: true,
        exposeHeaders: ['x-trace', 'x-id'],
      );
      final request = _buildRequest(method: Method.get);

      final result = await middleware(request, () => 'ok');

      final response = result as Response;
      expect(response.headers['Access-Control-Allow-Credentials'], 'true');
      expect(response.headers['Access-Control-Expose-Headers'], 'x-trace,x-id');
    });
  });

  group('cors middleware preflight', () {
    test('returns 204 and does not call next for options requests', () async {
      final middleware = cors();
      final request = _buildRequest(method: Method.options);
      var wasNextCalled = false;

      final result = await middleware(request, () {
        wasNextCalled = true;
        return 'should-not-run';
      });

      expect(wasNextCalled, isFalse);
      expect(result, isA<Response>());
      final response = result as Response;
      expect(response.statusCode, HttpStatus.noContent);
    });

    test('sets max-age, explicit methods, and explicit headers', () async {
      final middleware = cors(
        maxAge: 7200,
        allowMethods: [Method.get, Method.post],
        allowHeaders: ['authorization', 'content-type'],
      );
      final request = _buildRequest(method: Method.options);

      final result = await middleware(request, () => 'ignored');

      final response = result as Response;
      expect(response.statusCode, HttpStatus.noContent);
      expect(response.headers['Access-Control-Max-Age'], '7200');
      expect(response.headers['Access-Control-Allow-Methods'], 'GET,POST');
      expect(
        response.headers['Access-Control-Allow-Headers'],
        'authorization,content-type',
      );
      expect(response.headers['Vary'], 'Access-Control-Request-Headers');
    });

    test('falls back to request access-control-request-headers', () async {
      final middleware = cors(
        allowHeaders: const [],
      );
      final request = _buildRequest(
        method: Method.options,
        headers: const {
          'access-control-request-headers': 'x-trace,authorization',
        },
      );

      final result = await middleware(request, () => 'ignored');

      final response = result as Response;
      expect(
        response.headers['Access-Control-Allow-Headers'],
        'x-trace,authorization',
      );
      expect(response.headers['Vary'], 'Access-Control-Request-Headers');
    });

    test('combines vary origin and access-control-request-headers', () async {
      final middleware = cors(
        origins: ['https://app.test'],
        allowHeaders: const [],
      );
      final request = _buildRequest(
        method: Method.options,
        headers: const {
          'origin': 'https://app.test',
          'access-control-request-headers': 'x-trace',
        },
      );

      final result = await middleware(request, () => 'ignored');

      final response = result as Response;
      expect(
        response.headers['Access-Control-Allow-Origin'],
        'https://app.test',
      );
      expect(response.headers['Vary'], 'Origin,Access-Control-Request-Headers');
    });
  });
}
