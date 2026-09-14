import 'exception.dart';

class TooManyRequestsException extends LunartException {
  const TooManyRequestsException({
    super.message,
    super.error,
    super.context,
    super.stackTrace,
  }) : super(
         statusCode: 429,
         log: false,
       );
}
