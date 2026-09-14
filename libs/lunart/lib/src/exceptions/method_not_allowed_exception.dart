import 'exception.dart';

class MethodNotAllowedException extends LunartException {
  const MethodNotAllowedException({
    super.message,
    super.error,
    super.context,
    super.stackTrace,
  }) : super(
         statusCode: 405,
         log: false,
       );
}
