import 'package:lunart/lunart.dart';

Router userRouter() {
  final router = Router.nest('/users');

  // the full path will be /users
  router.get('/', (_) => 'Hello from /users');

  // the full path will be /users/:id
  router.get('/:id', (req) => 'Hello from /users/${req.parameters['id']}');

  // the full path will be /users/update
  router.patch('/update', (_) => 'Hello from /users/update');

  return router;
}

Router postRouter() {
  // We can also add route wide middlewares
  final router = Router.nest('/posts', middlewares: [postsMiddleware]);

  router.get('/', (_) => 'Hello from /posts');

  router.get('/:id', (req) => 'Hello from /posts/${req.parameters['id']}');

  router.patch('/update', (_) => 'Hello from /posts/update');

  return router;
}

void main() {
  final app = Lunart();

  app.get('/', (_) => 'Hello from /');

  // Now add it to the app
  app.mount(userRouter());
  app.mount(postRouter());

  app.serve();
}

Object? postsMiddleware(Request request, Next next) {
  print('postsMiddleware: ${request.path}');
  return next();
}
