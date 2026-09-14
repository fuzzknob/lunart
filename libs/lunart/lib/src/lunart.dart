import 'interfaces/plugin.dart';
import 'plugins/base_plugin.dart';
import 'enums/method.dart';
import 'server.dart';
import 'router.dart';
import 'types.dart';

class Lunart {
  late final Router router;
  late final Server server;

  Lunart({String prefix = '', bool barebones = false}) {
    router = Router(prefix: prefix);
    server = Server();

    if (!barebones) {
      plug(BaseLunartPlugin());
    }
  }

  Lunart plug(Plugin plugin) {
    plugin.plug(this);

    return this;
  }

  // Add global middleware
  Lunart use(Middleware middleware) {
    server.use(middleware);

    return this;
  }

  Lunart mount(Router router) {
    this.router.mount(router);

    return this;
  }

  Lunart registerResponseResolver<T>(ResponseResolver<T> resolver) {
    server.registerResponseResolver<T>(resolver);

    return this;
  }

  Lunart add(
    String path,
    Method method,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) {
    router.add(path, method, handler, middlewares: middlewares);

    return this;
  }

  Lunart get(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.get, handler, middlewares: middlewares);

  Lunart post(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.post, handler, middlewares: middlewares);

  Lunart put(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.put, handler, middlewares: middlewares);

  Lunart patch(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.patch, handler, middlewares: middlewares);

  Lunart group(
    void Function(Router) builder, {
    String prefix = '',
    List<Middleware> middlewares = const [],
  }) {
    router.group(builder, prefix: prefix, middlewares: middlewares);

    return this;
  }

  Lunart delete(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.delete, handler, middlewares: middlewares);

  Future<Lunart> serve({
    int port = 8000,
    String host = '0.0.0.0',
    bool silent = false,
  }) async {
    await server.serve(router, port: port, host: host);

    if (!silent) {
      print('Started server at $host:$port');
    }

    return this;
  }
}
