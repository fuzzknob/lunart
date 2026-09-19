import 'dart:io';
import 'dart:async';

import '../exceptions/exception.dart';
import '../exceptions/not_found_exception.dart';
import '../exceptions/bad_request_exception.dart';
import '../exceptions/method_not_allowed_exception.dart';
import '../enums/method.dart';
import '../types.dart';
import '../request.dart';
import '../response.dart';
import '../utils.dart';

Handler serveStatic({
  String path = './public',
  bool serveIndexHtml = true,
  bool isPublic = true,
  Map<String, String> headers = const {},
  bool etags = true,
  Duration? maxAge,
  FutureOr<bool> Function(String path)? verifyPath,
  Future<Object?> Function(String path)? onNotFound,
  Future<Object?> Function(String path, File file)? onFound,
  Future<Object?> Function(String path)? onInvalid,
}) {
  final fsEntity = FileSystemEntity.typeSync(path);

  if (fsEntity == FileSystemEntityType.notFound) {
    throw LunartException(message: '[ServeStatic] $path not found');
  }

  final isRootPathDirectory = fsEntity == FileSystemEntityType.directory;

  final singleServeFile = isRootPathDirectory ? null : File(path);

  Future<Object?> handleNotFound(String filePath) async {
    final response = await onNotFound?.call(filePath);
    if (response != null) {
      return response;
    }

    throw NotFoundException(message: 'File not found: $filePath');
  }

  Future<Object?> handleInvalid(String filePath) async {
    final response = await onInvalid?.call(filePath);
    if (response != null) {
      return response;
    }

    throw BadRequestException(message: 'Invalid file path: $filePath');
  }

  return (Request req) async {
    if (![Method.get, Method.head].contains(req.method)) {
      throw MethodNotAllowedException();
    }

    File? targetFile = singleServeFile;
    var targetFilePath = path;

    if (isRootPathDirectory) {
      final requestPath = req.path;

      final routerPath = req.routerPath.endsWith('/*')
          ? req.routerPath.substring(0, req.routerPath.length - 2)
          : req.routerPath;

      final relativePath = trimSlashes(
        requestPath.replaceFirst(routerPath, ''),
      );

      final isPathValid = await _validateRequestPath(relativePath);

      if (!isPathValid) {
        return handleInvalid(requestPath);
      }

      targetFilePath = '$path/$relativePath';

      if (verifyPath != null && !(await verifyPath(targetFilePath))) {
        return handleNotFound(targetFilePath);
      }

      final fileEntity = await FileSystemEntity.type(targetFilePath);

      if (fileEntity == FileSystemEntityType.notFound) {
        return handleNotFound(targetFilePath);
      }

      if (fileEntity == FileSystemEntityType.directory && serveIndexHtml) {
        targetFile = File('$targetFilePath/index.html');
      } else if (fileEntity == FileSystemEntityType.file) {
        targetFile = File(targetFilePath);
      }
    }

    if (targetFile == null || !await targetFile.exists()) {
      return handleNotFound(targetFilePath);
    }

    final customResponse = await onFound?.call(targetFilePath, targetFile);

    if (customResponse != null) {
      return customResponse;
    }

    final response = Res.addHeaders(headers);
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
              ? '$directive, max-age=${maxAge.inSeconds}'
              : directive,
        )
        .header('last-modified', HttpDate.format(fileStat.modified.toUtc()))
        .header('content-length', fileStat.size);

    if (req.method == .head) return response;

    return response.file(targetFile);
  };
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
