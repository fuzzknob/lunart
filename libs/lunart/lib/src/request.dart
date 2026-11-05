import 'dart:io';
import 'dart:convert' as convert;
import 'dart:typed_data';

import 'package:mime/mime.dart';

import 'exceptions/exception.dart';
import 'exceptions/bad_request_exception.dart';
import 'enums/method.dart';
import 'cookie.dart';

class Request {
  Request({
    required this.path,
    required this.method,
    required this._headers,
    required this._queries,
    required this._cookies,
    required this._getRawBody,
    this._contentType,
    this.connectionInfo,
    this.certificate,
  });

  final String path;
  final Method method;
  final HttpConnectionInfo? connectionInfo;
  final X509Certificate? certificate;

  late final String routerPath;

  final Map<String, String> _headers;
  final Map<String, LunartCookie> _cookies;
  final Map<String, String> _queries;
  final Future<Uint8List> Function() _getRawBody;
  final ContentType? _contentType;

  Map<String, String> _parameters = {};
  final Map<Object?, dynamic> _context = {};

  Future<String?> Function(String, {Duration? maxAge})? _signedCookieParser;

  Uint8List? _bodyBytes;
  Object? _parsedBody;

  bool get secure {
    if (certificate != null) {
      return true;
    }

    return header('x-forwarded-proto')?.toLowerCase() == 'https';
  }

  String? header(String name) {
    return _headers[name.toLowerCase()];
  }

  Map<String, String> allHeaders() {
    return _headers;
  }

  String? cookie(String name) {
    final lunartCookie = _cookies[name.toLowerCase()];

    if (lunartCookie == null) return null;
    if (lunartCookie.expires != null &&
        lunartCookie.expires!.millisecondsSinceEpoch <
            DateTime.now().millisecondsSinceEpoch) {
      return null;
    }

    return lunartCookie.value;
  }

  Future<String?> signedCookie(String name, {Duration? maxAge}) async {
    if (_signedCookieParser == null) {
      throw LunartException(
        message: 'Signed cookie parser not set. Have you added `signedCookie` middleware?',
      );
    }
    final cookie = this.cookie(name);

    if (cookie == null) return null;

    final value = await _signedCookieParser!(cookie, maxAge: maxAge);

    if (value == null) return null;

    return Uri.decodeQueryComponent(value);
  }

  Map<String, String> allCookies() {
    final cookieMap = <String, String>{};

    for (final cookie in _cookies.values) {
      cookieMap[cookie.name] = cookie.value;
    }

    return cookieMap;
  }

  LunartCookie? lunartCookie(String name) {
    return _cookies[name];
  }

  Map<String, LunartCookie> allLunartCookies() {
    return _cookies;
  }

  void setSignedCookieParser(
    Future<String?> Function(String, {Duration? maxAge})? parser,
  ) {
    _signedCookieParser = parser;
  }

  String? query(String name) {
    return _queries[name];
  }

  Map<String, String> allQueries() {
    return _queries;
  }

  String? param(String name) {
    return _parameters[name];
  }

  Map<String, dynamic> allParams() {
    return _parameters;
  }

  void setParams(Map<String, String> parameters) {
    _parameters = parameters;
  }

  T context<T>([String? name]) {
    if (name != null) {
      return _context[name];
    }

    return _context[T];
  }

  void setContext<T>(
    Object? nameOrValue, [
    Object? value = 'LUNART-CONTEXT-DEFAULT-VALUE', // So that null value can be set for context
  ]) {
    if (value != 'LUNART-CONTEXT-DEFAULT-VALUE') {
      _context[nameOrValue] = value;

      return;
    }

    _context[T] = nameOrValue;
  }

  /// # Get raw body bytes
  /// ```dart
  /// final data = await req.rawBody();
  /// ```
  Future<Uint8List> rawBody() async {
    if (_bodyBytes != null) return _bodyBytes!;

    _bodyBytes = await _getRawBody();

    return _bodyBytes!;
  }

  /// # Parses body according to the content-type
  /// ```dart
  /// final data = await req.body();
  /// ```
  Future<T?> body<T>() async {
    if (_parsedBody != null) {
      return _parsedBody as T?;
    }

    return _parsedBody = await _parseMappableBody() as T?;
  }

  Future<Object?> _parseMappableBody() async {
    try {
      var contentType = _contentType;

      if (contentType == null) {
        final rawContentType = header('content-type');

        if (rawContentType == null) {
          return null;
        }

        contentType = ContentType.parse(rawContentType);
      }

      final mimeType = contentType.mimeType;
      final bodyBytes = await rawBody();

      if (bodyBytes.isEmpty) return null;

      if (mimeType == 'application/json') {
        final rawBody = convert.utf8.decode(bodyBytes);

        return convert.json.decode(rawBody);
      }

      if (mimeType == 'application/x-www-form-urlencoded') {
        final rawBody = convert.utf8.decode(bodyBytes);

        return _parseUrlEncodedForm(rawBody);
      }

      if (mimeType == 'multipart/form-data') {
        return await _parseMultiPartForm(bodyBytes, contentType);
      }

      if (mimeType == 'text/plain') {
        return convert.utf8.decode(bodyBytes);
      }
    } catch (e, stacktrace) {
      print(e);
      print(stacktrace);

      throw BadRequestException(
        message: 'The request cannot be processed',
        error: e,
        stackTrace: stacktrace,
      );
    }

    return null;
  }

  Map<String, String> _parseUrlEncodedForm(String rawBody) {
    final fields = <String, String>{};

    for (final section in rawBody.split('&')) {
      final field = section.split('=');

      if (field.isEmpty) continue;

      final name = Uri.decodeQueryComponent(field[0]);
      final value = field.length > 1 ? Uri.decodeQueryComponent(field[1]) : '';

      fields[name] = value;
    }

    return fields;
  }

  Future<Map<String, Object>?> _parseMultiPartForm(
    Uint8List bytes,
    ContentType contentType,
  ) async {
    final body = <String, Object>{};

    final boundary = contentType.parameters['boundary'];

    if (boundary == null) return null;

    final byteStream = Stream.fromIterable(bytes.map((byte) => [byte]));

    final transformer = MimeMultipartTransformer(boundary);
    final parts = await transformer.bind(byteStream).toList();

    for (final part in parts) {
      final rawCD = part.headers['content-disposition'];

      if (rawCD == null) {
        continue;
      }

      final parameters = HeaderValue.parse(rawCD).parameters;
      final fieldName = parameters['name'];
      final filename = parameters['filename'];

      if (fieldName == null) continue;

      if (filename != null) {
        final contentType = part.headers['content-type'];
        final bytes = (await part.toList()).expand((b) => b).toList();

        body[fieldName] = MultipartFileUpload(
          name: filename,
          mime: contentType,
          bytes: bytes,
        );
        continue;
      }

      final fieldValue = await convert.utf8.decodeStream(part);

      body[fieldName] = fieldValue;
    }

    return body;
  }
}

class MultipartFileUpload({
  required final List<int> bytes,
  required final String name,
  final String? mime,
});
