import 'package:flutter/material.dart';
import 'models/node.dart';
import 'algorithm/a_star.dart';

class GridScreen extends StatefulWidget {
  const GridScreen({super.key});

  @override
  State<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> {
  int rows = 15;
  int cols = 15;

  late List<List<Node>> grid;
  final TextEditingController _rowsController = TextEditingController(
    text: '15',
  );
  final TextEditingController _colsController = TextEditingController(
    text: '15',
  );

  bool isDragging = false;
  bool isVisualizing = false;

  // Interaction mode
  String selectedMode = 'wall'; // wall, start, end

  @override
  void initState() {
    super.initState();
    initializeGrid();
  }

  void initializeGrid() {
    grid = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        return Node(row: r, col: c);
      });
    });
    // Set default start and end dynamically based on grid size
    int startRow = (rows * 0.2).toInt().clamp(0, rows - 1);
    int startCol = (cols * 0.2).toInt().clamp(0, cols - 1);
    int endRow = (rows * 0.8).toInt().clamp(0, rows - 1);
    int endCol = (cols * 0.8).toInt().clamp(0, cols - 1);

    // Ensure they are not the same
    if (startRow == endRow && startCol == endCol) {
      endRow = (rows - 1).clamp(0, rows - 1);
      endCol = (cols - 1).clamp(0, cols - 1);
    }

    grid[startRow][startCol].isStart = true;
    grid[endRow][endCol].isEnd = true;
  }

  void handleTap(int r, int c) {
    setState(() {
      Node node = grid[r][c];
      if (selectedMode == 'wall') {
        node.isWall = !node.isWall;
        // Ensure start/end are not overwritten effectively, or handle logic
        if (node.isStart || node.isEnd) {
          node.isWall = false;
        }
      } else if (selectedMode == 'start') {
        // Clear previous start
        for (var row in grid) {
          for (var n in row) {
            n.isStart = false;
          }
        }

        node.isStart = true;
        node.isWall = false;
        node.isEnd = false;
      } else if (selectedMode == 'end') {
        // Clear previous end
        for (var row in grid) {
          for (var n in row) {
            n.isEnd = false;
          }
        }

        node.isEnd = true;
        node.isWall = false;
        node.isStart = false;
      }
    });
  }

  void handlePanUpdate(
    DragUpdateDetails details,
    double cellWidth,
    double cellHeight,
  ) {
    // Calculate which cell is being touched
    // This is simple approximation, might need RenderBox for precision
    // For now, let's just make it work for walls on Tap/Pan
    // Since GridView is tricky with Pan, we might use GestureDetector on specific cells or Listener on the whole grid
    // For simplicity, let's rely on efficient GestureDetector per cell or a Stack.
    // Actually, GestureDetector per cell is fine for 20x20.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('A* Pathfinding Visualizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                initializeGrid();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Control Panel
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeButton(
                  'Set Start',
                  'start',
                  Icons.flag,
                  Colors.green,
                ),
                const SizedBox(width: 10),
                _buildModeButton('Set Wall', 'wall', Icons.block, Colors.black),
                const SizedBox(width: 10),
                _buildModeButton(
                  'Set End',
                  'end',
                  Icons.location_on,
                  Colors.red,
                ),
              ],
            ),
          ),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Keep cells square
                // Keep cells square
                // We want it to fit

                // We want it to fit
                return GridView.builder(
                  physics:
                      const NeverScrollableScrollPhysics(), // Disable scrolling for fixed grid
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                  ),
                  itemCount: rows * cols,

                  itemBuilder: (context, index) {
                    int r = index ~/ cols;
                    int c = index % cols;
                    Node node = grid[r][c];
                    return GestureDetector(
                      onTap: () => handleTap(r, c),
                      onPanUpdate: (details) {
                        // Allow "painting" walls
                        if (selectedMode == 'wall') {
                          // This requires more complex hit testing or global state tracking
                          // For this homework, simple Tap is okay, or we can improve later.
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: _getNodeColor(node),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${node.row},${node.col}',
                          style: TextStyle(
                            fontSize: 8,
                            color: node.isWall ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Visualize A*'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: isVisualizing
                        ? null
                        : () async {
                            setState(() {
                              isVisualizing = true;
                              // Clear previous path logic if needed
                              for (var row in grid) {
                                for (var n in row) {
                                  n.resetPathData();
                                }
                              }
                            });

                            Node start = grid
                                .expand((e) => e)
                                .firstWhere((e) => e.isStart);
                            Node end = grid
                                .expand((e) => e)
                                .firstWhere((e) => e.isEnd);

                            final messenger = ScaffoldMessenger.of(context);
                            bool found = await AStarPathfinder().findPath(
                              grid: grid,
                              startNode: start,
                              endNode: end,
                              onStep: () {
                                setState(() {});
                              },
                            );

                            if (!found) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Goal not reachable!'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }

                            setState(() {
                              isVisualizing = false;
                            });
                          },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Info'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),

                    onPressed: isVisualizing
                        ? null
                        : () {
                            setState(() {
                              for (var row in grid) {
                                for (var n in row) {
                                  n.resetPathData();
                                }
                              }
                            });
                          },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Clear Grid'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: isVisualizing
                        ? null
                        : () {
                            setState(() {
                              initializeGrid();
                            });
                          },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    String label,
    String mode,
    IconData icon,
    Color color,
  ) {
    bool isSelected = selectedMode == mode;
    return ElevatedButton.icon(
      onPressed: () => setState(() => selectedMode = mode),
      icon: Icon(icon, color: isSelected ? Colors.white : color),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
    );
  }

  Color _getNodeColor(Node node) {
    if (node.isStart) return Colors.green;
    if (node.isEnd) return Colors.red;
    if (node.isWall) return Colors.black;
    if (node.isPath) return Colors.blue; // Final path
    if (node.isVisited) {
      return Colors.blue.shade100; // Open/Closed set visualization
    }

    return Colors.white;
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grid Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _rowsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Rows (5-50)'),
            ),
            TextField(
              controller: _colsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Columns (5-50)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              int? newRows = int.tryParse(_rowsController.text);
              int? newCols = int.tryParse(_colsController.text);

              if (newRows != null && newCols != null) {
                // Limit size to prevent crashes/lag
                newRows = newRows.clamp(5, 50);
                newCols = newCols.clamp(5, 50);

                setState(() {
                  rows = newRows!;
                  cols = newCols!;
                  _rowsController.text = rows.toString();
                  _colsController.text = cols.toString();
                  initializeGrid();
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
