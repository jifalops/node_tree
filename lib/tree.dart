class Node<T> {
  Node._(this.value);
  final T value;
  T _parent;
  Map<int, T> _children;
  int _position;

  T get parent => _parent;
  Map<int, T> get children => Map.unmodifiable(_children);
  /// This node's position in its parent.
  int get position => _position;

  @override
  operator ==(o) => o is Node && value == o.value;
  int get hashCode => value.hashCode;
  @override toString() => 'Node: $value';
}

class Tree<T> {
  Tree(this.root, {this.maxBreadth, this.maxDepth}) {
    _parent[root] = null;
    _children[root] = {};
    _childIndex[root] = null;
  }
  final T root;
  final int maxBreadth;
  final int maxDepth;
  final _parent = <T, T>{};
  final _children = <T, Map<int, T>>{};
  final _childIndex = <T, int>{};

  bool nodeExists(T node) => _parent[node] != null || node == root;

  bool nodeHasChildren(T node) => _children[node]?.length ?? 0 > 0;

  bool nodeHasChild(T node, int childIndex) =>
      _children[node]?.containsKey(childIndex);

  /// Returns `0` if the node is not in the tree.
  int depthOf(T node) {
    if (node == root) return 1;
    node = _parent[node];
    if (node != null) {
      int depth = 2;
      while (_parent[node] != null) {
        depth++;
        node = _parent[node];
      }
      return depth;
    }
    return 0;
  }

  T parentOf(T node) => _parent[node];
  Map<int, T> childrenOf(T node) => Map.unmodifiable(_children[node]);
  int nodeIndexInParent(T node) => _childIndex[node];

  bool addNode(T node, T parent, int childIndex) {
    if (childIndex >= maxBreadth ||
        nodeExists(node) ||
        !nodeExists(parent) ||
        nodeHasChild(parent, childIndex)) return false;

    if ((maxBreadth == null || _children[parent].length < maxBreadth) &&
        (maxDepth == null || depthOf(parent) < maxDepth)) {
      _children[parent][childIndex] = node;
      _parent[node] = parent;
      _children[node] = {};
      _childIndex[node] = childIndex;
      return true;
    }
    return false;
  }

  bool moveNode(T node, T parent, int childIndex) {
    if (childIndex >= maxBreadth ||
        !nodeExists(node) ||
        !nodeExists(parent) ||
        nodeHasChild(parent, childIndex)) return false;

    _children[_parent[node]].remove(_childIndex[node]);
    _children[parent][childIndex] = node;
    _parent[node] = parent;
    _childIndex[node] = childIndex;
    return true;
  }

  /// The root node cannot be removed.
  bool removeNode(T node) {
    if (_parent[node] == null) return false;
    _children[_parent[node]].remove(_childIndex[node]);
    _parent.remove(node);
    _childIndex.remove(node);
    _children[node].forEach((index, n) {
      removeNode(n);
    });
    return true;
  }
}
