import '../exceptions/lunart_exception.dart';

class UnauthorizedException extends LunartException {
  const UnauthorizedException([
    String? message,
    Object? error,
    StackTrace? stackTrace,
  ]) : super(
         statusCode: 401,
         message: message,
         log: false,
         error: error,
         stackTrace: stackTrace,
       );
}
