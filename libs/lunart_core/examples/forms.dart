import 'dart:convert';

import 'package:lunart_core/lunart_core.dart';

const formsHTMLTemplate = '''
<!DOCTYPE html>
<html>
  <head>
    <title>Lunart forms</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.5/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-SgOJa3DmI69IUzQ2PVdRZhwQ+dy64/BUtbMJw1MZ8t5HZApcHrRKUc4W0kG879m7" crossorigin="anonymous">
  </head>
  <body>
    <main class="container mx-auto" style="width: 500px; margin-top: 100px;">
      <form class="mb-5" action="/post-urlencoded" method="post">
        <h3>Url encoded form</h3>
        <div class="mb-3">
          <label for="name" class="form-label">Name</label>
          <input class="form-control" type="text" id="name" name="name">
        </div>
        <div class="mb-3">
          <label for="email" class="form-label">Email</label>
          <input class="form-control" type="email" id="email" name="email">
        </div>
        <button class="btn btn-primary">Submit</button>
      </form>

      <form action="/post-multi-part" method="post" enctype="multipart/form-data">
        <h3>Multipart form</h3>
        <div class="mb-3">
          <label for="file-upload">Image</label>
          <input class="form-control" type="file" accept="image/*" id="file-upload" name="file-upload">
        </div>
        <button class="btn btn-primary">Submit</button>
      </form>
    </main>
  </body>
</html>
''';

void main() {
  final router = Router();

  router.get('/', (_) {
    return res().html(formsHTMLTemplate.trim());
  });

  // parses application/x-www-form-urlencoded
  router.post('/post-urlencoded', (req) async {
    final body = await req.body();
    return res().json(body);
  });

  // parses multipart/form-data
  router.post('/post-multi-part', (req) async {
    final body = await req.body();
    if (body == null) {
      return res().badRequest().text('Bad request');
    }
    final upload = body['file-upload'] as MultipartFileUpload?;
    if (upload == null) {
      return res().badRequest().text('No image to upload');
    }
    if (!upload.mime!.startsWith('image')) {
      return res().badRequest().text('Only images are supported');
    }
    final data = base64Encode(upload.bytes);
    return res().html('''
      <img src="data:${upload.mime};base64,$data" />
    ''');
  });

  Server().serve(router);
}
