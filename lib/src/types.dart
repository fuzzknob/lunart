import 'dart:async';

import 'server/server.dart';

typedef Next = FutureOr<Response> Function();
typedef Handler = FutureOr<Response> Function(Request request);
typedef Middleware = FutureOr<Response> Function(Request request, Next next);
