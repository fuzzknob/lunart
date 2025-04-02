import 'package:lunart/lunart.dart';

void main() {
  final router = Router();

  router.get('/', (_) => res().message('Hello World'));

  router.post('/posts', (req) async {
    final data = await req.body();
    return res().json(data);
  });

  // Just use the cors middleware on the server.
  // It will use the default settings with most permissive settings
  Server().use(cors()).serve(router);
}

void moreCors() {
  final router = Router();

  router.get('/', (_) => res().message('Hello World'));

  router.post('/posts', (req) async {
    final data = await req.body();
    return res().json(data);
  });

  // Configure cors according to your liking
  Server()
      .use(
        cors(
          origins: ['https://example.com'],
          allowHeaders: ['Content-Type'],
          allowMethods: [Method.post, Method.put],
          exposeHeaders: ['Accept-Type'],
          credentials: true,
          maxAge: 300,
        ),
      )
      .serve(router);
}
