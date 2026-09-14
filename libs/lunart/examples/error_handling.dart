import 'package:lunart/lunart.dart';

void main() {
  final app = Lunart();

  // This exception will be handled by global error_handler middleware
  // The response for this request will be a 404 json message
  app.get('/', (_) {
    throw NotFoundException(
      message: 'The thing you\'re looking for is not found.',
    );
  });

  app.get('/custom-exception', (_) {
    throw CustomException();
  });

  app.serve();
}

// Defining a custom exception
class CustomException extends LunartException {
  CustomException() : super(message: 'Custom error message', statusCode: 418);
}
