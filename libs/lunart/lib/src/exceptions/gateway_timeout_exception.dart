import 'exception.dart';

class GatewayTimeoutException extends LunartException {
  const GatewayTimeoutException({
    super.message,
    super.error,
    super.context,
    super.stackTrace,
  }) : super(
         statusCode: 504,
         log: true,
       );
}
