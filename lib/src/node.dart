part of tree;

/// A node within a [Tree].
///
/// Child nodes are kept in a `HashMap<int, Node<T>>`. They can be used as a
/// list by simply omitting the position argument to [add()]. However, if you
/// do specify the child's position directly, you should continue to do so when
/// adding other children, as [add()] simply sets the position to the current
/// length.
///
/// A node's position is its key in its parent's map of children, which allows
/// for fast removal.
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
  Node<T> get parent => tree.parentOf(this);

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

  /// [position] defaults to [childCount], which gives it list-like behavior --
  /// but it is not enforced. Once an element is added at a different position
  /// or an element is moved or removed from the list, the default [position]
  /// will cease to be correct.
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
