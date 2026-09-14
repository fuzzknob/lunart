import 'exception.dart';

class ServiceUnavailableException extends LunartException {
  const ServiceUnavailableException({
    super.message,
    super.error,
    super.context,
    super.stackTrace,
  }) : super(
         statusCode: 503,
         log: true,
       );
}
