import '../exceptions/lunart_exception.dart';

class BadRequestException extends LunartException {
  const BadRequestException([
    String? message,
    Object? error,
    StackTrace? stackTrace,
  ]) : super(
         statusCode: 400,
         message: message,
         log: false,
         error: error,
         stackTrace: stackTrace,
       );
}
