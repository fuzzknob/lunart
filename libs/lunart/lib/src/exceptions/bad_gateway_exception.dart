import 'exception.dart';

class BadGatewayException extends LunartException {
  BadGatewayException({
    super.message,
    super.error,
    super.context,
    super.stackTrace,
  }) : super(
         statusCode: 502,
         log: true,
       );
}
