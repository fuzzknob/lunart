import 'dart:async';
import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:lunart/src/enums/method.dart';
import 'package:lunart/src/exceptions/exception.dart';
import 'package:lunart/src/middlewares/request_logger.dart';
import 'package:lunart/src/request.dart';
import 'package:lunart/src/response.dart';

class _MockHttpRequest extends Mock implements HttpRequest {}

Request _buildRequest() {
  return Request(
    nativeRequest: _MockHttpRequest(),
    path: '/users',
    method: Method.get,
    headers: const {},
    queries: const {},
  );
}

Future<List<String>> _capturePrints(Future<void> Function() action) async {
  final logs = <String>[];

  await runZoned(
    () async => await action(),
    zoneSpecification: ZoneSpecification(
      print: (_, _, _, String message) {
        logs.add(message);
      },
    ),
  );

  return logs;
}

void main() {
  group('requestLogger', () {
    test('returns next result unchanged', () async {
      final request = _buildRequest();

      final result = await requestLogger(request, () => 'ok');

      expect(result, 'ok');
    });

    test(
      'logs success with default status 200 for non-response values',
      () async {
        final request = _buildRequest();

        final logs = await _capturePrints(() async {
          await requestLogger(request, () => 'ok');
        });

        expect(logs, hasLength(1));
        expect(logs.first, contains('[LOG]'));
        expect(logs.first, contains('[GET]'));
        expect(logs.first, contains('/users'));
        expect(logs.first, contains(' 200 '));
        expect(logs.first, contains('took '));
        expect(logs.first, contains('ms'));
      },
    );

    test('logs success with status from Response', () async {
      final request = _buildRequest();

      final logs = await _capturePrints(() async {
        await requestLogger(
          request,
          () => Res.status(HttpStatus.created),
        );
      });

      expect(logs, hasLength(1));
      expect(logs.first, contains('[LOG]'));
      expect(logs.first, contains(' 201 '));
    });

    test('logs error style when response status is 500', () async {
      final request = _buildRequest();

      final logs = await _capturePrints(() async {
        await requestLogger(
          request,
          () => Res.status(HttpStatus.internalServerError),
        );
      });

      expect(logs, hasLength(1));
      expect(logs.first, contains('[ERROR]'));
      expect(logs.first, contains(' 500 '));
    });

    test('rethrows LunartException and logs status code', () async {
      final request = _buildRequest();
      final logs = <String>[];

      await expectLater(
        () => runZoned(
          () async {
            await requestLogger(
              request,
              () => throw const LunartException(
                statusCode: HttpStatus.notFound,
                message: 'not found',
                log: false,
              ),
            );
          },
          zoneSpecification: ZoneSpecification(
            print: (_, __, ___, String message) {
              logs.add(message);
            },
          ),
        ),
        throwsA(isA<LunartException>()),
      );

      expect(logs, hasLength(1));
      expect(logs.first, contains('[LOG]'));
      expect(logs.first, contains(' 404 '));
      expect(logs.first, contains('[GET]'));
      expect(logs.first, contains('/users'));
    });

    test(
      'rethrows generic exception and logs error message without status',
      () async {
        final request = _buildRequest();
        final logs = <String>[];

        await expectLater(
          () => runZoned(
            () async {
              await requestLogger(request, () => throw StateError('boom'));
            },
            zoneSpecification: ZoneSpecification(
              print: (_, __, ___, String message) {
                logs.add(message);
              },
            ),
          ),
          throwsA(isA<StateError>()),
        );

        expect(logs, hasLength(1));
        expect(logs.first, contains('[ERROR]'));
        expect(logs.first, contains('[GET]'));
        expect(logs.first, contains('/users'));
        expect(logs.first, contains('took '));
        expect(logs.first, contains('ms'));
        expect(logs.first.contains(' 500 '), isFalse);
      },
    );
  });
}
