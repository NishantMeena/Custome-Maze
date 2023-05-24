import 'dart:math';

class Coordinate {
  final int x;
  final int y;

  Coordinate({required this.x, required this.y});

  @override
  bool operator ==(other) {
    if (other is Coordinate) {
      return x == other.x && y == other.y;
    }
    return false;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() {
    return '($x, $y)';
  }
}
