import '../exceptions/lunart_exception.dart';

class BadGatewayException extends LunartException {
  const BadGatewayException([
    String? message,
    Object? error,
    StackTrace? stackTrace,
  ]) : super(
         statusCode: 502,
         message: message,
         log: true,
         error: error,
         stackTrace: stackTrace,
       );
}
