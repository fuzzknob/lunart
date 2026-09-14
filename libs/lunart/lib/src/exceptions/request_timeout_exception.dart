import 'exception.dart';

class RequestTimeoutException extends LunartException {
  const RequestTimeoutException({
    super.message,
    super.error,
    super.context,
    super.stackTrace,
  }) : super(
         statusCode: 408,
         log: false,
       );
}
