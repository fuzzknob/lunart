import 'dart:convert';

import 'package:lunart/lunart.dart';

const formsHTMLTemplate = '''
<!DOCTYPE html>
<html>
  <head>
    <title>Lunart forms</title>
  </head>
  <body>
    <h1>Url encoded form</h1>
    <form action="/post-urlencoded" method="post">
      <label for="name">Name</label>
      <input type="text" id="name" name="name"><br><br>
      <label for="email">Email</label>
      <input type="email" id="email" name="email"><br><br>
      <button>Submit</button>
    </form>

    <h1>Multipart form</h1>
    <form action="/post-multi-part" method="post" enctype="multipart/form-data">
      <label for="file-upload">Image</label>
      <input type="file" accept="image/*" id="file-upload" name="file-upload"><br><br>
      <button>Submit</button>
    </form>
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
