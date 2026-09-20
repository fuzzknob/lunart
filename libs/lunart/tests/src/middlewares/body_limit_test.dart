import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:lunart/src/enums/method.dart';
import 'package:lunart/src/exceptions/content_too_large_exception.dart';
import 'package:lunart/src/libs/size.dart';
import 'package:lunart/src/middlewares/body_limit.dart';
import 'package:lunart/src/request.dart';

class _MockHttpRequest extends Mock implements HttpRequest {}

Request _buildRequest({required Map<String, String> headers}) {
  return Request(
    nativeRequest: _MockHttpRequest(),
    path: '/upload',
    method: Method.post,
    headers: headers,
    queries: const {},
  );
}

void main() {
  group('bodyLimit middleware', () {
    test('allows request when content-length is below default limit', () async {
      final middleware = bodyLimit();
      final request = _buildRequest(
        headers: const {'content-length': '1024'},
      );
      var wasNextCalled = false;

      final result = await middleware(request, () {
        wasNextCalled = true;
        return 'ok';
      });

      expect(wasNextCalled, isTrue);
      expect(result, 'ok');
    });

    test('allows request when content-length equals custom limit', () async {
      final middleware = bodyLimit(maxBytes: Size.fromBytes(100));
      final request = _buildRequest(
        headers: const {'content-length': '100'},
      );
      var wasNextCalled = false;

      final result = await middleware(request, () {
        wasNextCalled = true;
        return 'ok';
      });

      expect(wasNextCalled, isTrue);
      expect(result, 'ok');
    });

    test('throws ContentTooLargeException when above default limit', () async {
      final middleware = bodyLimit();
      final request = _buildRequest(
        headers: {'content-length': '${Size.fromMegabytes(50).bytes + 1}'},
      );

      await expectLater(
        () => middleware(request, () => 'ok'),
        throwsA(
          isA<ContentTooLargeException>().having(
            (e) => e.message,
            'message',
            contains('Request body exceeds maximum size'),
          ),
        ),
      );
    });

    test('throws ContentTooLargeException when above custom limit', () async {
      final middleware = bodyLimit(maxBytes: Size.fromKilobytes(1));
      final request = _buildRequest(
        headers: const {'content-length': '1025'},
      );

      await expectLater(
        () => middleware(request, () => 'ok'),
        throwsA(isA<ContentTooLargeException>()),
      );
    });
  });
}
