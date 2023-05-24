import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:custom_mazeapp/models/path_item.dart';
import 'package:flutter/material.dart' hide Stack;
import 'package:flutter/services.dart';
import 'models/cell.dart';
import 'models/item_position.dart';
import 'models/stack.dart';

/// Direction movement
enum Direction {
  ///Goes up in the maze
  up,

  ///Goes down in the maze
  down,

  ///Goes left in the maze
  left,

  ///Goes right in the maze
  right
}

///Maze Painter
///Draws the maze based on params
class MazePainter extends ChangeNotifier implements CustomPainter {
//this list for store each cell wall condition...

  ///Default constructor
  MazePainter({
    required this.playerImage,
    required this.playerImageUp,
    required this.playerImageDown,
    required this.playerImageLeft,
    required this.playerImageRight,
    this.playerColor = Colors.black,
    this.checkpointsImages = const [],
    this.columns = 7,
    this.finishImage,
    this.onCheckpoint,
    this.onFinish,
    this.onDrawPath,
    this.rows = 10,
    this.wallColor = Colors.black,
    this.wallThickness = 4.0,
  }) {
    _wallPaint
      ..color = wallColor
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeWidth = wallThickness;

    _exitPaint..color = wallColor;


    _playerPaint
      ..color = playerColor
      ..isAntiAlias = true;

    _checkpoints = List.from(checkpointsImages);
    _checkpointsPositions = _checkpoints
        .map((i) => ItemPosition(
            col: _randomizer.nextInt(columns), row: _randomizer.nextInt(rows)))
        .toList();

    _createMaze();
  }


  final Color playerColor;
  ///Images for checkpoints
  final List<ui.Image> checkpointsImages;

  ///Number of collums
  final int columns;

  ///Image for player
  final ui.Image? finishImage;

  ///Callback when the player reach a checkpoint
  final Function(int)? onCheckpoint;

  ///Callback when the player reach the finish
  final Function? onFinish;
  final Function(List<PathItem>)? onDrawPath;

  ///Image for player
  late final ui.Image playerImage;
  late final ui.Image playerImageUp;
  late final ui.Image playerImageDown;
  late final ui.Image playerImageLeft;
  late final ui.Image playerImageRight;

  ///Number of rows
  final int rows;

  ///Color of the walls
  Color wallColor;

  ///Size of the walls
  final double wallThickness;

  ///Private attributes
  late Cell _player, _exit;
  late List<ItemPosition> _checkpointsPositions;
  late List<List<Cell>> _cells;
  late List<ui.Image> _checkpoints;
  late double _cellSize, _hMargin, _vMargin;

  ///Paints for `exit`, `player` and `walls`
  final Paint _exitPaint = Paint();
  final Paint _playerPaint = Paint();
  final Paint _wallPaint = Paint();

  ///Randomizer for positions and walls distribution
  final math.Random _randomizer = math.Random();

  ///Position of user from event
  late double _userX;
  late double _userY;

  late double centerX;
  late double centerY;

  double playerRotation = 0.0;

  Direction currentdirection = Direction.right;
  Direction playerdirection = Direction.right;

  List<Cell>? solution;
  final Set<Cell> _visitedCells = {};

  bool isSolSelect = false;

  ///This method initialize the maze by randomizing what wall will be disable
  void _createMaze() {
    var stack = Stack<Cell>();
    var stackpop = Stack<Cell>();
    Cell current;
    Cell? next;

    _cells = List.generate(
      columns,
      (index1) => List.generate(
        rows,
        (index2) => Cell(index1, index2),
      ),
    );

    _player = _cells.first.first;
    _exit = _cells.last.last;

    current = _cells.first.first..visited = true;
    _visitedCells.add(current); // store the first cell as visited
    do {
      next = _getNext(current);
      if (next != null) {
        _removeWall(current, next);
        stack.push(current);
        current = next..visited = true;
        _visitedCells.add(current); // store the next cell as visited
      } else {
        current = stack.pop();
      }
    } while (stack.isNotEmpty);
  }

