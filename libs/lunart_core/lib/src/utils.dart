import 'server/server.dart';
import 'types.dart';

Future<Response> invokeHandler({
  required Request request,
  required List<Middleware> middlewares,
  required Handler handler,
}) async {
  Handler invoke(int index) {
    return (request) {
      final middlewareCall = middlewares.elementAtOrNull(index);
      if (middlewareCall != null) {
        return middlewareCall(request, () {
          return invoke(index + 1)(request);
        });
      }
      return handler(request);
    };
  }

  return invoke(0)(request);
}
