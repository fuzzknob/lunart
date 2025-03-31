import 'dart:io';
import 'dart:convert' as convert;

import 'cookie.dart';

class Response {
  int _statusCode = HttpStatus.ok;
  dynamic _body;
  Map<String, Object> _headers = {};
  List<LunartCookie> cookies = [];

  int get statusCode => _statusCode;
  Map<String, Object> get headers => _headers;
  dynamic get body => _body;

  Response status(int statusCode) {
    _statusCode = statusCode;
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

  Response json(dynamic body) {
    _body = convert.json.encode(body);
    _headers = {..._headers, 'content-type': 'application/json'};
    return this;
  }

  Response message(String message) => json({'message': message});

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
    String? domain,
    String? path,
    DateTime? expires,
    int? maxAge,
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
    String? domain,
    String? path,
    DateTime? expires,
    int? maxAge,
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
    cookies.add(LunartCookie(name: name, value: '', maxAge: 0));
    return this;
  }
}

Response res() => Response();
