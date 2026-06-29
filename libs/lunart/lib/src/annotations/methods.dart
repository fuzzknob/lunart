import '../core.dart';
import '../middleware_handler.dart';

abstract class BaseMethod {
  const BaseMethod({
    required this.method,
    required this.path,
    this.middlwares = const [],
  });

  final Method method;
  final String path;
  final List<MiddlewareHandler> middlwares;
}

class Get extends BaseMethod {
  const Get([String path = '', List<MiddlewareHandler> middlewares = const []])
    : super(path: path, method: Method.get, middlwares: middlewares);
}

class Post extends BaseMethod {
  const Post([String path = '', List<MiddlewareHandler> middlewares = const []])
    : super(path: path, method: Method.post, middlwares: middlewares);
}

class Put extends BaseMethod {
  const Put([String path = '', List<MiddlewareHandler> middlewares = const []])
    : super(path: path, method: Method.put, middlwares: middlewares);
}

class Patch extends BaseMethod {
  const Patch([
    String path = '',
    List<MiddlewareHandler> middlewares = const [],
  ]) : super(path: path, method: Method.patch, middlwares: middlewares);
}

class Delete extends BaseMethod {
  const Delete([
    String path = '',
    List<MiddlewareHandler> middlewares = const [],
  ]) : super(path: path, method: Method.delete, middlwares: middlewares);
}

class Head extends BaseMethod {
  const Head([String path = '', List<MiddlewareHandler> middlewares = const []])
    : super(path: path, method: Method.head, middlwares: middlewares);
}

class Options extends BaseMethod {
  const Options([
    String path = '',
    List<MiddlewareHandler> middlewares = const [],
  ]) : super(path: path, method: Method.options, middlwares: middlewares);
}

class Trace extends BaseMethod {
  const Trace([
    String path = '',
    List<MiddlewareHandler> middlewares = const [],
  ]) : super(path: path, method: Method.trace, middlwares: middlewares);
}
