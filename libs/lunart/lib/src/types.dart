import 'dart:async';

import 'request.dart';
import 'response.dart';
import 'websocket.dart';

typedef Next = FutureOr<dynamic> Function();
typedef Handler = FutureOr<dynamic> Function(Request request);
typedef Middleware = FutureOr<dynamic> Function(Request request, Next next);
typedef ResponseResolver<T> = FutureOr<Response> Function(T response);
typedef WebSocketHandler = void Function(WebSocketListener);
