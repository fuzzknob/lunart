import 'interfaces/plugin.dart';
import 'plugins/base_plugin.dart';
import 'enums/method.dart';
import 'server.dart';
import 'router.dart';
import 'types.dart';

class Lunart {
  late final Router _router;
  late final Server _server;

  Lunart({String prefix = '', bool barebones = false}) {
    _router = Router(prefix: prefix);
    _server = Server();

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
    _server.use(middleware);

    return this;
  }

  Lunart mount(Router router) {
    _router.mount(router);

    return this;
  }

  Lunart registerResponseResolver<T>(ResponseResolver<T> resolver) {
    _server.registerResponseResolver<T>(resolver);

    return this;
  }

  Lunart add(
    String path,
    Method method,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) {
    _router.add(path, method, handler, middlewares: middlewares);

    return this;
  }

  Lunart get(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.get, handler, middlewares: middlewares);

  Lunart head(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.head, handler, middlewares: middlewares);

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

  Lunart delete(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.delete, handler, middlewares: middlewares);

  Lunart connect(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.connect, handler, middlewares: middlewares);

  Lunart options(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.options, handler, middlewares: middlewares);

  Lunart trace(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.trace, handler, middlewares: middlewares);

  Lunart patch(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.patch, handler, middlewares: middlewares);

  Lunart query(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.query, handler, middlewares: middlewares);

  Lunart all(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.all, handler, middlewares: middlewares);

  Lunart group(
    void Function(Router) builder, {
    String prefix = '',
    List<Middleware> middlewares = const [],
  }) {
    _router.group(builder, prefix: prefix, middlewares: middlewares);

    return this;
  }

  Lunart ws(
    String path,
    WebSocketHandler handler, {
    List<Middleware> middlewares = const [],
    Duration? pingInterval,
  }) {
    _router.ws(
      path,
      handler,
      middlewares: middlewares,
      pingInterval: pingInterval,
    );

    return this;
  }

  Future<Lunart> serve({
    int port = 8000,
    String host = '0.0.0.0',
    bool silent = false,
    ServerIsolatesMode isolatesMode = .singleIsolate,
    int isolates = 1,
  }) async {
    await _server.serve(
      _router,
      port: port,
      host: host,
      isolatesMode: isolatesMode,
      isolates: isolates,
    );

    if (!silent) {
      print('Started server at $host:$port');
    }

    return this;
  }
}
