import 'dart:io';
import 'dart:convert' as convert;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:mime/mime.dart';

import 'enums/method.dart';
import 'exceptions/exception.dart';
import 'exceptions/bad_request_exception.dart';

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
  final Map<String, String> headers;
  final Map<String, String> queries;
  late final String routerPath;
  Map<String, dynamic> context = {};
  Map<String, dynamic> parameters = {};
  Future<String?> Function(String, {Duration? maxAge})? signedCookieParser;
  Object? _parsedBody;

  List<Cookie> get cookies => nativeRequest.cookies;

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
        message: 'Signed cookie parser not set. Have you added `signedCookie` middleware?',
      );
    }
    final cookie = getCookie(name);

    if (cookie == null) return null;

    final value = await signedCookieParser!(cookie, maxAge: maxAge);

    if (value == null) return null;

    return Uri.decodeQueryComponent(value);
  }

  /// # Get raw body bytes
  /// ```dart
  /// final data = await req.bytes();
  /// ```
  Future<List<Uint8List>> bytes() async {
    final chunks = <Uint8List>[];

    await for (final chunk in nativeRequest) {
      chunks.add(chunk);
    }

    return chunks;
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
      final contentType = nativeRequest.headers.contentType;
      if (contentType == null) return null;

      if (contentType.mimeType == 'application/json') {
        final rawBody = await convert.utf8.decodeStream(nativeRequest);
        return convert.json.decode(rawBody);
      }

      if (contentType.mimeType == 'application/x-www-form-urlencoded') {
        final rawBody = await convert.utf8.decodeStream(nativeRequest);
        return _parseUrlEncodedForm(rawBody);
      }

      if (contentType.mimeType == 'multipart/form-data') {
        return await _parseMultiPartForm(nativeRequest);
      }

      if (contentType.mimeType == 'text/plain') {
        return await convert.utf8.decodeStream(nativeRequest);
      }
    } catch (e, stacktrace) {
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

  Future<Map<String, Object>?> _parseMultiPartForm(HttpRequest request) async {
    final body = <String, Object>{};
    final boundary = request.headers.contentType!.parameters['boundary'];

    if (boundary == null) return null;

    final transformer = MimeMultipartTransformer(boundary);
    final parts = await transformer.bind(request).toList();

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
