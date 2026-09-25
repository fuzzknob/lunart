import 'dart:async';
import 'dart:io';
import 'dart:convert' as convert;

import 'utils.dart';
import 'cookie.dart';

class Response {
  int _statusCode = HttpStatus.ok;
  Object? _body = '';
  Map<String, Object> _headers = {};
  void Function(HttpResponse, Response)? _hijacker;
  List<LunartCookie> cookies = [];
  bool bufferResponse = false;

  // Will be flagged to be converted by the response converter registry
  bool autoResolveResponseType = false;

  int get statusCode => _statusCode;
  Map<String, Object> get headers => _headers;
  Object? get body => _body;

  bool get hasHijacked => _hijacker != null;

  Response();

  Response status(int statusCode) {
    _statusCode = statusCode;
    return this;
  }

  /// The content-type will automatically be resolved by the `ResponseTypeResolver`
  Response any(dynamic body) {
    if (body is Response) {
      return body;
    }

    _body = body;
    autoResolveResponseType = true;

    return this;
  }

  Response header(String name, Object value) {
    _headers[name] = value;
    return this;
  }

  Response addHeaders(Map<String, Object> headers) {
    _headers = {..._headers, ...headers};
    return this;
  }

  /// Sets the content-type header to application/json
  Response json(dynamic body) {
    _body = convert.json.encode(body);
    header('content-type', 'application/json; charset=utf-8');
    return this;
  }

  /// Sends a json response with a message property
  /// ```json
  /// {
  ///   "message": "the message"
  /// }
  /// ```
  Response message(String message) => json({'message': message});

  /// Sets the content-type header to text/html
  Response html(String html) {
    _body = html;
    header('content-type', 'text/html; charset=utf-8');
    return this;
  }

  Response text(String text) {
    _body = text;
    header('content-type', 'text/plain; charset=utf-8');
    return this;
  }

  Response setBody(dynamic body) {
    _body = body;

    return this;
  }

  Response redirect(String url, [int statusCode = HttpStatus.found]) {
    _statusCode = statusCode;
    header('Location', url);
    return this;
  }

  Response cookie(
    String name,
    String value, {
    bool httpOnly = true,
    bool secure = true,
    String path = '/',
    String? domain,
    DateTime? expires,
    Duration? maxAge,
    SameSite? sameSite,
  }) {
    cookies.add(
      LunartCookie(
        name: name,
        value: value,
        httpOnly: httpOnly,
        secure: secure,
        domain: domain,
        path: path,
        expires: expires,
        maxAge: maxAge,
        sameSite: sameSite,
      ),
    );
    return this;
  }

  Response signedCookie(
    String name,
    String value, {
    bool httpOnly = true,
    bool secure = true,
    String path = '/',
    String? domain,
    DateTime? expires,
    Duration? maxAge,
    SameSite? sameSite,
  }) {
    cookies.add(
      LunartCookie(
        name: name,
        value: value,
        httpOnly: httpOnly,
        secure: secure,
        domain: domain,
        path: path,
        expires: expires,
        maxAge: maxAge,
        sameSite: sameSite,
        signed: true,
      ),
    );

    return this;
  }

  Response removeCookie(String name) {
    cookies.add(
      LunartCookie(name: name, value: '', maxAge: Duration(seconds: 0)),
    );
    return this;
  }

  /// Hijacks the response.
  /// The hijacker is responsible to write and close the http response
  Response hijack(void Function(HttpResponse, Response) hijacker) {
    _hijacker = hijacker;
    return this;
  }

  // Response streamEvent(void Function(sse.SSEStream) cb) =>
  // sse.streamEvent(cb, this);

  Response stream(Stream stream) {
    _body = stream;

    return this;
  }

  Response streamText(Stream<String> stream) {
    _body = stream;
    bufferResponse = false;

    return this;
  }

  Future<Response> file(File file) async {
    header(
      'Content-Type',
      await getMimeType(file) ?? 'application/octet-stream',
    );

    return stream(file.openRead());
  }

  Response notFound() => status(HttpStatus.notFound);

  Response ok() => status(HttpStatus.ok);

  Response created() => status(HttpStatus.ok);

  Response internalServerError() => status(HttpStatus.internalServerError);

  Response forbidden() => status(HttpStatus.forbidden);

  Response unauthorized() => status(HttpStatus.unauthorized);

  Response badRequest() => status(HttpStatus.badRequest);

  Response noContent() => status(HttpStatus.noContent);

  Response mergeResponse(Response other) {
    _body = other._body;
    _statusCode = other._statusCode;
    _headers = {..._headers, ...other._headers};
    _hijacker = other._hijacker;
    cookies = [...cookies, ...other.cookies];
    autoResolveResponseType = other.autoResolveResponseType;

    return this;
  }
}

// ignore: non_constant_identifier_names
Response get Res => Response();
