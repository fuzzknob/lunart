import 'core.dart';
import 'route.dart';

typedef Handler = Function(Request request);

class Lunart {
  late final Server _server;
  late final Route _routes;

  Lunart({String prefix = '', bool barebones = false}) {
    _routes = Route(prefix: prefix);
    _server = Server(barebones: barebones);
  }

  Lunart use(Middleware middleware) {
    _server.use(middleware);

    return this;
  }

  Lunart plug(Plugin plugin) {
    _server.plug(plugin);

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

  Lunart delete(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.delete, handler, middlewares: middlewares);

  Lunart group(
    void Function(Route) builder, {
    String prefix = '',
    List<Middleware> middlewares = const [],
  }) {
    _routes.group(builder, prefix: prefix, middlewares: middlewares);

    return this;
  }

  Lunart add(
    String path,
    Method method,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) {
    _routes.add(path, method, handler, middlewares: middlewares);

    return this;
  }

  Lunart useRoutes(Route route) {
    _routes.merge(route);

    return this;
  }

  Future<Lunart> serve({
    int port = 8000,
    String host = '0.0.0.0',
    bool silent = false,
  }) async {
    await _server.serve(_routes.router, port: port, host: host, silent: silent);

    return this;
  }
}
