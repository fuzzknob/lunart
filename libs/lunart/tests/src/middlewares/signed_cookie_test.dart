import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:lunart/src/enums/method.dart';
import 'package:lunart/src/middlewares/signed_cookie.dart';
import 'package:lunart/src/request.dart';
import 'package:lunart/src/response.dart';

class _MockHttpRequest extends Mock implements HttpRequest {}

Request _buildRequest() {
  return Request(
    nativeRequest: _MockHttpRequest(),
    path: '/resource',
    method: Method.get,
    headers: const {},
    queries: const {},
  );
}

void main() {
  group('signedCookie middleware', () {
    test('sets request signedCookieParser before calling next', () async {
      final middleware = signedCookie(secret: 'secret-key');
      final request = _buildRequest();
      var parserWasSetBeforeNext = false;

      await middleware(request, () {
        parserWasSetBeforeNext = request.signedCookieParser != null;
        return Res.text('ok');
      });

      expect(parserWasSetBeforeNext, isTrue);
    });

    test('seals signed cookies and marks hasSigned as true', () async {
      final middleware = signedCookie(secret: 'secret-key');
      final request = _buildRequest();
      final response = Res.signedCookie('token', 'raw-value');
      final originalValue = response.cookies.first.value;

      final result = await middleware(request, () => response);

      final transformed = result as Response;
      final cookie = transformed.cookies.first;

      expect(cookie.signed, isTrue);
      expect(cookie.hasSigned, isTrue);
      expect(cookie.value, isNot(originalValue));
    });

    test('does not seal non-signed cookies', () async {
      final middleware = signedCookie(secret: 'secret-key');
      final request = _buildRequest();
      final response = Res.cookie('plain', 'plain-value');
      final originalValue = response.cookies.first.value;

      final result = await middleware(request, () => response);

      final transformed = result as Response;
      final cookie = transformed.cookies.first;

      expect(cookie.signed, isFalse);
      expect(cookie.hasSigned, isFalse);
      expect(cookie.value, originalValue);
    });

    test('does not re-sign cookies already marked as hasSigned', () async {
      final middleware = signedCookie(secret: 'secret-key');
      final request = _buildRequest();
      final response = Res.signedCookie('token', 'raw-value');

      final cookie = response.cookies.first;
      cookie.value = 'already-sealed-value';
      cookie.hasSigned = true;

      final result = await middleware(request, () => response);

      final transformed = result as Response;
      final transformedCookie = transformed.cookies.first;

      expect(transformedCookie.value, 'already-sealed-value');
      expect(transformedCookie.hasSigned, isTrue);
    });

    test('seals only signed cookies when response has mixed cookies', () async {
      final middleware = signedCookie(secret: 'secret-key');
      final request = _buildRequest();
      final response = Res.cookie('plain', 'plain-value')
          .signedCookie('signed-one', 'first-value')
          .signedCookie('signed-two', 'second-value');

      final plainBefore = response.cookies[0].value;
      final signedOneBefore = response.cookies[1].value;
      final signedTwoBefore = response.cookies[2].value;

      final result = await middleware(request, () => response);

      final transformed = result as Response;
      final plainCookie = transformed.cookies[0];
      final signedOne = transformed.cookies[1];
      final signedTwo = transformed.cookies[2];

      expect(plainCookie.signed, isFalse);
      expect(plainCookie.value, plainBefore);

      expect(signedOne.signed, isTrue);
      expect(signedOne.hasSigned, isTrue);
      expect(signedOne.value, isNot(signedOneBefore));

      expect(signedTwo.signed, isTrue);
      expect(signedTwo.hasSigned, isTrue);
      expect(signedTwo.value, isNot(signedTwoBefore));
    });
  });
}
