import '../exceptions/lunart_exception.dart';

class GatewayTimeoutException extends LunartException {
  const GatewayTimeoutException([
    String? message,
    Object? error,
    StackTrace? stackTrace,
  ]) : super(
         statusCode: 504,
         message: message,
         log: true,
         error: error,
         stackTrace: stackTrace,
       );
}
