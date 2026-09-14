import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:lunart/src/enums/method.dart';
import 'package:lunart/src/interfaces/plugin.dart';
import 'package:lunart/src/lunart.dart';
import 'package:lunart/src/request.dart';
import 'package:lunart/src/response.dart';
import 'package:lunart/src/router.dart';

class _MockHttpRequest extends Mock implements HttpRequest {}

class _TrackingPlugin implements Plugin {
  var wasPlugCalled = false;

  @override
  void plug(Lunart app) {
    wasPlugCalled = true;
    app.use((request, next) => next());
  }
}

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
  group('Lunart plugin behavior', () {
    test('plug invokes plugin and returns same app instance', () {
      final app = Lunart(barebones: true);
      final plugin = _TrackingPlugin();

      app.plug(plugin);

      expect(plugin.wasPlugCalled, isTrue);
      expect(app.server.globalMiddlewares, hasLength(1));
    });
  });

  group('Lunart delegation helpers', () {
    test('use delegates to server', () {
      final app = Lunart(barebones: true);

      app.use((request, next) => next());

      expect(app.server.globalMiddlewares, hasLength(1));
    });

    test(
      'group delegates builder, prefix, and middlewares to router.group',
      () async {
        final app = Lunart(barebones: true);
        final calls = <String>[];

        final returned = app.group(
          (groupRouter) {
            groupRouter.get('/health', (_) {
              calls.add('handler');
              return 'ok';
            });
          },
          prefix: 'admin',
          middlewares: [
            (_, next) async {
              calls.add('group-middleware-before');
              final value = await next();
              calls.add('group-middleware-after');
              return value;
            },
          ],
        );

        final result = await app.router.handleRequest(
          _buildRequest(path: 'admin/health', method: Method.get),
        );

        expect(identical(returned, app), isTrue);
        expect(result, 'ok');
        expect(calls, [
          'group-middleware-before',
          'handler',
          'group-middleware-after',
        ]);
      },
    );

    test('addRouter merges external router routes', () async {
      final app = Lunart(barebones: true);
      final externalRouter = Router()..get('/external', (_) => 'ok');

      app.addRouter(externalRouter);

      final result = await app.router.handleRequest(
        _buildRequest(path: '/external', method: Method.get),
      );

      expect(result, 'ok');
    });

    test('registerResponseResolver registers custom resolver', () async {
      final app = Lunart(barebones: true)
        ..registerResponseResolver<int>(
          (value) => Res.status(HttpStatus.created).text('value:$value'),
        );

      final resolved = await app.server.resTypeResolver.resolve(7);

      expect(resolved.statusCode, HttpStatus.created);
      expect(resolved.body, 'value:7');
      expect(resolved.headers['content-type'], 'text/plain; charset=utf-8');
    });
  });

  group('Lunart route registration methods', () {
    test('add registers route for explicit method', () async {
      final app = Lunart(barebones: true)
        ..add('/users', Method.post, (_) => 'created');

      final result = await app.router.handleRequest(
        _buildRequest(path: '/users', method: Method.post),
      );

      expect(result, 'created');
    });

    test('get helper registers GET route', () async {
      final app = Lunart(barebones: true)..get('/g', (_) => 'get');

      final result = await app.router.handleRequest(
        _buildRequest(path: '/g', method: Method.get),
      );

      expect(result, 'get');
    });

    test('post helper registers POST route', () async {
      final app = Lunart(barebones: true)..post('/p', (_) => 'post');

      final result = await app.router.handleRequest(
        _buildRequest(path: '/p', method: Method.post),
      );

      expect(result, 'post');
    });

    test('put helper registers PUT route', () async {
      final app = Lunart(barebones: true)..put('/u', (_) => 'put');

      final result = await app.router.handleRequest(
        _buildRequest(path: '/u', method: Method.put),
      );

      expect(result, 'put');
    });

    test('patch helper registers PATCH route', () async {
      final app = Lunart(barebones: true)..patch('/pa', (_) => 'patch');

      final result = await app.router.handleRequest(
        _buildRequest(path: '/pa', method: Method.patch),
      );

      expect(result, 'patch');
    });

    test('delete helper registers DELETE route', () async {
      final app = Lunart(barebones: true)..delete('/d', (_) => 'delete');

      final result = await app.router.handleRequest(
        _buildRequest(path: '/d', method: Method.delete),
      );

      expect(result, 'delete');
    });
  });
}
