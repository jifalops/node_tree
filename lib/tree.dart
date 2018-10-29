import 'dart:collection';
import 'dart:math';

/// A tree of arbitrary depth and breadth.
class Tree<T> {
  Tree(T rootValue,
      {this.maxBreadth,
      this.maxDepth,
      int maxNodes,
      bool startDepthAtOne: false})
      : assert(maxBreadth == null || maxBreadth >= 2),
        assert(maxDepth == null || maxDepth >= 1 + (startDepthAtOne ? 1 : 0)),
        assert(maxNodes == null || maxNodes >= 3),
        maxNodes =
            _clampMaxNodes(maxBreadth, maxDepth, maxNodes, startDepthAtOne),
        root = Node._(rootValue, startDepthAtOne ? 1 : 0, null) {
    root._tree = this;
    _parents[root] = null;
  }

  /// Create a tree by repeatedly calling the [generator] function.
  ///
  /// You must specify either [maxNodes] or ([maxDepth] and [maxBreadth]).
  /// Failing to do so will result an infinite loop.
  ///
  /// If [depthFirst] is true and [maxDepth] is specified, depth-first
  /// generation will be used. If [depthFirst] is false and [maxBreadth] is
  /// specified, breadth-first generation will be used. Otherwise, generated
  /// nodes will be attached to the tree by choosing an available parent node at
  /// random.
  Tree.generate(T Function(int index) generator,
      {this.maxBreadth,
      this.maxDepth,
      int maxNodes,
      bool depthFirst,
      bool startDepthAtOne: false})
      : assert(maxNodes != null || (maxBreadth != null && maxDepth != null)),
      assert(maxBreadth == null || maxBreadth >= 2),
        assert(maxDepth == null || maxDepth >= 1 + (startDepthAtOne ? 1 : 0)),
        assert(maxNodes == null || maxNodes >= 3),
        assert(generator != null),
        maxNodes =
            _clampMaxNodes(maxBreadth, maxDepth, maxNodes, startDepthAtOne),
        root = Node._(generator(0), startDepthAtOne ? 1 : 0, null) {
    root._tree = this;
    _parents[root] = null;

    final count = this.maxNodes;
    int index = 1;
    Node<T> n = root;
    if (depthFirst == true && maxDepth != null) {
      while (index < count) {
        while ((n?.canHaveChildren ?? false) && index < count) {
          n = n.add(generator(index++));
        }
        n = maxBreadth == null ? root : n?.parent ?? root;
      }
    } else if (depthFirst == false && maxBreadth != null) {
      while (index < count && n != null) {
        while (n.canHaveChildren && index < count) {
          n.add(generator(index++));
        }
        n = n.parent?.childAt(n.position + 1) ?? n.childAt(0);
      }
    } else {
      while (index < count) {
        do {
          n = nodes.elementAt(_random.nextInt(nodeCount));
        } while (!n.canHaveChildren);
        n.add(generator(index++));
      }
    }
  }

  final Node<T> root;
  final int maxNodes;

  /// The maximum number of child nodes any particular node may have.
  final int maxBreadth;
  final int maxDepth;
  final _parents = HashMap<Node<T>, Node<T>>();

  Random __random;
  Random get _random => __random ??= Random();

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
    Node n;
    do {
      n = nodes.elementAt(_random.nextInt(nodeCount));
    } while (!n.canHaveChildren);
    return n.add(value);
  }

  /// Returns a list that contains [root] plus the result of calling
  /// [root.allChildren()].
  List<Node<T>> allNodes({bool sortByPosition: false, bool depthFirst: false}) {
    final list = List<Node<T>>();
    list.add(root);
    list.addAll(root.allChildren(
        sortByPosition: sortByPosition, depthFirst: depthFirst));
    return list;
  }

  @override
  String toString({bool depthFirst: false, includePosition: false}) =>
      allNodes(sortByPosition: true, depthFirst: depthFirst)
          .map((n) => n.toString(includePosition))
          .join('\n');
}

_clampMaxNodes(
        int maxBreadth, int maxDepth, int maxNodes, bool startDepthAtOne) =>
    (maxBreadth != null &&
            maxDepth != null &&
            (maxNodes == null || maxNodes > maxBreadth * maxDepth))
        ? ((pow(maxBreadth, maxDepth + (startDepthAtOne ? 0 : 1)) - 1) /
                (maxBreadth - 1))
            .truncate()
        : maxNodes;

class Node<T> {
  Node._(this.value, this._depth, this._position, [this._tree]);
  final T value;
  final _children = HashMap<int, Node<T>>();
  int _depth;
  int _position;
  Tree<T> _tree;

  /// This node's position in its parent.
  int get position => _position;
  int get depth => _depth;
  Tree<T> get tree => _tree;
  HashMap<int, Node<T>> get children => Map.unmodifiable(_children);
  Node<T> get parent => tree._parents[this];

  int get childCount => _children.length;
  bool get canHaveChildren =>
      tree.canAddNode &&
      (tree.maxDepth == null || depth < tree.maxDepth) &&
      (tree.maxBreadth == null || childCount < tree.maxBreadth);

  bool hasChildAt(int position) => _children[position] != null;
  bool canHaveChildAt(int position) =>
      position >= 0 &&
      canHaveChildren &&
      !hasChildAt(position) &&
      (tree.maxBreadth == null || position < tree.maxBreadth);

  /// [position] defaults to [childCount], which gives it list-like behavior.
  Node<T> add(T value, [int position]) {
    position ??= childCount;
    if (canHaveChildAt(position)) {
      final node = Node._(value, depth + 1, position, tree);
      _children[position] = node;
      tree._parents[node] = this;
      return node;
    }
    return null;
  }

  Node<T> childAt(int position) => _children[position];

  Node<T> removeChildAt(int position) {
    final node = _children.remove(position);
    if (node != null) tree._remove(node);
    return node;
  }

  /// Returns false if this is the root node, true otherwise.
  bool remove() {
    if (parent == null) return false;
    parent.removeChildAt(position);
    return true;
  }

  bool moveTo(Node<T> newParent, int newPosition) {
    if (this == tree.root ||
        !tree.contains(newParent) ||
        !newParent.canHaveChildAt(position)) return false;

    parent._children.remove(position);

    newParent._children[newPosition] = this;
    _position = newPosition;
    _depth = newParent.depth + 1;

    tree._parents[this] = newParent;
    return true;
  }

  List<Node<T>> allChildren(
      {bool sortByPosition: false, bool depthFirst: false}) {
    final list = List<Node<T>>();
    if (sortByPosition) {
      final keys = _children.keys.toList()..sort();
      if (!depthFirst) list.addAll(keys.map((i) => _children[i]));

      keys.forEach((i) {
        if (depthFirst) list.add(_children[i]);
        list.addAll(_children[i].allChildren(
            sortByPosition: sortByPosition, depthFirst: depthFirst));
      });
    } else {
      if (!depthFirst) list.addAll(_children.values);
      _children.values.forEach((child) {
        if (depthFirst) list.add(child);
        list.addAll(child.allChildren(
            sortByPosition: sortByPosition, depthFirst: depthFirst));
      });
    }
    return list;
  }

  @override
  String toString([bool includePosition = false]) {
    final keys = _children.keys.toList()..sort();
    final kids = keys
        .map((i) => '${includePosition ? '$i: ' : ''}${_children[i].value}')
        .join(', ');
    return '$value: ($kids)';
  }
}
