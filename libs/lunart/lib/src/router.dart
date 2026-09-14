import 'libs/path_trie.dart';
import 'enums/method.dart';
import 'interfaces/request_handler.dart';
import 'exceptions/not_found_exception.dart';
import 'request.dart';
import 'types.dart';
import 'utils.dart';

class Router implements RequestHandler {
  Router({String prefix = '', List<Middleware> middlewares = const []}) {
    this.prefix = _trimSlashes(prefix);
    _globalMiddlewares = middlewares;
  }

  late final String prefix;
  late final List<Middleware> _globalMiddlewares;

  final routesMap = <String, RouteHandler>{};
  final pathTrie = PathTrie();

  factory Router.nest(
    String prefix, {
    List<Middleware> middlewares = const [],
  }) => Router(prefix: prefix, middlewares: middlewares);

  Router group(
    void Function(Router) builder, {
    String prefix = '',
    List<Middleware> middlewares = const [],
  }) {
    final groupRouter = Router(prefix: prefix, middlewares: middlewares);

    builder(groupRouter);

    mount(groupRouter);

    return this;
  }

  Router add(
    String path,
    Method method,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) {
    final fullPath = _buildPath(path);

    routesMap[_createRouteMapKey(fullPath, method)] = RouteHandler(
      path: fullPath,
      method: method,
      handler: handler,
      middlewares: [..._globalMiddlewares, ...middlewares],
    );

    pathTrie.addPath(fullPath);

    return this;
  }

  Router get(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.get, handler, middlewares: middlewares);

  Router post(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.post, handler, middlewares: middlewares);

  Router put(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.put, handler, middlewares: middlewares);

  Router patch(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.patch, handler, middlewares: middlewares);

  Router delete(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.delete, handler, middlewares: middlewares);

  Router mount(Router router) {
    for (final handler in router.routesMap.values) {
      final path = _buildPath(handler.path);
      final mapKey = _createRouteMapKey(path, handler.method);

      if (routesMap.containsKey(mapKey)) {
        // TODO: use a proper logger instead of print
        print(
          '\x1B[33m[WARN]\x1B[0m Route conflict during mount: ${handler.method} $path already exists and will be replaced.',
        );
      }

      routesMap[mapKey] = handler.copyWith(
        path: path,
      );
      pathTrie.addPath(path);
    }

    return this;
  }

  @override
  Future handleRequest(Request request) async {
    final path = request.path;
    final method = request.method;

    var handler = routesMap[_createRouteMapKey(path, method)];

    if (handler != null) {
      return handler.invoke(request);
    }

    final result = pathTrie.lookupPath(path);

    if (result != null) {
      request.parameters = result.parameters;
      handler = routesMap[_createRouteMapKey(result.path, method)];

      if (handler != null) return handler.invoke(request);
    }

    throw NotFoundException(message: "'$path' path not found");
  }

  String _buildPath(String path) {
    if (prefix.isEmpty) return '/${_trimSlashes(path)}';

    if (path == '/') return '/$prefix';

    return '/$prefix/${_trimSlashes(path)}';
  }

  String _createRouteMapKey(String path, Method method) => '$method@$path';

  String _trimSlashes(String path) => path.replaceAll(RegExp(r'^/+|/+$'), '');
}

class RouteHandler {
  const RouteHandler({
    required this.path,
    required this.method,
    required this.handler,
    this.middlewares = const [],
  });
  final String path;
  final Method method;
  final Handler handler;
  final List<Middleware> middlewares;

  RouteHandler copyWith({
    String? path,
    Method? method,
    Handler? handler,
    List<Middleware>? middlewares,
  }) {
    return RouteHandler(
      path: path ?? this.path,
      method: method ?? this.method,
      handler: handler ?? this.handler,
      middlewares: middlewares ?? this.middlewares,
    );
  }

  Future invoke(Request request) async {
    return invokeHandler(
      request: request,
      middlewares: middlewares,
      handler: handler,
    );
  }
}
