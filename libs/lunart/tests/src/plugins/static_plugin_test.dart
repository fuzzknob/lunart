import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:lunart/src/enums/method.dart';
import 'package:lunart/src/exceptions/bad_request_exception.dart';
import 'package:lunart/src/exceptions/exception.dart';
import 'package:lunart/src/exceptions/not_found_exception.dart';
import 'package:lunart/src/lunart.dart';
import 'package:lunart/src/plugins/static_plugin.dart';
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
  group('StaticPlugin', () {
    test('plug throws LunartException when root path does not exist', () {
      final app = Lunart(barebones: true);
      final plugin = StaticPlugin(
        path: '/tmp/lunart-missing-path-never-exists',
      );

      expect(
        () => plugin.plug(app),
        throwsA(isA<LunartException>()),
      );
    });

    test(
      'plug registers GET/HEAD/OPTIONS handlers for configured route',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'lunart-static-plugin-',
        );
        try {
          final app = Lunart(barebones: true);
          final plugin = StaticPlugin(path: tempDir.path, route: '/assets/*');

          plugin.plug(app);

          expect(
            app.router.routesMap.containsKey('${Method.get}@/assets/*'),
            isTrue,
          );
          expect(
            app.router.routesMap.containsKey('${Method.head}@/assets/*'),
            isTrue,
          );
          expect(
            app.router.routesMap.containsKey('${Method.options}@/assets/*'),
            isTrue,
          );
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );

    test(
      'serves configured single file',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'lunart-static-plugin-',
        );
        final file = File('${tempDir.path}/hello.txt');
        await file.writeAsString('hello');

        try {
          final app = Lunart(barebones: true);
          final plugin = StaticPlugin(
            path: file.path,
            route: '/assets/*',
          );
          plugin.plug(app);

          final request = _buildRequest(
            path: '/assets/ignored',
            method: Method.get,
            routerPath: '/assets/*',
          );

          final response = await plugin.handleRequest(request) as Response;

          expect(response.body, isA<Stream>());
          expect(response.headers['cache-control'], 'public');
          expect(response.headers['last-modified'], isNotNull);
          expect(response.headers['content-length'], 5);
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );

    test('serves index.html when resolved target is a directory', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'lunart-static-plugin-',
      );
      final docsDir = Directory('${tempDir.path}/docs');
      await docsDir.create(recursive: true);
      await File('${docsDir.path}/index.html').writeAsString('<h1>Docs</h1>');

      try {
        final app = Lunart(barebones: true);
        final plugin = StaticPlugin(
          path: tempDir.path,
          route: '/assets/*',
          etags: false,
        );
        plugin.plug(app);

        final request = _buildRequest(
          path: '/assets/docs',
          method: Method.get,
          routerPath: '/assets/*',
        );

        final response = await plugin.handleRequest(request) as Response;

        expect(response.body, isA<Stream>());
        expect(response.headers['content-length'], 13);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('throws NotFoundException when file is missing', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'lunart-static-plugin-',
      );
      try {
        final app = Lunart(barebones: true);
        final plugin = StaticPlugin(path: tempDir.path, route: '/assets/*');
        plugin.plug(app);

        final request = _buildRequest(
          path: '/assets/missing.txt',
          method: Method.get,
          routerPath: '/assets/*',
        );

        await expectLater(
          () => plugin.handleRequest(request),
          throwsA(isA<NotFoundException>()),
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'throws BadRequestException for unsafe path traversal input',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'lunart-static-plugin-',
        );
        try {
          final app = Lunart(barebones: true);
          final plugin = StaticPlugin(path: tempDir.path, route: '/assets/*');
          plugin.plug(app);

          final request = _buildRequest(
            path: '/assets/../secret.txt',
            method: Method.get,
            routerPath: '/assets/*',
          );

          await expectLater(
            () => plugin.handleRequest(request),
            throwsA(isA<BadRequestException>()),
          );
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );

    test('returns NotFoundException when verifyPath returns false', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'lunart-static-plugin-',
      );
      await File('${tempDir.path}/visible.txt').writeAsString('visible');

      try {
        final app = Lunart(barebones: true);
        final plugin = StaticPlugin(
          path: tempDir.path,
          route: '/assets/*',
          verifyPath: (_) async => false,
        );
        plugin.plug(app);

        final request = _buildRequest(
          path: '/assets/visible.txt',
          method: Method.get,
          routerPath: '/assets/*',
        );

        await expectLater(
          () => plugin.handleRequest(request),
          throwsA(isA<NotFoundException>()),
        );
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('uses onNotFound override when file does not exist', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'lunart-static-plugin-',
      );
      try {
        final app = Lunart(barebones: true);
        final plugin = StaticPlugin(
          path: tempDir.path,
          route: '/assets/*',
          onNotFound: (filePath) async => 'missing:$filePath',
        );
        plugin.plug(app);

        final request = _buildRequest(
          path: '/assets/none.txt',
          method: Method.get,
          routerPath: '/assets/*',
        );

        final result = await plugin.handleRequest(request);

        expect(result, contains('missing:'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('uses onInvalid override for invalid request path', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'lunart-static-plugin-',
      );
      try {
        final app = Lunart(barebones: true);
        final plugin = StaticPlugin(
          path: tempDir.path,
          route: '/assets/*',
          onInvalid: (filePath) async => 'invalid:$filePath',
        );
        plugin.plug(app);

        final request = _buildRequest(
          path: '/assets/../oops.txt',
          method: Method.get,
          routerPath: '/assets/*',
        );

        final result = await plugin.handleRequest(request);

        expect(result, 'invalid:/assets/../oops.txt');
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('uses onFound override for existing file', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'lunart-static-plugin-',
      );
      await File('${tempDir.path}/note.txt').writeAsString('hello');

      try {
        final app = Lunart(barebones: true);
        final plugin = StaticPlugin(
          path: tempDir.path,
          route: '/assets/*',
          onFound: (filePath, file) async =>
              'found:$filePath:${await file.exists()}',
        );
        plugin.plug(app);

        final request = _buildRequest(
          path: '/assets/note.txt',
          method: Method.get,
          routerPath: '/assets/*',
        );

        final result = await plugin.handleRequest(request);

        expect(result, contains('found:'));
        expect(result, contains(':true'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns 304 when if-none-match equals generated etag', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'lunart-static-plugin-',
      );

      await File('${tempDir.path}/etag.txt').writeAsString('etag-data');

      try {
        final app = Lunart(barebones: true);
        final plugin = StaticPlugin(
          path: tempDir.path,
          route: '/assets/*',
          etags: true,
        );
        plugin.plug(app);

        final firstRequest = _buildRequest(
          path: '/assets/etag.txt',
          method: Method.get,
          routerPath: '/assets/*',
        );

        final firstResponse =
            await plugin.handleRequest(firstRequest) as Response;
        final etag = firstResponse.headers['etag'] as String;

        final secondRequest = _buildRequest(
          path: '/assets/etag.txt',
          method: Method.get,
          routerPath: '/assets/*',
          headers: {'if-none-match': etag},
        );

        final secondResponse =
            await plugin.handleRequest(secondRequest) as Response;

        expect(secondResponse.statusCode, HttpStatus.notModified);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'head request returns metadata response without stream body',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'lunart-static-plugin-',
        );
        await File('${tempDir.path}/head.txt').writeAsString('head-data');

        try {
          final app = Lunart(barebones: true);
          final plugin = StaticPlugin(
            path: tempDir.path,
            route: '/assets/*',
            etags: false,
          );
          plugin.plug(app);

          final request = _buildRequest(
            path: '/assets/head.txt',
            method: Method.head,
            routerPath: '/assets/*',
          );

          final response = await plugin.handleRequest(request) as Response;

          expect(response.statusCode, HttpStatus.ok);
          expect(response.body, '');
          expect(response.headers['Content-Type'], isNotNull);
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );

    test(
      'options request returns metadata response without stream body',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'lunart-static-plugin-',
        );
        await File('${tempDir.path}/options.txt').writeAsString('options-data');

        try {
          final app = Lunart(barebones: true);
          final plugin = StaticPlugin(
            path: tempDir.path,
            route: '/assets/*',
            etags: false,
          );
          plugin.plug(app);

          final request = _buildRequest(
            path: '/assets/options.txt',
            method: Method.options,
            routerPath: '/assets/*',
          );

          final response = await plugin.handleRequest(request) as Response;

          expect(response.statusCode, HttpStatus.ok);
          expect(response.body, '');
          expect(response.headers['Content-Type'], isNotNull);
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );

    test('valid byte range returns 206 with correct content-range', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'lunart-static-plugin-',
      );
      await File('${tempDir.path}/range.txt').writeAsString('abcdefgh');

      try {
        final app = Lunart(barebones: true);
        final plugin = StaticPlugin(
          path: tempDir.path,
          route: '/assets/*',
          etags: false,
        );
        plugin.plug(app);

        final request = _buildRequest(
          path: '/assets/range.txt',
          method: Method.get,
          routerPath: '/assets/*',
          headers: {'range': 'bytes=0-3'},
        );

        final response = await plugin.handleRequest(request) as Response;

        expect(response.statusCode, HttpStatus.partialContent);
        expect(response.headers['content-range'], 'bytes 0-3/8');
        expect(response.body, isA<Stream>());
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'invalid byte range returns 416 with unsatisfied content-range',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'lunart-static-plugin-',
        );
        await File('${tempDir.path}/range-invalid.txt')
            .writeAsString('abcdefgh');

        try {
          final app = Lunart(barebones: true);
          final plugin = StaticPlugin(
            path: tempDir.path,
            route: '/assets/*',
            etags: false,
          );
          plugin.plug(app);

          final request = _buildRequest(
            path: '/assets/range-invalid.txt',
            method: Method.get,
            routerPath: '/assets/*',
            headers: {'range': 'bytes=99-120'},
          );

          final response = await plugin.handleRequest(request) as Response;

          expect(response.statusCode, HttpStatus.requestedRangeNotSatisfiable);
          expect(response.headers['content-range'], 'bytes */8');
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );
  });
}
