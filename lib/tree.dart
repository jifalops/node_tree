import 'dart:collection';

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
  Node<T> get parent => _tree._parent[this];

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
      tree._parent[node] = this;
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
    if (this == tree.root) return false;
    tree._remove(this);
    return true;
  }

  bool moveTo(Node<T> newParent, int newPosition) {
    if (tree.contains(newParent) && newParent.canHaveChildAt(position)) {
      if (parent != null) parent._children.remove(position);
      newParent._children[newPosition] = this;
      tree._parent[this] = newParent;
      return true;
    }
    return false;
  }

  @override
  toString() => 'Node: $value';
}

class Tree<T> {
  Tree(T rootValue, {this.maxBreadth, this.maxDepth})
      : root = Node._(rootValue, 1, null) {
    root._tree = this;
    _parent[root] = null;
  }

  final Node<T> root;
  final int maxBreadth;
  final int maxDepth;
  final _parent = HashMap<Node<T>, Node<T>>();

  bool contains(Node<T> node) => _parent[node] != null || node == root;

  void _remove(Node<T> node) {
    _parent.remove(node);
    node._children.forEach((index, n) {
      _remove(n);
    });
  }
}
