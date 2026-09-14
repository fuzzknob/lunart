import 'package:lunart/lunart.dart';

void main() {
  final app = Lunart();

  // Add request logger as a global middleware
  // This will log every request
  app.use(requestLogger);

  app.get('/', (_) => Res.message('Hello World'));

  app.post('/posts', (req) async {
    final data = await req.body();

    return data;
  });

  app.get('/posts/:id', (req) {
    final id = req.parameters['id'];

    print(id);
    return Res.ok();
  });

  app.serve();
}
