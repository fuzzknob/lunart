import 'dart:async';
import 'package:lunart/lunart.dart';

Router userRoutes() {
  final routes = Router.nest('/users');

  // the full path will be /users/:id
  routes.get('/:id', (_) => res().ok());

  // the full path will be /users/update
  routes.patch('/update', (_) => res());

  // the full path will be /users
  routes.post('/', (_) => res());

  return routes;
}

Router postsRoutes() {
  // You can also add posts route wide middlewares
  final routes = Router.nest('/posts', middlewares: [postMiddleware]);

  routes.post('/', (_) => res());

  routes.get('/:id', (_) => res().ok());

  routes.patch('/update', (_) => res());

  return routes;
}

void main() {
  final routes = Router();

  routes.get('/', (_) => res());

  // You can merge routes to the main
  routes.merge(userRoutes());
  routes.merge(postsRoutes());

  Server().serve(routes);
}

FutureOr<Response> postMiddleware(Request request, Next next) {
  return next();
}
