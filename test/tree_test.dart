import 'package:tree/tree.dart';
import 'package:test/test.dart';

const genLimit = 200;

void main() async {
  Future<int> gen(int i) async => i < genLimit ? i + 1 : null;

  final binaryBF = await Tree.generate(gen, depthFirst: false, maxBreadth: 2);
  final ternaryBF = await Tree.generate(gen, depthFirst: false, maxBreadth: 3);
  final binaryLimitedBF =
      await Tree.generate(gen, depthFirst: false, maxBreadth: 2, maxDepth: 4);
  final ternaryLimitedBF =
      await Tree.generate(gen, depthFirst: false, maxBreadth: 3, maxDepth: 4);

  final binaryDF =
      await Tree.generate(gen, depthFirst: true, maxBreadth: 2, maxDepth: 4);
  final ternaryDF =
      await Tree.generate(gen, depthFirst: true, maxBreadth: 3, maxDepth: 4);

  final wideDF = await Tree.generate(gen, depthFirst: true, maxDepth: 5);
  final wideRandom = await Tree.generate(gen, maxDepth: 5);
  final tallRandom = await Tree.generate(gen, maxBreadth: 5);
  final random = await Tree.generate(gen);

  group('node counts', () {
    test('binaryBF', () => expect(binaryBF.nodeCount, genLimit));
    test('ternaryBF', () => expect(ternaryBF.nodeCount, genLimit));
    test('binaryLimitedBF',
        () => expect(binaryLimitedBF.nodeCount, Tree.nodeLimit(2, 4)));
    test('ternaryLimitedBF',
        () => expect(ternaryLimitedBF.nodeCount, Tree.nodeLimit(3, 4)));
    test('binaryDF', () => expect(binaryDF.nodeCount, Tree.nodeLimit(2, 4)));
    test('ternaryDF', () => expect(ternaryDF.nodeCount, Tree.nodeLimit(3, 4)));
    test('wideDF', () => expect(wideDF.nodeCount, genLimit));
    test('wideRandom', () => expect(wideRandom.nodeCount, genLimit));
    test('tallRandom', () => expect(tallRandom.nodeCount, genLimit));
    test('random', () => expect(random.nodeCount, genLimit));
  });

  print((await Tree.generate(gen, maxNodes: 10, maxBreadth: 2, maxDepth: 3)));

  final timer = Stopwatch();
  int index = 0;
  var tree = Tree<int>(index, maxNodes: 10000);
  timer.start();
  while (tree.addRandom(++index) != null);
  // await Tree.generate((i) async => i, maxNodes: 10000);
  timer.stop();
  print('Unbound Random: ${timer.elapsed}');

  timer.reset();
  index = 0;
  tree = Tree<int>(index, maxNodes: 10000, maxBreadth: 2);
  timer.start();
  while (tree.addRandom(++index) != null);
  // await Tree.generate((i) async => i, maxNodes: 10000, maxBreadth: 2);
  timer.stop();
  print('Binary Random: ${timer.elapsed}');

  timer.reset();
  timer.start();
  await Tree.generate((i) async => i,
      maxNodes: 100000, maxDepth: 10, maxBreadth: 10, depthFirst: true);
  timer.stop();
  print('Generated depth-first: ${timer.elapsed}');

  timer.reset();
  timer.start();
  await Tree.generate((i) async => i,
      maxNodes: 100000, maxDepth: 10, depthFirst: true);
  timer.stop();
  print('Generated depth-first, unbound breadth: ${timer.elapsed}');

  timer.reset();
  timer.start();
  await Tree.generate((i) async => i,
      maxNodes: 100000, maxDepth: 10, maxBreadth: 10, depthFirst: false);
  timer.stop();
  print('Generated breadth-first: ${timer.elapsed}');
}
