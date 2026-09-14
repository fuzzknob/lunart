import 'exception.dart';

class NotImplementedException extends LunartException {
  const NotImplementedException({
    super.message,
    super.error,
    super.context,
    super.stackTrace,
  }) : super(
         statusCode: 501,
         log: true,
       );
}
