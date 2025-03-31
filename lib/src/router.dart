import 'package:lunart/src/exceptions/not_found_exception.dart';

import 'libs/path_trie.dart';
import 'utils.dart';
import 'method.dart';
import 'request.dart';
import 'response.dart';
import 'types.dart';
import 'server.dart';

class Router implements RequestHandler {
  Router({String prefix = '', List<Middleware> middlewares = const []}) {
    this.prefix = _trimLeadigSlash(prefix);
    _globalMiddlewares = middlewares;
  }

  late final String prefix;
  late final List<Middleware> _globalMiddlewares;

  final _routesMap = <String, RouteHandler>{};
  final _pathTrie = PathTrie();

  factory Router.nest(
    String prefix, {
    List<Middleware> middlewares = const [],
  }) => Router(prefix: prefix, middlewares: middlewares);

  Router add(
    String path,
    Method method,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) {
    final fullPath = _buildPath(path);
    _routesMap[_createRouteMapKey(fullPath, method)] = RouteHandler(
      path: fullPath,
      method: method,
      handler: handler,
      middlewares: [..._globalMiddlewares, ...middlewares],
    );
    _pathTrie.addPath(fullPath);
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

  Router merge(Router router) {
    for (final handler in router._routesMap.values) {
      final path = _buildPath(handler.path);
      _routesMap[_createRouteMapKey(path, handler.method)] = handler.copyWith(
        path: path,
      );
      _pathTrie.addPath(path);
    }
    return this;
  }

  @override
  Future<Response> handleRequest(Request request) async {
    final path = request.path;
    final method = request.method;
    var handler = _routesMap[_createRouteMapKey(path, method)];
    if (handler != null) {
      return handler.invoke(request);
    }
    final result = _pathTrie.lookupPath(path);
    if (result == null) {
      throw NotFoundException("'$path' path not found");
    }
    request.parameters = result.parameters;
    handler = _routesMap[_createRouteMapKey(result.path, method)];
    if (handler == null) {
      throw NotFoundException('"$path" path not found');
    }
    return handler.invoke(request);
  }

  String _buildPath(String path) {
    if (prefix.isEmpty) return path;
    if (path == '/') return '/$prefix';
    return '/$prefix/${_trimLeadigSlash(path)}';
  }

  String _createRouteMapKey(String path, Method method) => '$method@$path';
  String _trimLeadigSlash(String path) => path.replaceFirst(RegExp(r'^\/'), '');
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

  Future<Response> invoke(Request request) async {
    return invokeHandler(
      request: request,
      middlewares: middlewares,
      handler: handler,
    );
  }
}
