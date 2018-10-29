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

  print((await Tree.generate((i) async => i + 1, maxNodes: 25, maxBreadth: 5, maxDepth: 3))
      .toString(includePosition: false));
}
