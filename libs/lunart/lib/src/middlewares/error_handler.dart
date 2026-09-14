import '../exceptions/exception.dart';
import '../types.dart';
import '../request.dart';
import '../response.dart';

Future errorHandler(Request request, Next next, {bool logError = true}) async {
  try {
    return await next();
  } on LunartException catch (e, stacktrace) {
    if (e.log && logError) {
      print(e);
      print(stacktrace);
    }

    return _buildErrorResponse(e, request);
  } catch (e, stacktrace) {
    if (logError) {
      print(e);
      print(stacktrace);
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
}

Response _buildErrorResponse(LunartException exception, Request request) {
  final acceptHeaders = request.headers['accept'] ?? '';
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
