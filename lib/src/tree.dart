part of node_tree;

/// An unbalanced tree of arbitrary but limitable breadth and depth. Supports
/// random and asynchronous generation.
///
/// The tree itself stores a [HashMap] of [Node] => parent relationships,
/// allowing fast re-parenting of nodes and faster random tree generation
/// ([Tree.generate()]). The downside is that removing a node requires walking
/// through it's children and removing them from this map.
///
/// The fastest way to get all of the nodes is to use the [nodes] getter, but
/// more flexible ways of retrieving them are supported by [allNodes()] and
/// [Node.allChildren()].
class Tree<T> {
  Tree(T rootValue,
      {this.maxBreadth,
      this.maxDepth,
      int maxNodes,
      bool rootDepthIsOne: false})
      : assert(maxBreadth == null || maxBreadth >= 2),
        assert(maxDepth == null || maxDepth >= 1 + (rootDepthIsOne ? 1 : 0)),
        assert(maxNodes == null || maxNodes >= 3),
        maxNodes =
            _clampMaxNodes(maxBreadth, maxDepth, maxNodes, rootDepthIsOne),
        root = Node._(rootValue, rootDepthIsOne ? 1 : 0, null) {
    root._tree = this;
    _parents[root] = null;
  }

  final Node<T> root;
  final int maxNodes;

  /// The maximum number of child nodes any particular node may have.
  final int maxBreadth;
  final int maxDepth;
  final _parents = HashMap<Node<T>, Node<T>>();

  Random __random;
  Random get _random => __random ??= Random();

  Node<T> parentOf(Node<T> node) => _parents[node];

  /// Gets the nodes in an undetermined order.
  Iterable<Node<T>> get nodes => _parents.keys;
  int get nodeCount => _parents.length;
  bool get canAddNode => maxNodes == null || nodeCount < maxNodes;

  bool contains(Node<T> node) => _parents.containsKey(node);

  void _remove(Node<T> node) {
    _parents.remove(node);
    node._children.forEach((index, n) {
      _remove(n);
    });
  }

  /// This can take a very long time if there are few available spots in a large
  /// tree. If [maxBreadth] or [maxDepth] are null, this will be fast.
  Node<T> addRandom(T value) {
    if (!canAddNode) return null;
    Node<T> n;
    int position;
    do {
      n = nodes.elementAt(_random.nextInt(nodeCount));
    } while (!n.canHaveChildren);
    if (maxBreadth != null) {
      while (n.childAt(position = _random.nextInt(maxBreadth)) != null);
    }
    return n.add(value, position ?? n.childCount);
  }

  /// Returns a list that contains [root] plus the result of calling
  /// [root.allChildren()].
  List<Node<T>> allNodes({bool sortByPosition: true, bool depthFirst: false}) {
    final list = List<Node<T>>();
    list.add(root);
    list.addAll(root.allChildren(
        sortByPosition: sortByPosition, depthFirst: depthFirst));
    return list;
  }

  @override
  String toString({bool depthFirst: false, bool includePosition: true}) =>
      allNodes(depthFirst: depthFirst)
          .map((n) => n.toString(includePosition))
          .join('\n');

  static double nodeLimit(int breadth, int depth,
          [bool rootDepthIsOne = false]) =>
      (pow(breadth, depth + (rootDepthIsOne ? 0 : 1)) - 1) / (breadth - 1);

  /// Create a tree by repeatedly calling the [generator] function.
  ///
  /// Tree traversal/attachment order is decided as:
  ///
  /// * Depth-first if [depthFirst] is true and [maxDepth] is specified.
  ///   * If [maxBreadth] is null, traversal starts back at the root node once
  /// [maxDepth] has been reached. Normally, the next node is the current node's
  /// parent.
  /// * Breadth-first if [depthFirst] is false and [maxBreadth] is specified.
  /// * Otherwise, the generated node's parent is chosen at random. See
  /// [addRandom()].
  ///
  /// Generation is stopped when any of the following are true.
  /// * [maxNodes] has been generated. This value is clamped if both
  /// [maxBreadth] and [maxDepth] are specified.
  /// * The [generator] function returns `null`.
  ///
  /// Depth-first trees are faster to generate than breadth-first trees since
  /// they don't need to keep a list of nodes to visit. Random generation is the
  /// slowest; potentially very slow if there are few spots available in a large
  /// tree. See [addRandom()]. Depth-first generation with unlimited breadth is
  /// faster than depth-first with limited breadth, but not significantly so.
  static Future<Tree<T>> generate<T>(Future<T> Function(int index) generator,
      {int maxBreadth,
      int maxDepth,
      int maxNodes,
      bool depthFirst,
      bool rootDepthIsOne: false}) async {
    final tree = Tree<T>(await generator(0),
        maxBreadth: maxBreadth,
        maxDepth: maxDepth,
        maxNodes: maxNodes,
        rootDepthIsOne: rootDepthIsOne);

    Node<T> n = tree.root;
    T value = n.value;

    bool shouldContinue() => tree.canAddNode && value != null;

    if (depthFirst == true && maxDepth != null) {
      while (shouldContinue()) {
        while ((n?.canHaveChildren ?? false) && shouldContinue()) {
          value = await generator(tree.nodeCount);
          if (value != null) n = n.add(value);
        }
        n = maxBreadth == null ? tree.root : n?.parent ?? tree.root;
      }
    } else if (depthFirst == false && maxBreadth != null) {
      final nodesToVisit = List<Node<T>>();
      while (shouldContinue() && n != null) {
        while (n.canHaveChildren && shouldContinue()) {
          value = await generator(tree.nodeCount);
          if (value != null) nodesToVisit.add(n.add(value));
        }
        n = n?.parent?.childAt(n.position + 1) ?? nodesToVisit.removeAt(0);
      }
    } else {
      while (shouldContinue()) {
        value = await generator(tree.nodeCount);
        if (value != null) tree.addRandom(value);
      }
    }

    return tree;
  }
}

_clampMaxNodes(
    int maxBreadth, int maxDepth, int maxNodes, bool rootDepthIsOne) {
  if (maxBreadth != null && maxDepth != null) {
    final limit = Tree.nodeLimit(maxBreadth, maxDepth, rootDepthIsOne);
    if (maxNodes == null || maxNodes > limit) maxNodes = limit.floor();
  }
  return maxNodes;
}
