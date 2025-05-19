import '../exceptions/lunart_exception.dart';

class InternalServerError extends LunartException {
  const InternalServerError([
    String? message,
    Object? error,
    StackTrace? stackTrace,
  ]) : super(
         statusCode: 500,
         message: message,
         log: true,
         error: error,
         stackTrace: stackTrace,
       );
}
