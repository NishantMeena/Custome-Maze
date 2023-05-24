import 'dart:collection';

import 'package:custom_mazeapp/models/cell.dart';

class Solver {
  final List<List<Cell>> _maze;
  late int rows;
  late int columns;
  late Cell startCell;
  late Cell endCell;

  Solver(this._maze) {
    rows = _maze.length;
    columns = _maze[0].length;
    startCell = _maze[0][0];
    endCell = _maze[rows - 1][columns - 1];
  }

  List<Cell>? solve() {
    List<Cell> solution = [];

    Queue<Cell> queue = Queue<Cell>();
    queue.add(startCell);
    startCell.isVisited = true;

    Map<Cell, Cell> parents = {};

    while (queue.isNotEmpty) {
      Cell currentCell = queue.removeFirst();

      if (currentCell == endCell) {
        // Found the end cell, so build the solution path and return it
        solution.add(currentCell);

        Cell? parent = parents[currentCell];

        while (parent != startCell) {
          solution.add(parent!);
          parent = parents[parent];
        }

        solution.add(startCell);
        solution = solution.reversed.toList();

        return solution;
      }

      List<Cell> neighbors = getUnvisitedNeighbors(currentCell);

      for (Cell neighbor in neighbors) {
        neighbor.isVisited = true;
        queue.add(neighbor);
        parents[neighbor] = currentCell;
      }
    }

    // No solution found
    return null;
  }

  List<Cell> getUnvisitedNeighbors(Cell cell) {
    List<Cell> neighbors = [];

    int column = cell.col;
    int row = cell.row;

    // Check left neighbor
    if (column > 0 &&
        !_maze[column - 1][row].isVisited &&
        !cell.leftWall &&
        !_maze[column - 1][row].rightWall) {
      neighbors.add(_maze[column - 1][row]);
    }

    // Check right neighbor
    //column < _maze[row].length - 1
    if (row < columns - 1 &&
        !_maze[column + 1][row].isVisited &&
        !cell.rightWall &&
        !_maze[column + 1][row].leftWall) {
      neighbors.add(_maze[column + 1][row]);
    }

    // Check top neighbor
    if (row > 0 &&
        !_maze[column][row - 1].isVisited &&
        !cell.topWall &&
        !_maze[column][row - 1].bottomWall) {
      neighbors.add(_maze[column][row - 1]);
    }

    // Check bottom neighbor
    if (row < _maze.length - 1 &&
        !_maze[column][row + 1].isVisited &&
        !cell.bottomWall &&
        !_maze[column][row + 1].topWall) {
      neighbors.add(_maze[column][row + 1]);
    }

    return neighbors;
  }
}
