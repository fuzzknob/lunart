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
  });
}
