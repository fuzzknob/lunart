import 'package:lucore/lucore.dart';

void main() {
  final router = Router();
  final postStore = <int, Post>{
    1: Post(id: 1, title: 'Lunart Core', body: 'The ergonomic server library'),
  };

  router.get('/posts', (_) {
    final posts = postStore.values.map((post) => post.toJson()).toList();
    return res.json(posts);
  });

  router.get('/posts/:id', (req) {
    final id = int.tryParse(req.parameters['id']);
    if (id == null) {
      return res.badRequest().message('Invalid id');
    }

    final post = postStore[id];
    if (post == null) {
      return res.notFound().message('Post not found');
    }

    return res.json(post);
  });

  router.post('/posts', (req) async {
    final data = await req.body();
    if (data == null || data['title'] == null) {
      return res.badRequest().message('The request is not valid');
    }

    final id = postStore.keys.last + 1;
    final post = Post(
      id: id,
      title: data['title'] as String,
      body: data['body'] as String,
    );
    postStore[id] = post;

    return res.created().message('Post successfully created');
  });

  router.patch('/posts/:id', (req) async {
    final id = int.tryParse(req.parameters['id']);
    final data = await req.body();

    if (id == null) {
      return res.badRequest().message('Invalid id');
    }

    if (data == null) {
      return res.badRequest().message('The request is not valid');
    }

    final post = postStore[id];

    if (post == null) {
      return res.notFound().message('Post not found');
    }

    postStore[id] = post.copyWith(
      title: data['title'] as String,
      body: data['body'] as String,
    );

    return res.message('Post updated successfully');
  });

  router.delete('/posts/:id', (req) async {
    final id = int.tryParse(req.parameters['id']);

    if (id == null) {
      return res.badRequest().message('Invalid id');
    }

    if (postStore[id] == null) {
      res.notFound().message('Post not found');
    }

    postStore.remove(id);

    return res.message('Post deleted successfully');
  });

  Server().use(logger).serve(router);
}

class Post {
  Post({required this.id, required this.title, this.body});
  final int id;
  final String title;
  final String? body;

  Post copyWith({String? title, String? body}) {
    return Post(id: id, title: title ?? this.title, body: body ?? this.body);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'body': body};
  }
}
