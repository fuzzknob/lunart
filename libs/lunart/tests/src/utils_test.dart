import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:lunart/src/utils.dart';
import 'package:lunart/src/enums/method.dart';
import 'package:lunart/src/request.dart';

class _MockFile extends Mock implements File {}

class _MockHttpRequest extends Mock implements HttpRequest {}

Request _buildRequest() {
  return Request(
    nativeRequest: _MockHttpRequest(),
    path: '/',
    method: Method.get,
    headers: {},
    queries: {},
  );
}

void main() {
  group('getMimeType', () {
    test('returns mime type from file extension when available', () async {
      final file = _MockFile();
      when(() => file.path).thenReturn('/tmp/file.json');

      final mimeType = await getMimeType(file);

      expect(mimeType, 'application/json');
      verifyNever(() => file.openRead(any(), any()));
    });

    test('reads header bytes when extension is unknown', () async {
      final file = _MockFile();
      when(() => file.path).thenReturn('/tmp/file.unknown');
      when(() => file.openRead(0, 2))
          .thenAnswer((_) => Stream<List<int>>.value(<int>[0x42, 0x4D]));

      final mimeType = await getMimeType(file);

      expect(mimeType, isNull);
      verify(() => file.openRead(0, 2)).called(1);
    });

    test('returns null when mime type cannot be determined', () async {
      final file = _MockFile();
      when(() => file.path).thenReturn('/tmp/file.unknown');
      when(() => file.openRead(0, 2))
          .thenAnswer((_) => Stream<List<int>>.value(<int>[]));

      final mimeType = await getMimeType(file);

      expect(mimeType, isNull);
      verify(() => file.openRead(0, 2)).called(1);
    });
  });

  group('isHtml', () {
    test('returns true for standard HTML tags', () {
      expect(isHtml('<div>Hello</div>'), isTrue);
    });

    test('returns true for uppercase tag names', () {
      expect(isHtml('<SPAN>Text</SPAN>'), isTrue);
    });

    test('returns true for self-closing style tags', () {
      expect(isHtml('<br/>'), isTrue);
    });

    test('returns false for plain text', () {
      expect(isHtml('just text'), isFalse);
    });

    test('returns false when angle brackets are not HTML tags', () {
      expect(isHtml('1 < 2 and 3 > 1'), isFalse);
    });

    test('returns false for incomplete tag without closing bracket', () {
      expect(isHtml('<div'), isFalse);
    });
  });

  group('invokeHandler', () {
    test('calls handler directly when middleware list is empty', () async {
      final request = _buildRequest();
      var wasHandlerCalled = false;

      final result = await invokeHandler(
        request: request,
        middlewares: [],
        handler: (_) {
          wasHandlerCalled = true;
          return 'ok';
        },
      );

      expect(wasHandlerCalled, isTrue);
      expect(result, 'ok');
    });

    test('executes middlewares in order, then handler', () async {
      final request = _buildRequest();
      final calls = <String>[];

      await invokeHandler(
        request: request,
        middlewares: [
          (_, next) async {
            calls.add('middleware-1');
            return await next();
          },
          (_, next) async {
            calls.add('middleware-2');
            return await next();
          },
        ],
        handler: (_) {
          calls.add('handler');
          return null;
        },
      );

      expect(calls, ['middleware-1', 'middleware-2', 'handler']);
    });

    test('supports middleware around behavior with await next', () async {
      final request = _buildRequest();
      final calls = <String>[];

      await invokeHandler(
        request: request,
        middlewares: [
          (_, next) async {
            calls.add('m1-before');
            final value = await next();
            calls.add('m1-after');
            return value;
          },
          (_, next) async {
            calls.add('m2-before');
            final value = await next();
            calls.add('m2-after');
            return value;
          },
        ],
        handler: (_) {
          calls.add('handler');
          return 'done';
        },
      );

      expect(calls, [
        'm1-before',
        'm2-before',
        'handler',
        'm2-after',
        'm1-after',
      ]);
    });

    test('short-circuits when middleware does not call next', () async {
      final request = _buildRequest();
      final calls = <String>[];

      final result = await invokeHandler(
        request: request,
        middlewares: [
          (_, _) {
            calls.add('middleware-1');
            return 'blocked';
          },
          (_, next) async {
            calls.add('middleware-2');
            return await next();
          },
        ],
        handler: (_) {
          calls.add('handler');
          return 'handler';
        },
      );

      expect(calls, ['middleware-1']);
      expect(result, 'blocked');
    });

    test(
      'returns value produced by handler through middleware chain',
      () async {
        final request = _buildRequest();

        final result = await invokeHandler(
          request: request,
          middlewares: [
            (_, next) async {
              return await next();
            },
          ],
          handler: (_) => 42,
        );

        expect(result, 42);
      },
    );

    test('supports async middleware and async handler', () async {
      final request = _buildRequest();

      final result = await invokeHandler(
        request: request,
        middlewares: [
          (_, next) async {
            await Future<void>.delayed(Duration(milliseconds: 1));
            return await next();
          },
        ],
        handler: (_) async {
          await Future<void>.delayed(Duration(milliseconds: 1));
          return 'async-result';
        },
      );

      expect(result, 'async-result');
    });

    test('propagates errors thrown by handler', () async {
      final request = _buildRequest();

      expect(
        () => invokeHandler(
          request: request,
          middlewares: [
            (_, next) async => await next(),
          ],
          handler: (_) => throw StateError('handler failed'),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('propagates errors thrown by middleware', () async {
      final request = _buildRequest();

      expect(
        () => invokeHandler(
          request: request,
          middlewares: [
            (_, __) => throw ArgumentError('middleware failed'),
          ],
          handler: (_) => 'ok',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
