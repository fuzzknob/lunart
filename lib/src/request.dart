import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:lunart/src/exceptions/lunart_exception.dart';

import 'method.dart';

class Request {
  Request({
    required this.nativeRequest,
    required this.path,
    required this.method,
    required this.headers,
    required this.queries,
  });

  final String path;
  final Method method;
  final HttpRequest nativeRequest;
  final Map<String, List<String>> headers;
  final Map<String, String> queries;
  Map<String, dynamic> context = {};
  Map<String, dynamic> parameters = {};
  Future<String?> Function(String, {Duration? maxAge})? signedCookieParser;

  List<Cookie> get cookies =>
      nativeRequest.cookies.map((cookie) {
        cookie.name = Uri.decodeQueryComponent(cookie.name);
        cookie.value = Uri.decodeQueryComponent(cookie.value);
        return cookie;
      }).toList();

  String? getCookie(String name) {
    final cookie = cookies.firstWhereOrNull((cookie) => cookie.name == name);
    if (cookie == null) return null;
    if (cookie.expires != null &&
        cookie.expires!.millisecondsSinceEpoch <
            DateTime.now().millisecondsSinceEpoch) {
      return null;
    }
    return cookie.value;
  }

  Future<String?> getSignedCookie(String name, {Duration? maxAge}) async {
    if (signedCookieParser == null) {
      throw LunartException(
        message:
            'Signed cookie parser not set. Have you added `signedCookie` middleware?',
      );
    }
    final cookie = getCookie(name);
    if (cookie == null) return null;
    final value = await signedCookieParser!(cookie, maxAge: maxAge);
    if (value == null) return null;
    return Uri.decodeQueryComponent(value);
  }

  Future body() async {
    final contentType = nativeRequest.headers.contentType;
    if (contentType == null) return null;
    if (contentType.mimeType == 'application/json') {
      final content = await utf8.decodeStream(nativeRequest);
      return json.decode(content);
    }
  }
}
