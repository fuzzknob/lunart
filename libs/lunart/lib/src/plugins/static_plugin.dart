import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import '../interfaces/plugin.dart';
import '../enums/method.dart';
import '../exceptions/exception.dart';
import '../exceptions/not_found_exception.dart';
import '../exceptions/bad_request_exception.dart';
import '../lunart.dart';
import '../types.dart';
import '../request.dart';
import '../response.dart';
import '../utils.dart';

class StaticPlugin implements Plugin {
  StaticPlugin({
    this.path = './public',
    this.route = '/public/*',
    this.middlewares = const [],
    this.serveIndexHtml = true,
    this.isPublic = true,
    this.headers = const {},
    this.etags = true,
    this.maxAge,
    this.verifyPath,
    this.onNotFound,
    this.onFound,
    this.onInvalid,
  });

  final String path;
  final String route;
  final List<Middleware> middlewares;
  final bool serveIndexHtml;
  final bool isPublic;
  final Map<String, String> headers;
  final bool etags;
  final Duration? maxAge;
  final FutureOr<bool> Function(String path)? verifyPath;
  final Future<Object?> Function(String path)? onNotFound;
  final Future<Object?> Function(String path, File file)? onFound;
  final Future<Object?> Function(String path)? onInvalid;

  bool _isRootPathDirectory = true;
  File? _singleServeFile;

  @override
  void plug(Lunart app) {
    final fsEntity = FileSystemEntity.typeSync(path);

    if (fsEntity == FileSystemEntityType.notFound) {
      throw LunartException(message: '[ServeStatic] $path not found');
    }

    _isRootPathDirectory = fsEntity == FileSystemEntityType.directory;

    _singleServeFile = _isRootPathDirectory ? null : File(path);

    app.group(
      (router) {
        router.head('/', handleRequest);
        router.options('/', handleRequest);
        router.get('/', handleRequest);
      },
      prefix: route,
      middlewares: middlewares,
    );
  }

  Future<Object?> handleRequest(Request req) async {
    File? targetFile = _singleServeFile;
    var targetFilePath = path;

    if (_isRootPathDirectory) {
      final requestPath = req.path;

      final routerPath = req.routerPath.endsWith('/*')
          ? req.routerPath.substring(0, req.routerPath.length - 2)
          : req.routerPath;

      final relativePath = trimSlashes(
        requestPath.replaceFirst(routerPath, ''),
      );

      final isPathValid = await _validateRequestPath(relativePath);

      if (!isPathValid) {
        return _handleInvalid(requestPath);
      }

      targetFilePath = '$path/$relativePath';

      if (verifyPath != null && !(await verifyPath!(targetFilePath))) {
        return _handleNotFound(targetFilePath);
      }

      final fileEntity = await FileSystemEntity.type(targetFilePath);

      if (fileEntity == FileSystemEntityType.notFound) {
        return _handleNotFound(targetFilePath);
      }

      if (fileEntity == FileSystemEntityType.directory && serveIndexHtml) {
        targetFile = File('$targetFilePath/index.html');
      } else if (fileEntity == FileSystemEntityType.file) {
        targetFile = File(targetFilePath);
      }
    }

    if (targetFile == null || !await targetFile.exists()) {
      return _handleNotFound(targetFilePath);
    }

    final customResponse = await onFound?.call(targetFilePath, targetFile);

    if (customResponse != null) {
      return customResponse;
    }

    final contentType =
        await getMimeType(targetFile) ?? 'application/octet-stream';
    final response = Res.addHeaders(headers)
        .header('Content-Type', contentType);
    final fileStat = await targetFile.stat();

    if (etags) {
      final fileEtag = await generateWeakEtags(targetFile, fileStat);

      if (_isClientCacheValid(req.headers, fileEtag, fileStat)) {
        return response.status(304);
      }

      response.header('etag', fileEtag);
    }

    final directive = isPublic ? 'public' : 'private';

    response
        .header(
          'cache-control',
          maxAge != null
              ? '$directive, max-age=${maxAge!.inSeconds}'
              : directive,
        )
        .header('last-modified', HttpDate.format(fileStat.modified.toUtc()));

    final rangeHeader = req.headers['range'];
    final isHeadOrOptionRequest =
        req.method == Method.head || req.method == Method.options;

    if (rangeHeader != null && rangeHeader.isNotEmpty) {
      response.header('accept-ranges', 'bytes');

      final ranges = _parseRangeHeader(rangeHeader);

      // For now we only accept the first range
      // TODO: Decide if we want to support multiple ranges
      final range = ranges?.firstOrNull;

      final byteRange = range != null
          ? _resolveByteRange(range, fileStat.size)
          : null;

      if (byteRange == null) {
        return response
            .status(416)
            .header('content-range', 'bytes */${fileStat.size}');
      }

      response.status(206);
      response.header(
        'content-range',
        'bytes ${byteRange.start}-${byteRange.end}/${fileStat.size}',
      );

      if (isHeadOrOptionRequest) {
        return response;
      }

      return response.stream(
        targetFile.openRead(byteRange.start, byteRange.end + 1),
      );
    }

    if (isHeadOrOptionRequest) {
      return response;
    }

    return response
        .header('content-length', fileStat.size)
        .stream(targetFile.openRead());
  }

