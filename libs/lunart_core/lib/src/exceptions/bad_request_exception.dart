import '../exceptions/lunart_exception.dart';

class BadRequestException extends LunartException {
  BadRequestException([String? message, Object? error, StackTrace? stackTrace])
    : super(
        statusCode: 400,
        message: message,
        log: false,
        error: error,
        stackTrace: stackTrace,
      );
}
