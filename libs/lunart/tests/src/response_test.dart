import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:lunart/src/response.dart';

class _MockFile extends Mock implements File {}

void main() {
  group('Response core behavior', () {
    test('status sets status code and returns same instance', () {
      final response = Response();

      final returned = response.status(HttpStatus.accepted);

      expect(identical(returned, response), isTrue);

      expect(response.statusCode, HttpStatus.accepted);
    });

    test('header sets header value', () {
      final response = Response();

      response.header('x-test', 'value');

      expect(response.headers['x-test'], 'value');
    });

    test('addHeaders merges with existing headers and allows override', () {
      final response = Response();
      response.header('x-first', 1);
      response.header('x-override', 'before');

      response.addHeaders({'x-second': true, 'x-override': 'after'});

      expect(response.headers, {
        'x-first': 1,
        'x-override': 'after',
        'x-second': true,
      });
    });

    test(
      'setBody updates body without enabling auto resolve response type',
      () {
        final response = Response();

        response.setBody({'value': 1});

        expect(response.body, {'value': 1});
        expect(response.autoResolveResponseType, isFalse);
      },
    );
  });

  group('Response body helpers', () {
    test('any sets body and enables auto resolve response type', () {
      final response = Response();

      final returned = response.any({'name': 'lunart'});

      expect(identical(returned, response), isTrue);
      expect(response.body, {'name': 'lunart'});
      expect(response.autoResolveResponseType, isTrue);
    });

    test('any returns provided Response when body is a Response', () {
      final outer = Response();
      final inner = Response().text('inner');

      final returned = outer.any(inner);

      expect(identical(returned, inner), isTrue);
      expect(outer.body, '');
      expect(outer.autoResolveResponseType, isFalse);
    });

    test('json encodes body and sets content type', () {
      final response = Response();

      response.json({'name': 'lunart', 'version': 1});

      expect(
        response.body,
        convert.json.encode({'name': 'lunart', 'version': 1}),
      );
      expect(
        response.headers['content-type'],
        'application/json; charset=utf-8',
      );
    });

    test('message writes json body with message property', () {
      final response = Response();

      response.message('created');

      expect(response.body, convert.json.encode({'message': 'created'}));
      expect(
        response.headers['content-type'],
        'application/json; charset=utf-8',
      );
    });

    test('html sets body and html content type', () {
      final response = Response();

      response.html('<h1>ok</h1>');

      expect(response.body, '<h1>ok</h1>');
      expect(response.headers['content-type'], 'text/html; charset=utf-8');
    });

    test('text sets body and plain text content type', () {
      final response = Response();

      response.text('plain');

      expect(response.body, 'plain');
      expect(response.headers['content-type'], 'text/plain; charset=utf-8');
    });

    test('stream sets response body to stream instance', () {
      final response = Response();
      final stream = Stream<int>.fromIterable([1, 2, 3]);

      response.stream(stream);

      expect(identical(response.body, stream), isTrue);
    });
  });

  group('Response redirect and statuses', () {
    test('redirect sets default found status and location header', () {
      final response = Response();

      response.redirect('/login');

      expect(response.statusCode, HttpStatus.found);
      expect(response.headers['Location'], '/login');
    });

    test('redirect uses provided status code', () {
      final response = Response();

      response.redirect('/created', HttpStatus.movedPermanently);

      expect(response.statusCode, HttpStatus.movedPermanently);
      expect(response.headers['Location'], '/created');
    });

    test('status helper methods map to expected status codes', () {
      final response = Response();

      response.notFound();
      expect(response.statusCode, HttpStatus.notFound);

      response.ok();
      expect(response.statusCode, HttpStatus.ok);

      response.created();
      expect(response.statusCode, HttpStatus.ok);

      response.internalServerError();
      expect(response.statusCode, HttpStatus.internalServerError);

      response.forbidden();
      expect(response.statusCode, HttpStatus.forbidden);

      response.unauthorized();
      expect(response.statusCode, HttpStatus.unauthorized);

      response.badRequest();
      expect(response.statusCode, HttpStatus.badRequest);

      response.noContent();
      expect(response.statusCode, HttpStatus.noContent);
    });
  });

  group('Response cookie helpers', () {
    test('cookie adds cookie with default options', () {
      final response = Response();

      response.cookie('session id', 'abc 123');

      expect(response.cookies, hasLength(1));

      final cookie = response.cookies.first;

      expect(cookie.name, Uri.encodeQueryComponent('session id'));
      expect(cookie.value, Uri.encodeQueryComponent('abc 123'));
      expect(cookie.httpOnly, isTrue);
      expect(cookie.secure, isTrue);
      expect(cookie.path, '/');
      expect(cookie.signed, isFalse);
    });

    test('cookie applies provided options', () {
      final response = Response();
      final expires = DateTime.utc(2030, 1, 1);
      final maxAge = Duration(hours: 1);

      response.cookie(
        'token',
        'value',
        httpOnly: false,
        secure: false,
        path: '/api',
        domain: 'example.com',
        expires: expires,
        maxAge: maxAge,
        sameSite: SameSite.strict,
      );

      final cookie = response.cookies.first;

      expect(cookie.httpOnly, isFalse);
      expect(cookie.secure, isFalse);
      expect(cookie.path, '/api');
      expect(cookie.domain, 'example.com');
      expect(cookie.expires, expires);
      expect(cookie.maxAge, maxAge);
      expect(cookie.sameSite, SameSite.strict);
    });

    test('signedCookie adds cookie with signed flag enabled', () {
      final response = Response();

      response.signedCookie('auth', 'secret');

      expect(response.cookies, hasLength(1));

      final cookie = response.cookies.first;

      expect(cookie.name, Uri.encodeQueryComponent('auth'));
      expect(cookie.value, Uri.encodeQueryComponent('secret'));
      expect(cookie.signed, isTrue);
    });

    test('removeCookie adds cookie with zero maxAge and empty value', () {
      final response = Response();

      response.removeCookie('session');

      expect(response.cookies, hasLength(1));

      final cookie = response.cookies.first;

      expect(cookie.name, Uri.encodeQueryComponent('session'));
      expect(cookie.value, Uri.encodeQueryComponent(''));
      expect(cookie.maxAge, Duration(seconds: 0));
    });
  });

  group('Response file and mergeResponse', () {
    test(
      'file sets mime type from extension and body to file stream',
      () async {
        final response = Response();
        final file = _MockFile();

        when(() => file.path).thenReturn('/tmp/data.json');

        when(() => file.openRead()).thenAnswer(
          (_) => Stream<List<int>>.fromIterable([
            convert.utf8.encode('{"ok":true}'),
          ]),
        );

        final returned = await response.file(file);

        expect(identical(returned, response), isTrue);
        expect(response.headers['Content-Type'], 'application/json');
        expect(response.body, isA<Stream>());
        verifyNever(() => file.openRead(0, 2));
        verify(() => file.openRead()).called(1);
      },
    );

    test(
      'file falls back to octet-stream when mime type cannot be determined',
      () async {
        final response = Response();
        final file = _MockFile();

        when(() => file.path).thenReturn('/tmp/data.unknown');
        when(() => file.openRead(0, 2)).thenAnswer(
          (_) => Stream<List<int>>.value(<int>[]),
        );
        when(() => file.openRead()).thenAnswer(
          (_) => Stream<List<int>>.fromIterable([
            <int>[1, 2, 3],
          ]),
        );

        await response.file(file);

        expect(response.headers['Content-Type'], 'application/octet-stream');
        expect(response.body, isA<Stream>());
        verify(() => file.openRead(0, 2)).called(1);
        verify(() => file.openRead()).called(1);
      },
    );

    test('mergeResponse merges state from other response', () async {
      final current = Res.status(HttpStatus.accepted)
          .header('x-shared', 'old')
          .header('x-only-current', 1)
          .cookie('a', '1')
          .any('current');

      final otherStream = Stream<int>.fromIterable([9, 8]);
      final other =
          Res.status(HttpStatus.noContent)
              .header('x-shared', 'new')
              .header('x-only-other', true)
              .cookie('b', '2')
              .stream(otherStream)
            ..autoResolveResponseType = false;

      final returned = current.mergeResponse(other);

      expect(identical(returned, current), isTrue);
      expect(current.statusCode, HttpStatus.noContent);
      expect(identical(current.body, otherStream), isTrue);
      expect(current.headers, {
        'x-shared': 'new',
        'x-only-current': 1,
        'x-only-other': true,
      });
      expect(current.cookies, hasLength(2));
      expect(current.cookies.map((cookie) => cookie.name), [
        Uri.encodeQueryComponent('a'),
        Uri.encodeQueryComponent('b'),
      ]);
      expect(current.autoResolveResponseType, isFalse);
    });
  });

  group('Res convenience getter', () {
    test('returns a new Response instance on each access', () {
      final first = Res;
      final second = Res;

      expect(first, isA<Response>());
      expect(second, isA<Response>());
      expect(identical(first, second), isFalse);
    });
  });
}