  ({int start, int end})? _resolveByteRange((int?, int?) range, int fileSize) {
    var (start, end) = range;

    if (start == null && end == null) {
      return null;
    }

    // if range is a suffix eg: (-50)
    if (start == null) {
      return (start: math.max(0, (fileSize - end!)), end: fileSize - 1);
    }

    end = end == null ? fileSize - 1 : math.min(end, fileSize - 1);

    if (start > end) {
      return null;
    }

    return (start: start, end: end);
  }

  List<(int?, int?)>? _parseRangeHeader(String header) {
    final normalized = header.trim();

    final headerRegex = RegExp(
      r'^bytes=(?:\d+-\d*|-\d+)(?:\s*,\s*(?:\d+-\d*|-\d+))*$',
    );

    if (!headerRegex.hasMatch(normalized)) {
      return null;
    }

    final rangePattern = RegExp(
      r'^(?<start>\d+)-(?<end>\d*)|-(?<end>\d+)$',
    );

    // Parsing multiple ranges
    final rangeParts = normalized
        .replaceFirst(RegExp(r'^bytes='), '')
        .split(',');

    final ranges = <(int?, int?)>[];

    for (final part in rangeParts) {
      final match = rangePattern.firstMatch(part.trim());

      if (match == null) continue;

      final start = match.namedGroup('start') ?? '';
      final end = match.namedGroup('end') ?? '';

      ranges.add((int.tryParse(start), int.tryParse(end)));
    }

    return ranges;
  }

  Future<Object?> _handleNotFound(String filePath) async {
    final response = await onNotFound?.call(filePath);
    if (response != null) {
      return response;
    }

    throw NotFoundException(message: 'File not found: $filePath');
  }

  Future<Object?> _handleInvalid(String filePath) async {
    final response = await onInvalid?.call(filePath);
    if (response != null) {
      return response;
    }

    throw BadRequestException(message: 'Invalid file path: $filePath');
  }

  Future<bool> _validateRequestPath(String targetFilePath) async {
    // check for null bytes
    if (targetFilePath.contains('\x00')) {
      return false;
    }

    // No non-canonical/unsafe path input: "." or ".." segments, consecutive slashes/backslashes, or any backslash.
    return !RegExp(r'(?:^|[\/\\])\.{1,2}(?:$|[\/\\])|[\/\\]{2,}|\\')
        .hasMatch(targetFilePath);
  }

  bool _isClientCacheValid(
    Map<String, String> headers,
    String fileEtag,
    FileStat fileStat,
  ) {
    final cacheControl = headers['cache-control'] ?? '';

    if (RegExp(r'no-cache|no-store').hasMatch(cacheControl)) {
      return false;
    }

    final ifNoneMatch = headers['if-none-match'];

    if (ifNoneMatch != null) {
      if (ifNoneMatch == '*') {
        return true;
      }

      final clientEtags = ifNoneMatch.split(',').map((e) => e.trim());

      if (clientEtags.contains(fileEtag)) {
        return true;
      }

      return false;
    }

    final ifModifiedSince = headers['if-modified-since'];

    if (ifModifiedSince != null) {
      try {
        final clientDate = HttpDate.parse(ifModifiedSince);

        final fileModified = fileStat.modified.toUtc();
        final truncated = DateTime.utc(
          fileModified.year,
          fileModified.month,
          fileModified.day,
          fileModified.hour,
          fileModified.minute,
          fileModified.second,
        );

        return !truncated.isAfter(clientDate);
      } catch (_) {
        return false;
      }
    }

    return false;
  }
}
