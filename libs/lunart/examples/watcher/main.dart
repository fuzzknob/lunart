import 'package:lunart/lunart.dart';

void main() {
  final app = Lunart();

  app.use(requestLogger);

  app.get('/', (_) => 'Ahoy-hoy');

  app.get('/another', (_) => 'Another hoy-hoy');

  app.serve();
}
