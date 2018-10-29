import 'package:tree/tree.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    final tree = Tree<int>.generate(20, (i) => i+1, depthFirst: false, maxDepth: 2, maxBreadth: 2);
    print('\n${tree.maxNodes}');
  print('\n$tree');
  print('\n${tree.toString(depthFirst: true)}');
  tree.root.childAt(0).remove();
  print('\n${tree.toString(includePosition: true)}');
    test('First Test', () {
      expect(tree.root, isNotNull);
    });
  });
}
