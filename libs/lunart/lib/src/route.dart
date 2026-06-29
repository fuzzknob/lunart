import 'dart:io';

import 'package:lucore/lucore.dart' hide Handler;
import 'package:lucore/lucore.dart' as core;

typedef Handler = Function(Request request);

class Route {
  late final Router router;

  Route({String prefix = '', List<Middleware> middlewares = const []}) {
    router = Router(prefix: prefix, middlewares: middlewares);
  }

  factory Route.nest(
    String prefix, {
    List<Middleware> middlewares = const [],
  }) => Route(prefix: prefix, middlewares: middlewares);

  Route get(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.get, handler, middlewares: middlewares);

  Route post(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.post, handler, middlewares: middlewares);

  Route put(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.put, handler, middlewares: middlewares);

  Route patch(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.patch, handler, middlewares: middlewares);

  Route delete(
    String path,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) => add(path, Method.delete, handler, middlewares: middlewares);

  Route add(
    String path,
    Method method,
    Handler handler, {
    List<Middleware> middlewares = const [],
  }) {
    router.add(path, method, _bridgeHandler(handler), middlewares: middlewares);

    return this;
  }

  Route merge(Route route) {
    router.merge(route.router);

    return this;
  }

  Route group(
    void Function(Route) builder, {
    String prefix = '',
    List<Middleware> middlewares = const [],
  }) {
    final groupRouter = Route(prefix: prefix, middlewares: middlewares);

    builder(groupRouter);

    merge(groupRouter);

    return this;
  }

  core.Handler _bridgeHandler(Handler handler) {
    return (Request request) async {
      final response = await handler(request);

      if (response == null) {
        return res.setBody(null);
      }

      if (response is Response) {
        return response;
      }

      if (response is String) {
        return res.text(response);
      }

      if (response is Map) {
        return res.json(response);
      }

      if (response is File) {
        return res.file(response);
      }

      return res.setBody(response);
    };
  }
}
