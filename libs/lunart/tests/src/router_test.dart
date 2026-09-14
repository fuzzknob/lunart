import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:lunart/src/enums/method.dart';
import 'package:lunart/src/exceptions/not_found_exception.dart';
import 'package:lunart/src/request.dart';
import 'package:lunart/src/router.dart';

class _MockHttpRequest extends Mock implements HttpRequest {}

Request _buildRequest({required String path, required Method method}) {
  return Request(
    nativeRequest: _MockHttpRequest(),
    path: path,
    method: method,
    headers: {},
    queries: {},
  );
}

void main() {
  group('Router route registration', () {
    test('add registers route and handleRequest invokes handler', () async {
      final router = Router();
      router.add('/users', Method.get, (_) => 'ok');

      final result = await router.handleRequest(
        _buildRequest(path: '/users', method: Method.get),
      );

      expect(result, 'ok');
    });

    test(
      'verb helpers register and resolve handlers for their methods',
      () async {
        final router = Router()
          ..get('/g', (_) => 'get')
          ..post('/p', (_) => 'post')
          ..put('/u', (_) => 'put')
          ..patch('/pa', (_) => 'patch')
          ..delete('/d', (_) => 'delete');

        expect(
          await router.handleRequest(
            _buildRequest(path: '/g', method: Method.get),
          ),
          'get',
        );
        expect(
          await router.handleRequest(
            _buildRequest(path: '/p', method: Method.post),
          ),
          'post',
        );
        expect(
          await router.handleRequest(
            _buildRequest(path: '/u', method: Method.put),
          ),
          'put',
        );
        expect(
          await router.handleRequest(
            _buildRequest(path: '/pa', method: Method.patch),
          ),
          'patch',
        );
        expect(
          await router.handleRequest(
            _buildRequest(path: '/d', method: Method.delete),
          ),
          'delete',
        );
      },
    );

    test(
      'global middlewares run before route middlewares then handler',
      () async {
        final calls = <String>[];
        final router = Router(
          middlewares: [
            (_, next) async {
              calls.add('global-before');
              final value = await next();
              calls.add('global-after');
              return value;
            },
          ],
        );

        router.get(
          '/mw',
          (_) {
            calls.add('handler');
            return 'done';
          },
          middlewares: [
            (_, next) async {
              calls.add('route-before');
              final value = await next();
              calls.add('route-after');
              return value;
            },
          ],
        );

        final result = await router.handleRequest(
          _buildRequest(path: '/mw', method: Method.get),
        );

        expect(result, 'done');
        expect(calls, [
          'global-before',
          'route-before',
          'handler',
          'route-after',
          'global-after',
        ]);
      },
    );
  });

  group('Router prefix, nest, merge, and group', () {
    test('constructor prefix is normalized for both prefixed and non-prefixed input', () async {
      final routerA = Router(prefix: 'api')..get('/users', (_) => 'a');
      final routerB = Router(prefix: '/api')..get('/users', (_) => 'b');

      final resultA = await routerA.handleRequest(
        _buildRequest(path: '/api/users', method: Method.get),
      );
      final resultB = await routerB.handleRequest(
        _buildRequest(path: '/api/users', method: Method.get),
      );

      expect(resultA, 'a');
      expect(resultB, 'b');
    });

    test('root route with prefix is registered under /prefix', () async {
      final router = Router(prefix: 'api')..get('/', (_) => 'root');

      final result = await router.handleRequest(
        _buildRequest(path: '/api', method: Method.get),
      );

      expect(result, 'root');
    });

    test('Router.nest creates prefixed router', () async {
      final router = Router.nest('/v1')..get('/status', (_) => 'ok');

      final result = await router.handleRequest(
        _buildRequest(path: '/v1/status', method: Method.get),
      );

      expect(result, 'ok');
    });

    test('merge applies parent prefix to merged child routes', () async {
      final parent = Router(prefix: 'v1');
      final child = Router(prefix: 'admin')
        ..get('/users', (_) => 'child-users');

      parent.mount(child);

      final result = await parent.handleRequest(
        _buildRequest(path: '/v1/admin/users', method: Method.get),
      );

      expect(result, 'child-users');
    });

    test('group builds and merges child routes into parent', () async {
      final router = Router(prefix: 'v1');

      router.group((groupRouter) {
        groupRouter.get('/health', (_) => 'healthy');
      }, prefix: 'system');

      final result = await router.handleRequest(
        _buildRequest(path: '/v1/system/health', method: Method.get),
      );

      expect(result, 'healthy');
    });
  });

  group('Router request matching and not found behavior', () {
    test('resolves dynamic path parameters into request.parameters', () async {
      final router = Router()..get('/users/:id', (_) => 'ok');
      final request = _buildRequest(path: '/users/42', method: Method.get);

      final result = await router.handleRequest(request);

      expect(result, 'ok');
      expect(request.parameters, {'id': '42'});
    });

    test('matches dynamic route when path includes query string', () async {
      final router = Router()..get('/users/:id', (_) => 'ok');
      final request = _buildRequest(
        path: '/users/42?expand=true',
        method: Method.get,
      );

      final result = await router.handleRequest(request);

      expect(result, 'ok');
      expect(request.parameters, {'id': '42'});
    });

    test(
      'prefers exact route over dynamic fallback for same path shape',
      () async {
        final router = Router()
          ..get('/users/:id', (_) => 'dynamic')
          ..get('/users/me', (_) => 'exact');

        final result = await router.handleRequest(
          _buildRequest(path: '/users/me', method: Method.get),
        );

        expect(result, 'exact');
      },
    );

    test('throws NotFoundException for unknown path', () async {
      final router = Router()..get('/known', (_) => 'ok');

      await expectLater(
        () => router.handleRequest(
          _buildRequest(path: '/unknown', method: Method.get),
        ),
        throwsA(isA<NotFoundException>()),
      );
    });

    test(
      'throws NotFoundException when method does not match exact route',
      () async {
        final router = Router()..get('/users', (_) => 'ok');

        await expectLater(
          () => router.handleRequest(
            _buildRequest(path: '/users', method: Method.post),
          ),
          throwsA(isA<NotFoundException>()),
        );
      },
    );

    test('throws NotFoundException when dynamic path matches but method is missing', () async {
      final router = Router()..get('/users/:id', (_) => 'ok');
      final request = _buildRequest(path: '/users/88', method: Method.delete);

      await expectLater(
        () => router.handleRequest(request),
        throwsA(isA<NotFoundException>()),
      );
      expect(request.parameters, {'id': '88'});
    });
  });
}
