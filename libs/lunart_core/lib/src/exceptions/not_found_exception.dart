import '../exceptions/lunart_exception.dart';

class NotFoundException extends LunartException {
  const NotFoundException([
    String? message,
    Object? error,
    StackTrace? stackTrace,
  ]) : super(
         statusCode: 404,
         message: message,
         log: false,
         error: error,
         stackTrace: stackTrace,
       );
}
