import 'package:lunart/lunart.dart';

void main() {
  final app = Lunart();

  // Throws a [RequestTimeoutException] if the request longer than the specified duration
  app.use(
    timeout(
      duration: Duration(seconds: 1),
    ),
  );

  // The request stalls for 5 seconds
  app.get('/', (_) => Future.delayed(Duration(seconds: 5)));

  app.serve();
}
