import 'package:lunart/lunart.dart';

void main() {
  final app = Lunart();

  app.use(requestLogger);

  final postStore = <int, Post>{
    1: Post(id: 1, title: 'Lunart', body: 'The ergonomic server library'),
  };

  app.get('/posts', (_) {
    return postStore.values.toList();
  });

  app.get('/posts/:id', (req) {
    final id = int.tryParse(req.parameters['id']);
    if (id == null) {
      return Res.badRequest().message('Invalid id');
    }

    final post = postStore[id];
    if (post == null) {
      return Res.notFound().message('Post not found');
    }

    return post;
  });

  app.post('/posts', (req) async {
    final data = await req.body();
    if (data == null || data['title'] == null) {
      return Res.badRequest().message('The request is not valid');
    }

    final id = postStore.keys.last + 1;
    final post = Post(
      id: id,
      title: data['title'] as String,
      body: data['body'] as String,
    );
    postStore[id] = post;

    return Res.created().message('Post successfully created');
  });

  app.patch('/posts/:id', (req) async {
    final id = int.tryParse(req.parameters['id']);
    final data = await req.body();

    if (id == null) {
      return Res.badRequest().message('Invalid id');
    }

    if (data == null) {
      return Res.badRequest().message('The request is not valid');
    }

    final post = postStore[id];

    if (post == null) {
      return Res.notFound().message('Post not found');
    }

    postStore[id] = post.copyWith(
      title: data['title'] as String?,
      body: data['body'] as String?,
    );

    return Res.message('Post updated successfully');
  });

  app.delete('/posts/:id', (req) async {
    final id = int.tryParse(req.parameters['id']);

    if (id == null) {
      return Res.badRequest().message('Invalid id');
    }

    if (postStore[id] == null) {
      return Res.notFound().message('Post not found');
    }

    postStore.remove(id);

    return Res.message('Post deleted successfully');
  });

  app.serve();
}

class Post({
  required final int id,
  required final String title,
  final String? body,
}) implements ToJson {
  Post copyWith({String? title, String? body}) {
    return Post(id: id, title: title ?? this.title, body: body ?? this.body);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
    };
  }
}