  @override
  bool hitTest(Offset position) {
    return true;
  }

  /// This method moves player to user input
  void movePlayer(Direction direction) async {
    // Update the playerRotation angle based on the currentdirection
    switch (direction) {
      case Direction.up:
        {
          currentdirection = Direction.up;
          playerRotation = 0.0;
          if (!_player.topWall) _player = _cells[_player.col][_player.row - 1];
          break;
        }
      case Direction.down:
        {
          currentdirection = Direction.down;
          playerRotation = math.pi;
          if (!_player.bottomWall) {
            _player = _cells[_player.col][_player.row + 1];
          }
          break;
        }
      case Direction.left:
        {
          currentdirection = Direction.left;
          playerRotation = -math.pi / 2;
          if (!_player.leftWall) _player = _cells[_player.col - 1][_player.row];
          break;
        }
      case Direction.right:
        {
          currentdirection = Direction.right;
          playerRotation = math.pi / 2;
          if (!_player.rightWall) {
            _player = _cells[_player.col + 1][_player.row];
          }
          break;
        }
    }

    // Notify the listeners
    notifyListeners();

    final result = _getItemPosition(_player.col, _player.row);

    if (result != null) {
      final checkpointIndex = _checkpointsPositions.indexOf(result);
      final image = _checkpoints[checkpointIndex];
      _checkpoints.remove(image);
      _checkpointsPositions.removeAt(checkpointIndex);
      if (onCheckpoint != null) {
        onCheckpoint!(checkpointsImages.indexOf(image));
      }
    }

    if (_player.col == _exit.col && _player.row == _exit.row) {
      if (isSolSelect) {
        solution = await computeSolutionPath(Cell(_player.col, _player.row));
        notifyListeners();
      }
      if (onFinish != null) {
        onFinish!();
      }
    } else {
      if (isSolSelect) {
        solution = await computeSolutionPath(Cell(_player.col, _player.row));
        notifyListeners();
      }
    }
  }

  Direction getPlayerDirection(double rotation) {
    // Normalize the rotation angle to be between 0 and 360 degrees
    rotation %= 360.0;

    if (rotation >= 45.0 && rotation < 135.0) {
      return Direction.down;
    } else if (rotation >= 135.0 && rotation < 225.0) {
      return Direction.left;
    } else if (rotation >= 225.0 && rotation < 315.0) {
      return Direction.up;
    } else {
      return Direction.right;
    }
  }

