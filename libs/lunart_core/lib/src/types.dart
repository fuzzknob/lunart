import 'dart:async';

import 'server/server.dart';

typedef Plugin = Function(Server server);

typedef Next = FutureOr<Response> Function();
typedef Handler = FutureOr<Response> Function(Request request);
typedef Middleware = FutureOr<Response> Function(Request request, Next next);
