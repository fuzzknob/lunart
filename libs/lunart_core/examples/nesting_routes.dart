import 'package:lucore/lucore.dart';

Router userRoutes() {
  final routes = Router.nest('/users');

  // the full path will be /users
  routes.get('/', (_) => res());

  // the full path will be /users/:id
  routes.get('/:id', (_) => res().ok());

  // the full path will be /users/update
  routes.patch('/update', (_) => res());

  return routes;
}

Router postsRoutes() {
  // We can also add route wide middlewares
  final routes = Router.nest('/posts', middlewares: [postsMiddleware]);

  routes.get('/', (_) => res());

  routes.get('/:id', (_) => res().ok());

  routes.patch('/update', (_) => res());

  return routes;
}

void main() {
  final routes = Router();

  routes.get('/', (_) => res());

  // Now to merge everything to the main router
  routes.merge(userRoutes());
  routes.merge(postsRoutes());

  Server().serve(routes);
}

FutureOr<Response> postsMiddleware(Request request, Next next) {
  return next();
}
