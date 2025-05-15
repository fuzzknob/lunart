import '../exceptions/lunart_exception.dart';

class ServiceUnavailableException extends LunartException {
  const ServiceUnavailableException([
    String? message,
    Object? error,
    StackTrace? stackTrace,
  ]) : super(
         statusCode: 503,
         message: message,
         log: true,
         error: error,
         stackTrace: stackTrace,
       );
}
