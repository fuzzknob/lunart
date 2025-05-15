import '../exceptions/lunart_exception.dart';

class ForbiddenException extends LunartException {
  const ForbiddenException([
    String? message,
    Object? error,
    StackTrace? stackTrace,
  ]) : super(
         statusCode: 403,
         message: message,
         log: false,
         error: error,
         stackTrace: stackTrace,
       );
}
