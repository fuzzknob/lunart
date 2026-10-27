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
      return await Future(next).timeout(duration);
    } on TimeoutException {
      if (handleTimeout != null) {
        return handleTimeout;
      }

      throw RequestTimeoutException(message: 'Request timed out');
    }
  };
}
