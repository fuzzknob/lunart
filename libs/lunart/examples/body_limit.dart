import 'package:lunart/lunart.dart';

void main() {
  final app = Lunart();

  // Limits the body size to 50MB
  app.use(bodyLimit(maxBytes: .fromMegabytes(50)));

  app.post('/post', (req) {
    return req.body();
  });

  app.serve();
}
