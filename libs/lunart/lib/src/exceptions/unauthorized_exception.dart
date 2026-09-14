import 'exception.dart';

class UnauthorizedException extends LunartException {
  const UnauthorizedException({
    super.message,
    super.error,
    super.context,
    super.stackTrace,
  }) : super(
         statusCode: 401,
         log: false,
       );
}
