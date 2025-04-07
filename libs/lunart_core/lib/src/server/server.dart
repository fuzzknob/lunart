import 'dart:io';
import 'dart:convert' as convert;

import 'package:collection/collection.dart';
import 'package:mime/mime.dart';

import '../exceptions/lunart_exception.dart';
import '../helpers/sse.dart' as sse;
import '../plugins/base_plugin.dart';
import '../cookie.dart';
import '../method.dart';
import '../types.dart';
import '../utils.dart';

part 'request.dart';
part 'response.dart';

typedef Plugin = Function(Server server);

abstract interface class RequestHandler {
  Future<Response> handleRequest(Request request);
}

class Server {
  late final RequestHandler _router;
  final List<Middleware> _middlewares = [];

  Server({barebones = false}) {
    if (!barebones) {
      plug(basePlugin);
    }
  }

  Server use(Middleware middleware) {
    _middlewares.add(middleware);
    return this;
  }

  Server plug(Plugin plugin) {
    plugin(this);
    return this;
  }

  Future<Server> serve(
    RequestHandler router, {
    port = 8000,
    host = '0.0.0.0',
    silent = false,
  }) async {
    _router = router;
    final httpServer = await HttpServer.bind(host, port);
    httpServer.listen(_handleRequest);
    if (!silent) {
      print('Started server at $host:$port');
    }
    return this;
  }

  void _handleRequest(HttpRequest httpRequest) async {
    final request = await _makeLunartRequest(httpRequest);
    final response = await invokeHandler(
      request: request,
      middlewares: _middlewares,
      handler: _router.handleRequest,
    );
    await _writeResponse(response, httpRequest.response);
  }

  Future<void> _writeResponse(Response response, HttpResponse httpResponse) {
    httpResponse.statusCode = response.statusCode;
    response.headers.forEach(
      (key, value) => httpResponse.headers.set(key, value),
    );
    for (final cookie in response.cookies) {
      if (cookie.signed && !cookie.hasSigned) {
        throw Exception(
          'Cookie "${cookie.name}" wasn\'t signed. Have you added the `signedCookie` middleware?',
        );
      }
      final httpCookie = Cookie(cookie.name, cookie.value);
      httpCookie.domain = cookie.domain;
      httpCookie.expires = cookie.expires;
      httpCookie.httpOnly = cookie.httpOnly;
      httpCookie.maxAge = cookie.maxAge?.inSeconds;
      httpCookie.path = cookie.path;
      httpCookie.sameSite = cookie.sameSite;
      httpCookie.secure = cookie.secure;
      httpResponse.cookies.add(httpCookie);
    }
    if (response.hasHijacked) {
      return response._hijacker?.call(httpResponse, response);
    }
    httpResponse.write(response.body);
    return httpResponse.close();
  }

  Future<Request> _makeLunartRequest(HttpRequest httpRequest) async {
    final headers = <String, List<String>>{};
    httpRequest.headers.forEach((name, values) {
      headers[name] = values;
    });
    return Request(
      headers: headers,
      method: Method.fromString(httpRequest.method),
      nativeRequest: httpRequest,
      path: httpRequest.uri.path,
      queries: httpRequest.uri.queryParameters,
    );
  }
}
