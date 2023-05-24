import 'dart:collection';
import 'package:custom_mazeapp/models/cell.dart';

class MazeSolver {
  late List<List<Cell>> cells;
  late int rows;
  late int columns;
  late Cell startCell;
  late Cell endCell;
  late List<Cell> solutionPath;

  MazeSolver(this.cells) {
    rows = cells.length;
    columns = cells[0].length;
    startCell = cells[0][0];
    endCell = cells[rows - 1][columns - 1];
    solutionPath = [];
  }

  List<Cell>? solve() {
    final start = cells[0][0];
    final end = cells[cells.length - 1][cells[0].length - 1];

    solutionPath.clear();
    final stack = Queue<Cell>();
    stack.add(start);
    startCell.isVisited = true;


    Map<Cell, Cell> cameFrom = Map();
    cameFrom[startCell];

    while (stack.isNotEmpty) {
      var currentCell = stack.removeLast();

      if (currentCell == end) {
        //solutionPath.add(currentCell);
        solutionPath=constructSolutionPath(cameFrom, endCell);
        return solutionPath;
      }

      if (!solutionPath.contains(currentCell)) {
        solutionPath.add(currentCell);


        final neighbors = getUnvisitedNeighbors(currentCell);
        if (neighbors.isNotEmpty) {
          /*for (Cell next in neighbors) {
            print("${next.row}");
            List<Cell> nextPath = List.from(solutionPath)..add(next);
            //solutionPath.add(next);
            currentCell=next;
            next.parent = currentCell;
            stack.add(next);
          }*/

          neighbors.forEach((cell) {
            cell.parent = currentCell;
            cell.isVisited = true;
            stack.add(cell);
          });
        } else {
          solutionPath.removeLast();
        }
      }
    }

    return null;
  }



  List<Cell> constructSolutionPath(Map<Cell, Cell> cameFrom, Cell endCell) {
    List<Cell> path = [];

    Cell? currentCell = endCell;
    while (currentCell != null) {
      path.add(currentCell);
      currentCell = cameFrom[currentCell];
    }

    return path.reversed.toList();
  }

  List<Cell> getUnvisitedNeighbors(Cell cell) {
    List<Cell> neighbours = [];

    //left
    if (cell.col > 0) {
      if (!cells[cell.col - 1][cell.row].isVisited) {
        //current cell left wall check
        if (!cells[cell.col][cell.row].leftWall) {
          //next cell should not have right wall
          if (!cells[cell.col - 1][cell.row].rightWall) {
            neighbours.add(cells[cell.col - 1][cell.row]);
          }
        }
      }
    }

    //right
    if (cell.col < columns - 1) {
      if (cells.length != cell.col + 1) {
        if (!cells[cell.col + 1][cell.row].isVisited) {
          //current cell right wall check
          if (!cells[cell.col][cell.row].rightWall) {
            //next cell should not have left wall
            if (!cells[cell.col + 1][cell.row].leftWall) {
              neighbours.add(cells[cell.col + 1][cell.row]);
            }
          }
        }
      }
    }

    //Top
    if (cell.row > 0) {
      if (!cells[cell.col][cell.row - 1].isVisited) {
        //current cell top wall check
        if (!cells[cell.col][cell.row].topWall) {
          //next cell should not have bottom wall
          if (!cells[cell.col][cell.row - 1].bottomWall) {
            neighbours.add(cells[cell.col][cell.row - 1]);
          }
        }
      }
    }

    //Bottom
    if (cell.row < rows - 1) {
      if (cells.length != cell.col + 1) {
        if (!cells[cell.col][cell.row + 1].isVisited) {
          //current cell bottom wall check
          if (!cells[cell.col][cell.row].bottomWall) {
            //next cell should not have top wall
            if (!cells[cell.col][cell.row + 1].topWall) {
              neighbours.add(cells[cell.col][cell.row + 1]);
            }
          }
        }
      }
    }

    return neighbours;
  }
}