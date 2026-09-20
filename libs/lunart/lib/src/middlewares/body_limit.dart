import '../exceptions/content_too_large_exception.dart';
import '../libs/size.dart';
import '../request.dart';
import '../types.dart';

Middleware bodyLimit({Size? maxBytes}) {
  return (Request req, Next next) async {
    final maxRequestSize = maxBytes ?? Size.fromMegabytes(50);

    final contentLength = req.headers['content-length'];

    if (contentLength != null &&
        int.parse(contentLength) > maxRequestSize.bytes) {
      throw ContentTooLargeException(
        message: 'Request body exceeds maximum size of $maxRequestSize',
      );
    }

    return next();
  };
}
