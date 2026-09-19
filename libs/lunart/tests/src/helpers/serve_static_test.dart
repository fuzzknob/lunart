import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:lunart/src/enums/method.dart';
import 'package:lunart/src/exceptions/bad_request_exception.dart';
import 'package:lunart/src/exceptions/exception.dart';
import 'package:lunart/src/exceptions/method_not_allowed_exception.dart';
import 'package:lunart/src/exceptions/not_found_exception.dart';
import 'package:lunart/src/helpers/serve_static.dart';
import 'package:lunart/src/request.dart';
import 'package:lunart/src/response.dart';

class _MockHttpRequest extends Mock implements HttpRequest {}

Request _buildRequest({
  required String path,
  required Method method,
  required String routerPath,
  Map<String, String> headers = const {},
}) {
  final request = Request(
    nativeRequest: _MockHttpRequest(),
    path: path,
    method: method,
    headers: headers,
    queries: const {},
  );
  request.routerPath = routerPath;

  return request;
}

void main() {
  group('serveStatic', () {
    test('throws LunartException when root path does not exist', () {
      expect(
        () => serveStatic(path: '/tmp/lunart-missing-path-never-exists'),
        throwsA(isA<LunartException>()),
      );
    });

    test(
      'throws MethodNotAllowedException for non GET/HEAD requests',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('lunart-static-');
        try {
          final handler = serveStatic(path: tempDir.path);
          final request = _buildRequest(
            path: '/assets/file.txt',
            method: Method.post,
            routerPath: '/assets/*',
          );

          await expectLater(
            () => handler(request),
            throwsA(isA<MethodNotAllowedException>()),
          );
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );

    test(
      'serves configured single file and sets cache metadata headers',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('lunart-static');
        final file = File('${tempDir.path}/hello.txt');
        await file.writeAsString('hello');

        try {
          final handler = serveStatic(path: file.path, etags: false);
          final request = _buildRequest(
            path: '/ignored',
            method: Method.get,
            routerPath: '/ignored',
          );

          final result = await handler(request) as Response;

          expect(result.body, isA<Stream>());
          expect(result.headers['cache-control'], 'public');
          expect(result.headers['last-modified'], isNotNull);
          expect(result.headers['content-length'], 5);
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );

    test(
      'serves directory index.html when target path is a directory',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('lunart-static-');
        final nestedDir = Directory('${tempDir.path}/docs');
        await nestedDir.create(recursive: true);
        await File('${nestedDir.path}/index.html')
            .writeAsString('<h1>Docs</h1>');

        try {
          final handler = serveStatic(path: tempDir.path, etags: false);
          final request = _buildRequest(
            path: '/assets/docs',
            method: Method.get,
            routerPath: '/assets/*',
          );

          final result = await handler(request) as Response;

          expect(result.body, isA<Stream>());
          expect(result.headers['content-length'], 13);
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );

    test('throws NotFoundException for missing file by default', () async {
      final tempDir = await Directory.systemTemp.createTemp('lunart-static-');
      try {
        final handler = serveStatic(path: tempDir.path);
        final request = _buildRequest(
          path: '/assets/missing.txt',
          method: Method.get,
          routerPath: '/assets/*',
        );

        await expectLater(
          () => handler(request),
          throwsA(isA<NotFoundException>()),
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('rejects unsafe traversal-like request paths', () async {
      final tempDir = await Directory.systemTemp.createTemp('lunart-static-');
      try {
        final handler = serveStatic(path: tempDir.path);
        final request = _buildRequest(
          path: '/assets/../secret.txt',
          method: Method.get,
          routerPath: '/assets/*',
        );

        await expectLater(
          () => handler(request),
          throwsA(isA<BadRequestException>()),
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns not found when verifyPath denies access', () async {
      final tempDir = await Directory.systemTemp.createTemp('lunart-static-');
      await File('${tempDir.path}/visible.txt').writeAsString('visible');

      try {
        final handler = serveStatic(
          path: tempDir.path,
          verifyPath: (_) async => false,
        );
        final request = _buildRequest(
          path: '/assets/visible.txt',
          method: Method.get,
          routerPath: '/assets/*',
        );

        await expectLater(
          () => handler(request),
          throwsA(isA<NotFoundException>()),
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('uses onNotFound override when file is missing', () async {
      final tempDir = await Directory.systemTemp.createTemp('lunart-static-');
      try {
        final handler = serveStatic(
          path: tempDir.path,
          onNotFound: (filePath) async => 'missing:$filePath',
        );
        final request = _buildRequest(
          path: '/assets/none.txt',
          method: Method.get,
          routerPath: '/assets/*',
        );

        final result = await handler(request);

        expect(result, contains('missing:'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('uses onInvalid override for invalid path', () async {
      final tempDir = await Directory.systemTemp.createTemp('lunart-static-');
      try {
        final handler = serveStatic(
          path: tempDir.path,
          onInvalid: (filePath) async => 'invalid:$filePath',
        );
        final request = _buildRequest(
          path: '/assets/../oops.txt',
          method: Method.get,
          routerPath: '/assets/*',
        );

        final result = await handler(request);

        expect(result, 'invalid:/assets/../oops.txt');
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('uses onFound override instead of default file response', () async {
      final tempDir = await Directory.systemTemp.createTemp('lunart-static-');
      await File('${tempDir.path}/note.txt').writeAsString('hello');

      try {
        final handler = serveStatic(
          path: tempDir.path,
          onFound: (filePath, file) async =>
              'found:$filePath:${await file.exists()}',
        );
        final request = _buildRequest(
          path: '/assets/note.txt',
          method: Method.get,
          routerPath: '/assets/*',
        );

        final result = await handler(request);

        expect(result, contains('found:'));
        expect(result, contains(':true'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns 304 when if-none-match matches generated etag', () async {
      final tempDir = await Directory.systemTemp.createTemp('lunart-static-');
      await File('${tempDir.path}/etag.txt').writeAsString('etag-data');

      try {
        final handler = serveStatic(path: tempDir.path, etags: true);
        final firstRequest = _buildRequest(
          path: '/assets/etag.txt',
          method: Method.get,
          routerPath: '/assets/*',
        );

        final firstResponse = await handler(firstRequest) as Response;
        final etag = firstResponse.headers['etag'] as String;

        final secondRequest = _buildRequest(
          path: '/assets/etag.txt',
          method: Method.get,
          routerPath: '/assets/*',
          headers: {'if-none-match': etag},
        );

        final secondResponse = await handler(secondRequest) as Response;

        expect(secondResponse.statusCode, HttpStatus.notModified);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'head request returns metadata response without streaming file body',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('lunart-static-');
        await File('${tempDir.path}/head.txt').writeAsString('head-data');

        try {
          final handler = serveStatic(path: tempDir.path, etags: false);
          final request = _buildRequest(
            path: '/assets/head.txt',
            method: Method.head,
            routerPath: '/assets/*',
          );

          final response = await handler(request) as Response;

          expect(response.statusCode, HttpStatus.ok);
          expect(response.body, '');
          expect(response.headers['content-length'], 9);
          expect(response.headers.containsKey('Content-Type'), isFalse);
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );
  });
}
