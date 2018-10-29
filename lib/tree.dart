import 'dart:collection';

class Tree<T> {
  Tree(T rootValue, {this.maxBreadth, this.maxDepth})
      : root = Node._(rootValue, 1, null) {
    root._tree = this;
    _parents[root] = null;
  }

  final Node<T> root;
  final int maxBreadth;
  final int maxDepth;
  final _parents = HashMap<Node<T>, Node<T>>();

  Iterable<Node<T>> get nodes => _parents.keys;
  int get nodeCount => _parents.length;

  bool contains(Node<T> node) => _parents.containsKey(node);

  void _remove(Node<T> node) {
    _parents.remove(node);
    node._children.forEach((index, n) {
      _remove(n);
    });
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
  String toString() => allNodes(sortByPosition: true).join('\n');
}

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
  bool get canHaveChildren => tree.maxDepth == null || depth < tree.maxDepth;
  bool get hasChildren => _children.length > 0;
  bool hasChildAt(int position) => _children[position] != null;
  bool canHaveChildAt(int position) =>
      position >= 0 &&
      canHaveChildren &&
      !hasChildAt(position) &&
      (tree.maxBreadth == null ||
          (position < tree.maxBreadth && _children.length < tree.maxBreadth));

  Node<T> add(T value, int position) {
    if (canHaveChildAt(position)) {
      final node = Node._(value, depth + 1, position, tree);
      tree._parents[node] = this;
      return node;
    }
    return null;
  }

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
  String toString() {
    final kids = _children.keys.toList()
      ..sort()
      ..map((i) => '$i: ${_children[i].value}').join(', ');
    return '$value: ($kids)';
  }
}
