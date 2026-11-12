import '../exceptions/exception.dart';
import '../types.dart';
import '../request.dart';
import '../response.dart';

Middleware errorHandler({
  bool logError = true,
  Function(Object, StackTrace)? onError,
}) {
  return (Request request, Next next) async {
    try {
      return await next();
    } on LunartException catch (e, stacktrace) {
      if (e.log && logError) {
        print(e);
        print(stacktrace);
      }

      if (onError != null) {
        final res = onError(e, stacktrace);

        if (res != null) return res;
      }

      return _buildErrorResponse(e, request);
    } catch (e, stacktrace) {
      if (logError) {
        print(e);
        print(stacktrace);
      }

      if (onError != null) {
        final res = onError(e, stacktrace);

        if (res != null) return res;
      }

      return _buildErrorResponse(
        LunartException(
          statusCode: 500,
          message: 'There was an unknown error',
          error: e,
          stackTrace: stacktrace,
        ),
        request,
      );
    }
  };
}

Response _buildErrorResponse(LunartException exception, Request request) {
  final acceptHeaders = request.header('Accept') ?? '';
  final message =
      exception.message ?? 'There was an ${exception.statusCode} error!';
  final response = Res.status(exception.statusCode);

  if (acceptHeaders.contains('application/json')) {
    return response.json({
      'message': message,
    });
  }

  if (acceptHeaders.contains('text/html')) {
    return response.html(
      '<h3 style="font-family: sans-serif,serif;">$message</h3>',
    );
  }

  return response.text(message);
}
