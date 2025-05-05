import 'package:mocktail/mocktail.dart';

import 'package:test/test.dart';
import 'package:lucore/lucore.dart';
import 'package:lucore/src/utils.dart';

class MockRequest extends Mock implements Request {}

void main() {
  group('invokeHandler', () {
    test('invokes a single middleware and handler', () async {
      final request = MockRequest();

      final invokeOrder = <String>[];

      FutureOr<Response> middleware(Request req, Next next) {
        invokeOrder.add('middleware');
        return next();
      }

      Response handler(Request req) {
        invokeOrder.add('handler');
        return res.text('passed');
      }

      final result = await invokeHandler(
        request: request,
        middlewares: [middleware],
        handler: handler,
      );

      expect(result.statusCode, equals(200));
      expect(result.body, equals('passed'));
      expect(invokeOrder, equals(['middleware', 'handler']));
    });

    test('invokes multiple middleware in order', () async {
      final request = MockRequest();

      final invokeOrder = <String>[];

      FutureOr<Response> middleware1(Request req, Next next) async {
        invokeOrder.add('middleware1-start');
        final response = await next();
        invokeOrder.add('middleware1-end');
        return response;
      }

      FutureOr<Response> middleware2(Request req, Next next) async {
        invokeOrder.add('middleware2-start');
        final response = await next();
        invokeOrder.add('middleware2-end');
        return response;
      }

      FutureOr<Response> middleware3(Request req, Next next) async {
        invokeOrder.add('middleware3-start');
        final response = await next();
        invokeOrder.add('middleware3-end');
        return response;
      }

      Response handler(Request req) {
        invokeOrder.add('handler');
        return res.text('passed');
      }

      final result = await invokeHandler(
        request: request,
        middlewares: [middleware1, middleware2, middleware3],
        handler: handler,
      );

      expect(
        invokeOrder,
        equals([
          'middleware1-start',
          'middleware2-start',
          'middleware3-start',
          'handler',
          'middleware3-end',
          'middleware2-end',
          'middleware1-end',
        ]),
      );
      expect(result.body, equals('passed'));
    });

    test('invokes handler without any middlwares', () async {
      var isHandlerInvoked = false;

      Response handler(Request req) {
        isHandlerInvoked = true;
        return res.text('passed');
      }

      final request = MockRequest();

      final result = await invokeHandler(
        request: request,
        middlewares: [],
        handler: handler,
      );

      expect(isHandlerInvoked, isTrue);
      expect(result.body, equals('passed'));
    });

    test('middleware can throw error and break chain', () async {
      final request = MockRequest();
      final invokeOrder = <String>[];

      FutureOr<Response> middleware1(Request req, Next next) async {
        invokeOrder.add('middleware1-start');
        final response = await next();
        invokeOrder.add('middleware1-end');
        return response;
      }

      FutureOr<Response> middleware2(Request req, Next next) async {
        invokeOrder.add('middleware2-start');

        throw Exception('middleware 2 error');
      }

      FutureOr<Response> middleware3(Request req, Next next) async {
        invokeOrder.add('middleware3-start');
        final response = await next();
        invokeOrder.add('middleware3-end');
        return response;
      }

      Response handler(Request req) {
        invokeOrder.add('handler');
        return res.text('passed');
      }

      var hasThrown = false;

      try {
        await invokeHandler(
          request: request,
          middlewares: [middleware1, middleware2, middleware3],
          handler: handler,
        );
      } catch (_) {
        hasThrown = true;
      }

      expect(hasThrown, isTrue);
      expect(invokeOrder, ['middleware1-start', 'middleware2-start']);
    });

    test('middleware can return response and break chain', () async {
      final request = MockRequest();
      final invokeOrder = <String>[];

      FutureOr<Response> middleware1(Request req, Next next) async {
        invokeOrder.add('middleware1-start');
        final response = await next();
        invokeOrder.add('middleware1-end');
        return response;
      }

      FutureOr<Response> middleware2(Request req, Next next) async {
        invokeOrder.add('middleware2-start');

        // breaks the chain
        return res.text('from-middleware2');
      }

      FutureOr<Response> middleware3(Request req, Next next) async {
        invokeOrder.add('middleware3-start');

        final response = await next();

        invokeOrder.add('middleware3-end');
        return response;
      }

      Response handler(Request req) {
        invokeOrder.add('handler');
        return res.text('passed');
      }

      final result = await invokeHandler(
        request: request,
        middlewares: [middleware1, middleware2, middleware3],
        handler: handler,
      );

      expect(
        invokeOrder,
        equals(['middleware1-start', 'middleware2-start', 'middleware1-end']),
      );
      expect(result.body, equals('from-middleware2'));
    });
  });
}
