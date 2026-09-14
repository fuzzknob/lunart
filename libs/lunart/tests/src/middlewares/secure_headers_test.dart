import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:lunart/src/enums/method.dart';
import 'package:lunart/src/middlewares/secure_headers.dart';
import 'package:lunart/src/request.dart';
import 'package:lunart/src/response.dart';

class _MockHttpRequest extends Mock implements HttpRequest {}

Request _buildRequest({
  Map<String, String> headers = const {},
  HttpRequest? nativeRequest,
}) {
  return Request(
    nativeRequest: nativeRequest ?? _MockHttpRequest(),
    path: '/resource',
    method: Method.get,
    headers: headers,
    queries: const {},
  );
}

void main() {
  group('secureHeaders middleware', () {
    test(
      'adds default secure headers and preserves body for non-response values',
      () async {
        final middleware = secureHeaders();
        final request = _buildRequest();

        final result = await middleware(request, () => 'ok');

        expect(result, isA<Response>());
        final response = result as Response;
        expect(response.body, 'ok');
        expect(response.headers['X-Content-Type-Options'], 'nosniff');
        expect(
          response.headers['Content-Security-Policy'],
          "default-src 'self'; base-uri 'self'; frame-ancestors 'self'; object-src 'none'",
        );
        expect(response.headers['X-Frame-Options'], 'SAMEORIGIN');
        expect(response.headers['X-XSS-Protection'], '0');
        expect(
          response.headers['Referrer-Policy'],
          'strict-origin-when-cross-origin',
        );
        expect(response.headers['Cross-Origin-Opener-Policy'], 'same-origin');
        expect(response.headers['Cross-Origin-Resource-Policy'], 'same-origin');
        expect(response.headers['Origin-Agent-Cluster'], '?1');
        expect(response.headers['X-DNS-Prefetch-Control'], 'off');
        expect(response.headers['X-Permitted-Cross-Domain-Policies'], 'none');
        expect(response.headers['X-Download-Options'], 'noopen');
      },
    );

    test('does not set HSTS on non-secure request by default', () async {
      final middleware = secureHeaders();
      final request = _buildRequest();

      final result = await middleware(request, () => 'ok');

      final response = result as Response;
      expect(
        response.headers.containsKey('Strict-Transport-Security'),
        isFalse,
      );
    });

    test('sets HSTS when x-forwarded-proto is https', () async {
      final middleware = secureHeaders();
      final request = _buildRequest(
        headers: const {'x-forwarded-proto': 'https'},
      );

      final result = await middleware(request, () => 'ok');

      final response = result as Response;
      expect(
        response.headers['Strict-Transport-Security'],
        'max-age=31536000; includeSubDomains',
      );
    });

    test(
      'sets HSTS for non-secure request when secure-only check is disabled',
      () async {
        final middleware = secureHeaders(
          strictTransportSecurityOnlyWhenSecureRequest: false,
        );
        final request = _buildRequest();

        final result = await middleware(request, () => 'ok');

        final response = result as Response;
        expect(
          response.headers['Strict-Transport-Security'],
          'max-age=31536000; includeSubDomains',
        );
      },
    );

    test('composes custom HSTS value correctly', () async {
      final middleware = secureHeaders(
        strictTransportSecurityOnlyWhenSecureRequest: false,
        strictTransportSecurityMaxAge: 60,
        strictTransportSecurityIncludeSubDomains: false,
        strictTransportSecurityPreload: true,
      );
      final request = _buildRequest();

      final result = await middleware(request, () => 'ok');

      final response = result as Response;
      expect(
        response.headers['Strict-Transport-Security'],
        'max-age=60; preload',
      );
    });

    test('omits disabled or null-configured headers', () async {
      final middleware = secureHeaders(
        xContentTypeOptions: false,
        contentSecurityPolicy: null,
        xFrameOptions: null,
        xXssProtection: null,
        referrerPolicy: null,
        crossOriginOpenerPolicy: null,
        crossOriginResourcePolicy: null,
        originAgentCluster: null,
        xDnsPrefetchControl: null,
        xPermittedCrossDomainPolicies: null,
        xDownloadOptions: null,
      );
      final request = _buildRequest();

      final result = await middleware(request, () => 'ok');

      final response = result as Response;
      expect(response.headers.containsKey('X-Content-Type-Options'), isFalse);
      expect(response.headers.containsKey('Content-Security-Policy'), isFalse);
      expect(response.headers.containsKey('X-Frame-Options'), isFalse);
      expect(response.headers.containsKey('X-XSS-Protection'), isFalse);
      expect(response.headers.containsKey('Referrer-Policy'), isFalse);
      expect(
        response.headers.containsKey('Cross-Origin-Opener-Policy'),
        isFalse,
      );
      expect(
        response.headers.containsKey('Cross-Origin-Resource-Policy'),
        isFalse,
      );
      expect(response.headers.containsKey('Origin-Agent-Cluster'), isFalse);
      expect(response.headers.containsKey('X-DNS-Prefetch-Control'), isFalse);
      expect(
        response.headers.containsKey('X-Permitted-Cross-Domain-Policies'),
        isFalse,
      );
      expect(response.headers.containsKey('X-Download-Options'), isFalse);
    });

    test('adds COEP only when configured', () async {
      final defaultMiddleware = secureHeaders();
      final configuredMiddleware = secureHeaders(
        crossOriginEmbedderPolicy: 'require-corp',
      );
      final request = _buildRequest();

      final defaultResult = await defaultMiddleware(request, () => 'ok');
      final defaultResponse = defaultResult as Response;
      expect(
        defaultResponse.headers.containsKey('Cross-Origin-Embedder-Policy'),
        isFalse,
      );

      final configuredResult = await configuredMiddleware(request, () => 'ok');
      final configuredResponse = configuredResult as Response;
      expect(
        configuredResponse.headers['Cross-Origin-Embedder-Policy'],
        'require-corp',
      );
    });

    test('preserves existing response headers', () async {
      final middleware = secureHeaders();
      final request = _buildRequest();

      final result = await middleware(
        request,
        () => Res.header('x-trace', 'yes').status(HttpStatus.created),
      );

      final response = result as Response;
      expect(response.statusCode, HttpStatus.created);
      expect(response.headers['x-trace'], 'yes');
      expect(response.headers['X-Content-Type-Options'], 'nosniff');
    });
  });
}
