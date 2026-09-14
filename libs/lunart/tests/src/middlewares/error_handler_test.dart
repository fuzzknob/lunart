import 'dart:convert' as convert;
import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:lunart/src/enums/method.dart';
import 'package:lunart/src/exceptions/exception.dart';
import 'package:lunart/src/middlewares/error_handler.dart';
import 'package:lunart/src/request.dart';
import 'package:lunart/src/response.dart';

class _MockHttpRequest extends Mock implements HttpRequest {}

Request _buildRequest({Map<String, String> headers = const {}}) {
  return Request(
    nativeRequest: _MockHttpRequest(),
    path: '/resource',
    method: Method.get,
    headers: headers,
    queries: const {},
  );
}

void main() {
  group('errorHandler', () {
    test('passes through value when next succeeds', () async {
      final request = _buildRequest();

      final result = await errorHandler(request, () => 'ok');

      expect(result, 'ok');
    });

    test('returns json response for LunartException when accept is application/json', () async {
      final request = _buildRequest(
        headers: const {
          'accept': 'application/json',
        },
      );

      final result = await errorHandler(
        request,
        () => throw const LunartException(
          statusCode: HttpStatus.badRequest,
          message: 'invalid input',
          log: false,
        ),
      );

      expect(result, isA<Response>());
      final response = result as Response;
      expect(response.statusCode, HttpStatus.badRequest);
      expect(
        response.headers['content-type'],
        'application/json; charset=utf-8',
      );
      expect(response.body, convert.json.encode({'message': 'invalid input'}));
    });

    test(
      'returns html response for LunartException when accept is text/html',
      () async {
        final request = _buildRequest(
          headers: const {
            'accept': 'text/html',
          },
        );

        final result = await errorHandler(
          request,
          () => throw const LunartException(
            statusCode: HttpStatus.forbidden,
            message: 'forbidden',
            log: false,
          ),
        );

        final response = result as Response;
        expect(response.statusCode, HttpStatus.forbidden);
        expect(response.headers['content-type'], 'text/html; charset=utf-8');
        expect(
          response.body,
          '<h3 style="font-family: sans-serif,serif;">forbidden</h3>',
        );
      },
    );

    test(
      'returns text response for LunartException when accept is missing',
      () async {
        final request = _buildRequest();

        final result = await errorHandler(
          request,
          () => throw const LunartException(
            statusCode: HttpStatus.unauthorized,
            message: 'unauthorized',
            log: false,
          ),
        );

        final response = result as Response;
        expect(response.statusCode, HttpStatus.unauthorized);
        expect(response.headers['content-type'], 'text/plain; charset=utf-8');
        expect(response.body, 'unauthorized');
      },
    );

    test(
      'uses fallback message when LunartException message is null',
      () async {
        final request = _buildRequest();

        final result = await errorHandler(
          request,
          () => throw const LunartException(
            statusCode: HttpStatus.unprocessableEntity,
            log: false,
          ),
        );

        final response = result as Response;
        expect(response.statusCode, HttpStatus.unprocessableEntity);
        expect(response.body, 'There was an 422 error!');
      },
    );

    test('returns 500 unknown error as negotiated json response', () async {
      final request = _buildRequest(
        headers: const {
          'accept': 'application/json',
        },
      );

      final result = await errorHandler(
        request,
        () => throw StateError('boom'),
        logError: false,
      );

      final response = result as Response;
      expect(response.statusCode, HttpStatus.internalServerError);
      expect(
        response.headers['content-type'],
        'application/json; charset=utf-8',
      );
      expect(
        response.body,
        convert.json.encode({'message': 'There was an unknown error'}),
      );
    });
  });
}
