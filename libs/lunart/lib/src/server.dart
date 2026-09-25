import 'dart:io';
import 'dart:typed_data';

import 'enums/method.dart';
import 'interfaces/request_handler.dart';
import 'exceptions/exception.dart';
import 'response_resolver.dart';
import 'types.dart';
import 'request.dart';
import 'response.dart';
import 'utils.dart';

class Server {
  late final RequestHandler router;
  final List<Middleware> globalMiddlewares = [];
  final ResponseTypeResolver resTypeResolver = ResponseTypeResolver();

  Server use(Middleware middleware) {
    globalMiddlewares.add(middleware);

    return this;
  }

  Server registerResponseResolver<T>(ResponseResolver<T> resolver) {
    resTypeResolver.register<T>(resolver);

    return this;
  }

  Future<Server> serve(
    RequestHandler router, {
    int port = 8000,
    String host = '0.0.0.0',
  }) async {
    this.router = router;

    final httpServer = await HttpServer.bind(host, port);

    httpServer.listen(handleRequest);

    return this;
  }

  Future<Request> makeLunartRequest(HttpRequest httpRequest) async {
    final headers = <String, String>{};

    httpRequest.headers.forEach((name, values) {
      headers[name] = values.join(', ');
    });

    return Request(
      headers: headers,
      method: Method.fromString(httpRequest.method),
      nativeRequest: httpRequest,
      path: httpRequest.uri.path,
      queries: httpRequest.uri.queryParameters,
    );
  }

  void handleRequest(HttpRequest httpRequest) async {
    try {
      final request = await makeLunartRequest(httpRequest);
      final response = await invokeHandler(
        request: request,
        middlewares: globalMiddlewares,
        handler: router.handleRequest,
      );

      final lunartResponse = await resTypeResolver.resolve(response);

      await writeResponse(lunartResponse, httpRequest.response);
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);

      writeResponse(
        Res.status(500).text('Internal Server Error'),
        httpRequest.response,
      );
    }
  }

  Stream<List<int>> getStreamedResponse(Stream stream) {
    Stream<List<int>>? resStream;

    if (stream is Stream<List<int>>) {
      resStream = stream;
    } else if (stream is Stream<String>) {
      resStream = stream.map((s) => s.codeUnits);
    } else if (stream is Stream<Uint8List>) {
      resStream = stream.map((s) => s.toList());
    }

    if (resStream == null) {
      throw LunartException(
        message: 'Unsupported stream type: ${stream.runtimeType}',
      );
    }

    return resStream;
  }

  Future<void> writeResponse(
    Response response,
    HttpResponse httpResponse,
  ) async {
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

    // if (response.hasHijacked) {
    //   return response.hijacker?.call(httpResponse, response);
    // }

    httpResponse.bufferOutput = response.bufferResponse;

    if (response.body is Stream) {
      await httpResponse.addStream(
        getStreamedResponse(response.body as Stream),
      );
    } else {
      httpResponse.write(response.body);
    }

    return httpResponse.close();
  }
}
