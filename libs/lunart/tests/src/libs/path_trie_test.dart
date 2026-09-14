import 'package:lunart/src/libs/path_trie.dart';
import 'package:test/test.dart';

void main() {
  group('PathTrie', () {
    test('matches exact static path', () {
      final trie = PathTrie();
      trie.addPath('/users/list');

      final result = trie.lookupPath('/users/list');

      expect(result, isNotNull);
      expect(result!.path, '/users/list');
      expect(result.parameters, isEmpty);
    });

    test('returns null for non-existing path', () {
      final trie = PathTrie();
      trie.addPath('/users/list');

      final result = trie.lookupPath('/users/detail');

      expect(result, isNull);
    });

    test('matches dynamic segment and extracts parameter', () {
      final trie = PathTrie();
      trie.addPath('/users/:id');

      final result = trie.lookupPath('/users/42');

      expect(result, isNotNull);
      expect(result!.path, '/users/:id');
      expect(result.parameters, {'id': '42'});
    });

    test('decodes URL-encoded dynamic parameter', () {
      final trie = PathTrie();
      trie.addPath('/files/:name');

      final result = trie.lookupPath('/files/hello%20world');

      expect(result, isNotNull);
      expect(result!.path, '/files/:name');
      expect(result.parameters, {'name': 'hello world'});
    });

    test('matches wildcard segment for a single section', () {
      final trie = PathTrie();
      trie.addPath('/assets/*');

      final result = trie.lookupPath('/assets/logo.png');

      expect(result, isNotNull);
      expect(result!.path, '/assets/*');
      expect(result.parameters, isEmpty);
    });

    test('prefers exact segment over parameter fallback', () {
      final trie = PathTrie();
      trie.addPath('/users/:id');
      trie.addPath('/users/me');

      final result = trie.lookupPath('/users/me');

      expect(result, isNotNull);
      expect(result!.path, '/users/me');
      expect(result.parameters, isEmpty);
    });

    test('returns null when path is only a non-terminal prefix', () {
      final trie = PathTrie();
      trie.addPath('/users/profile/details');

      final result = trie.lookupPath('/users/profile');

      expect(result, isNull);
    });

    test('extracts multiple dynamic parameters', () {
      final trie = PathTrie();
      trie.addPath('/users/:userId/posts/:postId');

      final result = trie.lookupPath('/users/10/posts/99');

      expect(result, isNotNull);
      expect(result!.path, '/users/:userId/posts/:postId');
      expect(result.parameters, {'userId': '10', 'postId': '99'});
    });

    test('ignores query string when matching path', () {
      final trie = PathTrie();
      trie.addPath('/users/:id');

      final result = trie.lookupPath('/users/42?expand=true');

      expect(result, isNotNull);
      expect(result!.path, '/users/:id');
      expect(result.parameters, {'id': '42'});
    });

    test('matches when lookup path has trailing slash', () {
      final trie = PathTrie();
      trie.addPath('/users/:id');

      final result = trie.lookupPath('/users/42/');

      expect(result, isNotNull);
      expect(result!.path, '/users/:id');
      expect(result.parameters, {'id': '42'});
    });

    test('matches when lookup path contains repeated slashes', () {
      final trie = PathTrie();
      trie.addPath('/users/:id');

      final result = trie.lookupPath('/users//42');

      expect(result, isNotNull);
      expect(result!.path, '/users/:id');
      expect(result.parameters, {'id': '42'});
    });

    test('wildcard matches a single segment and is not greedy', () {
      final trie = PathTrie();
      trie.addPath('/assets/*');

      final result = trie.lookupPath('/assets/a/b');

      expect(result, isNull);
    });

    test('returns null on empty trie', () {
      final trie = PathTrie();

      final result = trie.lookupPath('/anything');

      expect(result, isNull);
    });

    test('uses first inserted fallback when both parameter and wildcard exist', () {
      final trie = PathTrie();
      trie.addPath('/items/:id');
      trie.addPath('/items/*');

      final result = trie.lookupPath('/items/value');

      expect(result, isNotNull);
      expect(result!.path, '/items/:id');
      expect(result.parameters, {'id': 'value'});
    });

    test('uses wildcard first when wildcard was inserted before parameter', () {
      final trie = PathTrie();
      trie.addPath('/items/*');
      trie.addPath('/items/:id');

      final result = trie.lookupPath('/items/value');

      expect(result, isNotNull);
      expect(result!.path, '/items/*');
      expect(result.parameters, isEmpty);
    });
  });
}