  ///This method is used to notify the user drag position change to the maze
  ///and perfom the movement
  void updatePosition(Offset position) {
    _userX = position.dx;
    _userY = position.dy;
    notifyListeners();

    var playerCenterX = _hMargin + (_player.col + 0.5) * _cellSize;
    var playerCenterY = _vMargin + (_player.row + 0.5) * _cellSize;

    var dx = _userX - playerCenterX;
    var dy = _userY - playerCenterY;

    var absDx = dx.abs();
    var absDy = dy.abs();

    if (absDx > _cellSize || absDy > _cellSize) {
      if (absDx > absDy) {
        // X
        if (dx > 0) {
          movePlayer(Direction.right);
        } else {
          movePlayer(Direction.left);
        }
      } else {
        // Y
        if (dy > 0) {
          movePlayer(Direction.down);
        } else {
          movePlayer(Direction.up);
        }
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) async {
    //get cell size
    if (size.width / size.height < columns / rows) {
      _cellSize = size.width / (columns + 1);
    } else {
      _cellSize = size.height / (rows + 1);
    }

    //margin
    _hMargin = (size.width - columns * _cellSize) / 2;
    _vMargin = (size.height - rows * _cellSize) / 2;
    var squareMargin = _cellSize / 10;
    canvas.translate(_hMargin, _vMargin);
    for (var v in _cells) {
      for (int i = 0; i < v.length; i++) {
        PathItem pathItem = PathItem();
        if (v[i].topWall) {
          canvas.drawLine(
              Offset(v[i].col * _cellSize, v[i].row * _cellSize),
              Offset((v[i].col + 1) * _cellSize, v[i].row * _cellSize),
              _wallPaint);
        }

        if (v[i].leftWall) {
          canvas.drawLine(
              Offset(v[i].col * _cellSize, v[i].row * _cellSize),
              Offset(v[i].col * _cellSize, (v[i].row + 1) * _cellSize),
              _wallPaint);
        }

        if (v[i].bottomWall) {
          canvas.drawLine(
              Offset(v[i].col * _cellSize, (v[i].row + 1) * _cellSize),
              Offset((v[i].col + 1) * _cellSize, (v[i].row + 1) * _cellSize),
              _wallPaint);
        }

        if (v[i].rightWall) {
          canvas.drawLine(
              Offset((v[i].col + 1) * _cellSize, v[i].row * _cellSize),
              Offset((v[i].col + 1) * _cellSize, (v[i].row + 1) * _cellSize),
              _wallPaint);
        }
      }
    }

    // Draw the solution path
    if (solution != null) {
      // draw the solution path if it exists
      // set the paint color to red for the solution path
      Paint paint = Paint()..color = Colors.green;

      // iterate over the cells in the solution path
      for (Cell cell in solution!) {
        // calculate the pixel position of the center of the cell
        centerX = (cell.col + 0.5) * _cellSize;
        centerY = (cell.row + 0.5) * _cellSize;

        // draw a small dot at the center of the cell to indicate it is part of the solution path
        canvas.drawCircle(Offset(centerX, centerY), _cellSize / 20, paint);
      }
    }

    // draw others
    if (finishImage != null) {
      canvas.drawImageRect(
        finishImage!,
        Offset.zero &
            Size(finishImage!.width.toDouble(), finishImage!.height.toDouble()),
        Offset(
              _exit.col * _cellSize +
                  (_cellSize - _cellSize * 0.7) / 2 +
                  squareMargin,
              _exit.row * _cellSize +
                  (_cellSize - _cellSize * 0.7) / 2 +
                  squareMargin,
            ) &
            Size(
                _cellSize * 0.6 - squareMargin, _cellSize * 0.7 - squareMargin),
        _exitPaint,
      );
    } else {
      canvas.drawRect(
          Rect.fromPoints(
              Offset(_exit.col * _cellSize + squareMargin,
                  _exit.row * _cellSize + squareMargin),
              Offset((_exit.col + 1) * _cellSize - squareMargin,
                  (_exit.row + 1) * _cellSize - squareMargin)),
          _exitPaint);
    }

    for (var i = 0; i < _checkpoints.length; i++) {
      canvas.drawImageRect(
          _checkpoints[i],
          Offset.zero &
              Size(_checkpoints[i].width.toDouble(),
                  _checkpoints[i].height.toDouble()),
          Offset(_checkpointsPositions[i].col * _cellSize + squareMargin,
                  _checkpointsPositions[i].row * _cellSize + squareMargin) &
              Size(_cellSize - squareMargin, _cellSize - squareMargin),
          _wallPaint);
    }

    // Draw the player image

    double rotationAngle = 0.0;
    switch (currentdirection) {
      case Direction.up:
        rotationAngle = 0.0;
        canvas.drawImageRect(
          playerImageUp,
          Offset.zero &
          Size(playerImageUp.width.toDouble(), playerImageUp.height.toDouble()),
          Offset(
            _player.col * _cellSize +
                (_cellSize - _cellSize * 0.6) / 2 +
                squareMargin,
            _player.row * _cellSize +
                (_cellSize - _cellSize * 0.6) / 2 +
                squareMargin,
          ) &
          Size(
              _cellSize * 0.6 - squareMargin, _cellSize * 0.6 - squareMargin),
          _playerPaint,
        );
        break;
      case Direction.right:
        rotationAngle = math.pi / 2;
        canvas.drawImageRect(
          playerImageRight,
          Offset.zero &
          Size(playerImageRight.width.toDouble(), playerImageRight.height.toDouble()),
          Offset(
            _player.col * _cellSize +
                (_cellSize - _cellSize * 0.6) / 2 +
                squareMargin,
            _player.row * _cellSize +
                (_cellSize - _cellSize * 0.6) / 2 +
                squareMargin,
          ) &
          Size(
              _cellSize * 0.6 - squareMargin, _cellSize * 0.6 - squareMargin),
          _playerPaint,
        );
        break;
      case Direction.down:
        rotationAngle = math.pi;
        canvas.drawImageRect(
          playerImageDown,
          Offset.zero &
          Size(playerImageDown.width.toDouble(), playerImageDown.height.toDouble()),
          Offset(
            _player.col * _cellSize +
                (_cellSize - _cellSize * 0.6) / 2 +
                squareMargin,
            _player.row * _cellSize +
                (_cellSize - _cellSize * 0.6) / 2 +
                squareMargin,
          ) &
          Size(
              _cellSize * 0.6 - squareMargin, _cellSize * 0.6 - squareMargin),
          _playerPaint,
        );
        break;
      case Direction.left:
        rotationAngle = -math.pi / 2;
        canvas.drawImageRect(
          playerImageLeft,
          Offset.zero &
          Size(playerImageLeft.width.toDouble(), playerImageLeft.height.toDouble()),
          Offset(
            _player.col * _cellSize +
                (_cellSize - _cellSize * 0.6) / 2 +
                squareMargin,
            _player.row * _cellSize +
                (_cellSize - _cellSize * 0.6) / 2 +
                squareMargin,
          ) &
          Size(
              _cellSize * 0.6 - squareMargin, _cellSize * 0.6 - squareMargin),
          _playerPaint,
        );
        break;
    }
  }

  // Utility function to load an image
  Future<ui.Image> loadImage(String path) async {
    final ByteData data = await rootBundle.load(path);
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  @override
  List<CustomPainterSemantics> Function(Size)? get semanticsBuilder => null;

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) {
    return false;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  Cell? _getNext(Cell cell) {
    var neighbours = <Cell>[];

    //left
    if (cell.col > 0) {
      if (!_cells[cell.col - 1][cell.row].visited) {
        neighbours.add(_cells[cell.col - 1][cell.row]);
      }
    }

    //right
    if (cell.col < columns - 1) {
      if (!_cells[cell.col + 1][cell.row].visited) {
        neighbours.add(_cells[cell.col + 1][cell.row]);
      }
    }

    //Top
    if (cell.row > 0) {
      if (!_cells[cell.col][cell.row - 1].visited) {
        neighbours.add(_cells[cell.col][cell.row - 1]);
      }
    }

    //Bottom
    if (cell.row < rows - 1) {
      if (!_cells[cell.col][cell.row + 1].visited) {
        neighbours.add(_cells[cell.col][cell.row + 1]);
      }
    }
    if (neighbours.isNotEmpty) {
      final index = _randomizer.nextInt(neighbours.length);
      return neighbours[index];
    }
    return null;
  }

  void _removeWall(Cell current, Cell next) {
    //Below
    if (current.col == next.col && current.row == next.row + 1) {
      current.topWall = false;
      next.bottomWall = false;
    }

    //Above
    if (current.col == next.col && current.row == next.row - 1) {
      current.bottomWall = false;
      next.topWall = false;
    }

    //right
    if (current.col == next.col + 1 && current.row == next.row) {
      current.leftWall = false;
      next.rightWall = false;
    }

    //left
    if (current.col == next.col - 1 && current.row == next.row) {
      current.rightWall = false;
      next.leftWall = false;
    }
  }

  ItemPosition? _getItemPosition(int col, int row) {
    try {
      return _checkpointsPositions.singleWhere(
          (element) => element == ItemPosition(col: col, row: row));
    } catch (e) {
      return null;
    }
  }

  void removeSolution() {
    isSolSelect = false;
    solution = null;
  }

  Future<List<Cell>> computeSolutionPath(Cell startCell) async {
    var endCell = _cells.last.last;
    var queue = Queue<List<Cell>>();
    queue.add([startCell]);
    while (queue.isNotEmpty) {
      var path = queue.removeFirst();
      var currentCell = path.last;
      if (currentCell == endCell) {
        return path;
      }
      for (var neighbor in _getNeighbors(currentCell)) {
        if (_visitedCells.contains(neighbor) && !path.contains(neighbor)) {
          List<Cell> newPath = List.from(path)..add(neighbor);
          queue.add(newPath);
        }
      }
    }

    return []; // no solution found
  }

  List<Cell> _getNeighbors(Cell cell) {
    var neighbors = <Cell>[];
//left
    if (cell.col > 0) {
      if (!_cells[cell.col][cell.row].leftWall) {
        if (!_cells[cell.col - 1][cell.row].rightWall) {
          neighbors.add(_cells[cell.col - 1][cell.row]);
        }
      }
    }

    //top
    if (cell.row > 0) {
      if (!_cells[cell.col][cell.row].topWall) {
        //next cell should not have bottom wall
        if (!_cells[cell.col][cell.row - 1].bottomWall) {
          neighbors.add(_cells[cell.col][cell.row - 1]);
        }
      }
    }

    //right
    if (cell.col < columns - 1) {
      if (!_cells[cell.col][cell.row].rightWall) {
        //next cell should not have left wall
        if (!_cells[cell.col + 1][cell.row].leftWall) {
          neighbors.add(_cells[cell.col + 1][cell.row]);
        }
      }
    }

    //bottom
    if (cell.row < rows - 1) {
      if (!_cells[cell.col][cell.row].bottomWall) {
        //next cell should not have top wall
        if (!_cells[cell.col][cell.row + 1].topWall) {
          neighbors.add(_cells[cell.col][cell.row + 1]);
        }
      }
    }

    return neighbors.where((c) => !c.isVisited).toList();
  }

  List<Cell> getUnvisitedNeighbors(Cell cell) {
    List<Cell> neighbours = [];

    //left
    if (cell.col > 0) {
      if (!_cells[cell.col - 1][cell.row].isVisited) {
        //current cell left wall check
        if (!_cells[cell.col][cell.row].leftWall) {
          //next cell should not have right wall
          if (!_cells[cell.col - 1][cell.row].rightWall) {
            neighbours.add(_cells[cell.col - 1][cell.row]);
            _cells[cell.col - 1][cell.row].isVisited = true;
          }
        }
      }
    }

    //right
    if (cell.col < columns - 1) {
      if (_cells.length != cell.col + 1) {
        if (!_cells[cell.col + 1][cell.row].isVisited) {
          //current cell right wall check
          if (!_cells[cell.col][cell.row].rightWall) {
            //next cell should not have left wall
            if (!_cells[cell.col + 1][cell.row].leftWall) {
              neighbours.add(_cells[cell.col + 1][cell.row]);
              _cells[cell.col + 1][cell.row].isVisited = true;
            }
          }
        }
      }
    }

    //Top
    if (cell.row > 0) {
      if (!_cells[cell.col][cell.row - 1].isVisited) {
        //current cell top wall check
        if (!_cells[cell.col][cell.row].topWall) {
          //next cell should not have bottom wall
          if (!_cells[cell.col][cell.row - 1].bottomWall) {
            neighbours.add(_cells[cell.col][cell.row - 1]);
            _cells[cell.col][cell.row - 1].isVisited = true;
          }
        }
      }
    }

    //Bottom
    if (cell.row < rows - 1) {
      if (_cells.length != cell.col + 1) {
        if (!_cells[cell.col][cell.row + 1].isVisited) {
          //current cell bottom wall check
          if (!_cells[cell.col][cell.row].bottomWall) {
            //next cell should not have top wall
            if (!_cells[cell.col][cell.row + 1].topWall) {
              neighbours.add(_cells[cell.col][cell.row + 1]);
              _cells[cell.col][cell.row + 1].isVisited = true;
            }
          }
        }
      }
    }

    return neighbours;
  }
}
