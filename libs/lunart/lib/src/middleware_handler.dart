import 'core.dart';

abstract interface class MiddlewareHandler {
  FutureOr<Response> handle(Request request, Next next);

  factory MiddlewareHandler.fromMiddleware(Middleware middleware) {
    return _FromMiddleware(middleware);
  }
}

class _FromMiddleware implements MiddlewareHandler {
  const _FromMiddleware(this.middleware);

  final Middleware middleware;

  @override
  FutureOr<Response> handle(Request request, Next next) {
    return middleware(request, next);
  }
}
