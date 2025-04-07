import 'package:lucore/lucore.dart';

void main() {
  final router = Router();

  router.get('/', (_) => res().message('Hello World'));

  router.post('/posts', (req) async {
    // get request body
    final data = await req.body();
    return res().json(data);
  });

  router.get('/posts/:id', (req) {
    // get request parameters from parameters map
    final id = req.parameters['id'];

    print(id);
    return res();
  });

  router.get('/posts/search', (req) {
    // get queries from the queries map
    final query = req.queries['q'];
    print(query);

    return res();
  });

  // Port can be set with port option
  Server().serve(router, port: 8888);
}
