import 'package:lunart/lunart.dart';

void main() {
  final app = Lunart();

  app.use(bodyLimit(maxBytes: .fromMegabytes(50)));

  app.post('/post', (req) {
    return req.body();
  });

  app.serve();
}
