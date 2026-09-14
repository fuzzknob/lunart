import 'package:lunart/lunart.dart';

void main() {
  final app = Lunart();

  // Adds default secure headers
  app.use(
    secureHeaders(),
  );

  app.get('/', (req) {
    return 'Secure headers added. Check your headers';
  });

  app.serve();
}
