import 'package:node_tree/node_tree.dart';

void main() async {
  // Number generator.
  Future<int> gen(int i) async => i + 1;

  print('Manual creation.');
  final tree = Tree<String>('a');
  final b = tree.root.add('b');
  final c = tree.root.add('c');
  b..add('d')..add('e');
  c..add('f')..add('g');
  tree.addRandom('x');
  print(tree.toString());

  print('10 random nodes.');
  print((await Tree.generate((i) async => i < 10 ? i + 1 : null))
      .toString(includePosition: true));
  print(
      (await Tree.generate(gen, maxNodes: 10)).toString(includePosition: true));

  print('Generated, depth-first.');
  print((await Tree.generate(gen, maxNodes: 10, depthFirst: true, maxDepth: 2))
      .toString(depthFirst: true));

  print('Generated, breadth-first.');
  print(
      await Tree.generate(gen, maxNodes: 10, depthFirst: false, maxBreadth: 2));

  print('Filled, depth first.');
  print((await Tree.generate(gen, maxBreadth: 2, maxDepth: 3, depthFirst: true))
      .toString(depthFirst: true));
}