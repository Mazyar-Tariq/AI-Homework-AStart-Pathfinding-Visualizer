class Node {
  final int row;
  final int col;
  bool isWall;
  bool isStart;
  bool isEnd;
  bool isPath;
  bool isVisited;

  // A* specific properties
  double gCost = double.infinity;
  double hCost = double.infinity;
  Node? parent;

  Node({
    required this.row,
    required this.col,
    this.isWall = false,
    this.isStart = false,
    this.isEnd = false,
    this.isPath = false,
    this.isVisited = false,
  });

  double get fCost => gCost + hCost;

  void reset() {
    isWall = false;
    isStart = false;
    isEnd = false;
    isPath = false;
    isVisited = false;
    gCost = double.infinity;
    hCost = double.infinity;
    parent = null;
  }

  void resetPathData() {
    isPath = false;
    isVisited = false;
    gCost = double.infinity;
    hCost = double.infinity;
    parent = null;
  }
}
