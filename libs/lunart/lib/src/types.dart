import 'dart:async';

import 'request.dart';
import 'response.dart';
import 'websocket.dart';

typedef Next = FutureOr<Object?> Function();
typedef Handler = FutureOr<Object?> Function(Request request);
typedef Middleware = FutureOr<Object?> Function(Request request, Next next);
typedef ResponseResolver<T> = FutureOr<Response> Function(T response);
typedef WebSocketHandler = void Function(WebSocketListener);
