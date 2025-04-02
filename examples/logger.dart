import 'package:lunart/lunart.dart';

void main() {
  final router = Router();

  router.get('/', (_) => res().message('Hello World'));

  router.post('/posts', (req) async {
    final data = await req.body();
    return res().json(data);
  });

  router.get('/posts/:id', (req) {
    final id = req.parameters['id'];

    print(id);
    return res();
  });

  // Add request logger as a global middleware
  // This will log every request
  Server().use(logger).serve(router);
}
