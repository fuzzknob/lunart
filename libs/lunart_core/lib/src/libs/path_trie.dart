import 'package:collection/collection.dart';

class PathTrie {
  final rootNode = Node();

  void addPath(String path) {
    final sections = path.split('/');
    var currentNode = rootNode;
    for (final section in sections) {
      if (section.isEmpty) continue;
      final child = currentNode.children[section];
      if (child != null) {
        currentNode = child;
        continue;
      }
      final newChild = Node();
      currentNode.children[section] = newChild;
      currentNode = newChild;
    }
    currentNode.isAPathEnd = true;
  }

  PathLookupResult? lookupPath(String path) {
    final uri = Uri.parse(path);
    final sections = uri.path.split('/');
    final parameters = <String, String>{};

    var currentNode = rootNode;
    var fullPath = '';

    for (final requestSection in sections) {
      if (requestSection.isEmpty) continue;
      var pathSection = requestSection;
      var child = currentNode.children[pathSection];
      if (child == null) {
        pathSection =
            currentNode.children.keys.firstWhereOrNull(
              (path) => path == '*' || path.startsWith(':'),
            ) ??
            '';
        child = currentNode.children[pathSection];
      }
      if (child == null) return null;
      if (pathSection.startsWith(':')) {
        final parameterName = pathSection.substring(1);
        parameters[parameterName] = requestSection;
      }
      fullPath += '/$pathSection';
      currentNode = child;
    }
    if (!currentNode.isAPathEnd) return null;
    return PathLookupResult(parameters: parameters, path: fullPath);
  }

  void printTrie([Node? node, String prefix = '']) {
    node ??= rootNode;
    if (node.isAPathEnd) {
      print(prefix.isEmpty ? '/' : prefix);
    }
    for (final entry in node.children.entries) {
      printTrie(entry.value, '$prefix/${entry.key}');
    }
  }
}

class Node {
  final children = <String, Node>{};
  bool isAPathEnd = false;
}

class PathLookupResult {
  final String path;
  final Map<String, String> parameters;
  const PathLookupResult({required this.path, required this.parameters});
}
