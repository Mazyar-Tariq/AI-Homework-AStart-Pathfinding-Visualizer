import 'dart:collection';
import '../models/node.dart';

class AStarPathfinder {
  // Heuristic function: Manhattan Distance
  double _getDistance(Node a, Node b) {
    return (a.row - b.row).abs() + (a.col - b.col).abs().toDouble();
  }

  Future<bool> findPath({
    required List<List<Node>> grid,
    required Node startNode,
    required Node endNode,
    required Function() onStep, // Callback to update UI
    Duration stepDelay = const Duration(milliseconds: 50),
  }) async {
    // 1. Initialize Open and Closed Sets
    List<Node> openSet = [];
    HashSet<Node> closedSet = HashSet<Node>();

    openSet.add(startNode);

    while (openSet.isNotEmpty) {
      // 2. Find node with lowest F cost

      openSet.sort((a, b) => a.fCost.compareTo(b.fCost));
      Node currentNode = openSet.first;
      openSet.remove(currentNode);
      closedSet.add(currentNode);

      // Highlight visited (skip start/end for color preservation)
      if (currentNode != startNode && currentNode != endNode) {
        currentNode.isVisited = true;
        onStep();
        await Future.delayed(stepDelay);
      }

      // 3. Check if reached end
      if (currentNode == endNode) {
        _retracePath(startNode, endNode, onStep);
        return true;
      }

      // 4. Check neighbors
      for (Node neighbor in _getNeighbors(grid, currentNode)) {
        if (neighbor.isWall || closedSet.contains(neighbor)) {
          continue;
        }

        double newMovementCostToNeighbor =
            currentNode.gCost + 1; // Assuming cost 1
        if (currentNode.gCost == double.infinity) {
          newMovementCostToNeighbor = 1; // Start node fix
        }

        if (newMovementCostToNeighbor < neighbor.gCost ||
            !openSet.contains(neighbor)) {
          neighbor.gCost = newMovementCostToNeighbor;
          neighbor.hCost = _getDistance(neighbor, endNode);
          neighbor.parent = currentNode;

          if (!openSet.contains(neighbor)) {
            openSet.add(neighbor);
          }
        }
      }
    }

    return false; // No path found
  }

  void _retracePath(Node startNode, Node endNode, Function() onStep) {
    Node? currentNode = endNode;
    while (currentNode != null) {
      if (currentNode != startNode && currentNode != endNode) {
        currentNode.isPath = true;
      }
      currentNode = currentNode.parent;
    }
    onStep();
  }

  List<Node> _getNeighbors(List<List<Node>> grid, Node node) {
    List<Node> neighbors = [];
    int rows = grid.length;
    int cols = grid[0].length;

    // Up, Down, Left, Right (No diagonals for Manhattan style usually, but can add)
    int r = node.row;
    int c = node.col;

    if (r > 0) neighbors.add(grid[r - 1][c]); // Up
    if (r < rows - 1) neighbors.add(grid[r + 1][c]); // Down
    if (c > 0) neighbors.add(grid[r][c - 1]); // Left
    if (c < cols - 1) neighbors.add(grid[r][c + 1]); // Right

    return neighbors;
  }
}
