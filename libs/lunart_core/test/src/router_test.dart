import 'package:mocktail/mocktail.dart';

import 'package:lucore/lucore.dart';
import 'package:test/test.dart';

class MockRequest extends Mock implements Request {
  @override
  String path = '';

  @override
  Method method = Method.get;

  @override
  Map<String, dynamic> parameters = {};
}

void main() {
  group('router internals test', () {
    test('adds route to the route map', () {
      final router = Router();

      handler(Request req) => res;

      router.add('/test-route', Method.get, handler);

      expect(router.routesMap.length, 1);
      expect(router.routesMap.containsKey('GET@/test-route'), isTrue);

      final routerHandler = router.routesMap['GET@/test-route'];

      expect(routerHandler, isNotNull);
      expect(routerHandler?.path, '/test-route');
      expect(routerHandler?.handler, handler);
      expect(routerHandler?.method, Method.get);
    });

    test('adds route to the route path trie', () {
      final router = Router();

      handler(Request req) => res;

      router.add('/test-route', Method.get, handler);

      final pathResult = router.pathTrie.lookupPath('/test-route');

      expect(pathResult, isNotNull);
      expect(pathResult?.path, '/test-route');
    });

    test('builds correct path trie', () {
      final router = Router();

      router.get('/', (_) => res);
      router.get('/patha', (_) => res);
      router.get('/patha/subpath', (_) => res);
      router.get('/pathb/subpath', (_) => res);
      router.get('/pathc', (_) => res);
      router.get('/pathc/subpath/subsubpath', (_) => res);

      final trie = router.pathTrie.printTrie();

      expect([
        '/',
        '/patha',
        '/patha/subpath',
        '/pathb/subpath',
        '/pathc',
        '/pathc/subpath/subsubpath',
      ], trie);
    });
  });

  group('route match tests', () {
    Router? router;
    MockRequest? request;

    setUp(() {
      router = Router();
      request = MockRequest();
    });

    test('handles get request', () async {
      router?.get('/', (req) => res.text('test'));

      request?.path = '/';

      final response = await router?.handleRequest(request!);

      expect(response?.body, 'test');
    });

    test('handles post request', () async {
      router?.post('/', (req) => res.text('test'));

      request?.path = '/';

      request?.method = Method.post;

      final response = await router?.handleRequest(request!);

      expect(response?.body, 'test');
    });

    test('handles put request', () async {
      router?.put('/', (req) => res.text('test'));

      request?.path = '/';

      request?.method = Method.put;

      final response = await router?.handleRequest(request!);

      expect(response?.body, 'test');
    });

    test('handles patch request', () async {
      router?.patch('/', (req) => res.text('test'));

      request?.path = '/';

      request?.method = Method.patch;

      final response = await router?.handleRequest(request!);

      expect(response?.body, 'test');
    });

    test('handles delete request', () async {
      router?.delete('/', (req) => res.text('test'));

      request?.path = '/';

      request?.method = Method.delete;

      final response = await router?.handleRequest(request!);

      expect(response?.body, 'test');
    });

    test('handler can access parameters', () async {
      router?.get(
        '/entry/:parameter',
        (req) => res.text(req.parameters['parameter']),
      );

      request?.path = '/entry/hello';

      final response = await router?.handleRequest(request!);

      expect(response?.body, 'hello');
    });

    test('returns 404 when path not found', () async {
      router?.get('/valid-path', (req) => res.text('found'));

      request?.path = '/invalid-path';

      expect(
        () => router?.handleRequest(request!),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('returns 404 when method not allowed', () async {
      router?.get('/valid-path', (req) => res.text('found'));

      request?.path = '/valid-path';
      request?.method = Method.post;

      expect(
        () => router?.handleRequest(request!),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('handles multiple path parameters', () async {
      router?.get(
        '/users/:userId/posts/:postId',
        (req) =>
            res.text('${req.parameters['userId']}-${req.parameters['postId']}'),
      );

      request?.path = '/users/123/posts/456';

      final response = await router?.handleRequest(request!);

      expect(response?.body, '123-456');
    });
  });

  group('middleware tests', () {
    Router? router;
    MockRequest? request;

    setUp(() {
      router = Router();
      request = MockRequest();
    });

    test('global middleware is applied to all routes', () async {
      // Create router with global middleware
      router = Router(
        middlewares: [(req, next) => res.text('global middleware')],
      );

      router?.get('/', (req) => res.text('handler'));

      request?.path = '/';

      final response = await router?.handleRequest(request!);

      expect(response?.body, 'global middleware');
    });

    test('route-specific middleware is applied', () async {
      router?.get(
        '/',
        (req) => res.text('handler'),
        middlewares: [(req, next) => res.text('route middleware')],
      );

      request?.path = '/';

      final response = await router?.handleRequest(request!);

      expect(response?.body, 'route middleware');
    });

    test('middleware chain executes in correct order', () async {
      final order = <String>[];

      router = Router(
        middlewares: [
          (req, next) {
            order.add('global1');
            return next();
          },
          (req, next) {
            order.add('global2');
            return next();
          },
        ],
      );

      router?.get(
        '/',
        (req) {
          order.add('handler');
          return res.text('done');
        },
        middlewares: [
          (req, next) {
            order.add('route1');
            return next();
          },
          (req, next) {
            order.add('route2');
            return next();
          },
        ],
      );

      request?.path = '/';

      await router?.handleRequest(request!);

      expect(order, ['global1', 'global2', 'route1', 'route2', 'handler']);
    });

    test('middleware can short-circuit request handling', () async {
      router = Router(
        middlewares: [
          (req, next) => res.text('short-circuit'),
          (req, next) {
            fail('This middleware should not be called');
          },
        ],
      );

      router?.get('/', (req) {
        fail('This handler should not be called');
      });

      request?.path = '/';

      final response = await router?.handleRequest(request!);

      expect(response?.body, 'short-circuit');
    });
  });

  group('nested router tests', () {
    Router? mainRouter;
    Router? nestedRouter;
    MockRequest? request;

    setUp(() {
      mainRouter = Router();
      nestedRouter = Router.nest('api');
      request = MockRequest();
    });

    test('nested router handles routes with correct prefix', () async {
      nestedRouter?.get('/users', (req) => res.text('users'));
      mainRouter?.merge(nestedRouter!);

      request?.path = '/api/users';

      final response = await mainRouter?.handleRequest(request!);

      expect(response?.body, 'users');
    });

    test('nested router with root path', () async {
      nestedRouter?.get('/', (req) => res.text('api root'));
      mainRouter?.merge(nestedRouter!);

      request?.path = '/api';

      final response = await mainRouter?.handleRequest(request!);

      expect(response?.body, 'api root');
    });

    test('nested routers with multiple levels', () async {
      final v1Router = Router.nest('v1');
      v1Router.get('/products', (req) => res.text('v1 products'));

      nestedRouter?.merge(v1Router);
      mainRouter?.merge(nestedRouter!);

      request?.path = '/api/v1/products';

      final response = await mainRouter?.handleRequest(request!);

      expect(response?.body, 'v1 products');
    });

    test('nested router with path parameters', () async {
      nestedRouter?.get('/users/:id', (req) => res.text(req.parameters['id']));
      mainRouter?.merge(nestedRouter!);

      request?.path = '/api/users/123';

      final response = await mainRouter?.handleRequest(request!);

      expect(response?.body, '123');
    });

    test('nested router with middleware', () async {
      nestedRouter = Router.nest(
        'api',
        middlewares: [(req, next) => res.text('api middleware')],
      );

      nestedRouter?.get('/users', (req) => res.text('users'));
      mainRouter?.merge(nestedRouter!);

      request?.path = '/api/users';

      final response = await mainRouter?.handleRequest(request!);

      expect(response?.body, 'api middleware');
    });
  });

  group('router merge tests', () {
    Router? mainRouter;
    Router? otherRouter;
    MockRequest? request;

    setUp(() {
      mainRouter = Router();
      otherRouter = Router();
      request = MockRequest();
    });

    test('merges routes from another router', () async {
      otherRouter?.get('/other', (req) => res.text('other route'));
      mainRouter?.merge(otherRouter!);

      request?.path = '/other';

      final response = await mainRouter?.handleRequest(request!);

      expect(response?.body, 'other route');
    });

    test('merges routes with same path but different methods', () async {
      otherRouter?.get('/resource', (req) => res.text('get resource'));
      otherRouter?.post('/resource', (req) => res.text('post resource'));

      mainRouter?.merge(otherRouter!);

      request?.path = '/resource';

      final getResponse = await mainRouter?.handleRequest(request!);
      expect(getResponse?.body, 'get resource');

      request?.method = Method.post;
      final postResponse = await mainRouter?.handleRequest(request!);
      expect(postResponse?.body, 'post resource');
    });
  });
}
