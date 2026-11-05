import 'dart:async';

import '../exceptions/request_timeout_exception.dart';
import '../request.dart';
import '../types.dart';

Middleware timeout({
  Duration duration = const Duration(seconds: 5),
  Function(Request req)? handleTimeout,
}) {
  return (Request req, Next next) async {
    try {
      return await Future(() async {
        // Waits for the request to be read completely,
        // if the request takes longer than the duration time it will trigger timeout exception
        // This needs to be here because if the handler or any middlewares don't call this function
        // and say the client is slow to send request chunks it will indefinitely wait for the client and never complete the response
        // It's Kind of hacky but it works
        await req.rawBody();

        return await next();
      }).timeout(duration);
    } on TimeoutException {
      if (handleTimeout != null) {
        return handleTimeout;
      }

      throw RequestTimeoutException(message: 'Request timed out');
    }
  };
}
