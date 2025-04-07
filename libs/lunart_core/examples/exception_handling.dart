import 'package:lucore/lucore.dart';

void main() {
  final router = Router();

  // This exception will be handled by global error_handler middleware
  // The response for this request will be a 404 json message
  router.get('/', (_) {
    throw NotFoundException('The thing you\'re looking for is not found.');
  });

  router.get('/custom-exception', (_) {
    throw CustomException();
  });

  Server().serve(router);
}

// Defining a custom exception
class CustomException extends LunartException {
  CustomException() : super(message: 'Custom error message', statusCode: 418);
}
