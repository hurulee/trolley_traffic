import 'dart:math';
import 'package:flutter/material.dart';
import 'maze.dart';
import 'models.dart';

class EnemyTrolley {
  final double cellSize;
  final MazeComponent maze;
  final int startCol;
  final int startRow;

  int gridCol;
  int gridRow;
  late double centerX;
  late double centerY;

  Direction direction = Direction.right;
  final _rng = Random();

  EnemyTrolley({
    required this.cellSize,
    required this.maze,
    required this.startCol,
    required this.startRow,
  })  : gridCol = startCol,
        gridRow = startRow {
    centerX = _cellCenter(startCol);
    centerY = _cellCenter(startRow);
    // Pick a random initial direction that is walkable
    _pickDirection();
  }

  double _cellCenter(int index) => (index + 0.5) * cellSize;

  void reset() {
    gridCol = startCol;
    gridRow = startRow;
    centerX = _cellCenter(startCol);
    centerY = _cellCenter(startRow);
    _pickDirection();
  }

  /// Choose a random valid direction, preferring not to reverse.
  void _pickDirection({Direction? avoid}) {
    final candidates = Direction.values.where((d) {
      if (d == avoid) return false;
      return maze.canMove(gridCol, gridRow, d);
    }).toList();

    if (candidates.isEmpty) {
      // Forced reversal
      if (avoid != null && maze.canMove(gridCol, gridRow, avoid)) {
        direction = avoid;
      }
      return;
    }
    candidates.shuffle(_rng);
    direction = candidates.first;
  }

  void update(double dt) {
    final speed   = kTrolleySpeed * cellSize;
    final nextCol = gridCol + direction.dx;
    final nextRow = gridRow + direction.dy;

    if (!maze.isWalkable(nextCol, nextRow)) {
      _pickDirection(avoid: direction.opposite);
      return;
    }

    centerX += direction.dx * speed * dt;
    centerY += direction.dy * speed * dt;

    final targetX = _cellCenter(nextCol);
    final targetY = _cellCenter(nextRow);

    final reached = (direction.dx > 0 && centerX >= targetX) ||
                    (direction.dx < 0 && centerX <= targetX) ||
                    (direction.dy > 0 && centerY >= targetY) ||
                    (direction.dy < 0 && centerY <= targetY);

    if (reached) {
      centerX = targetX;
      centerY = targetY;
      gridCol = nextCol;
      gridRow = nextRow;

      // At each intersection, randomly pick a new direction
      if (_isIntersection(gridCol, gridRow)) {
        _pickDirection(avoid: direction.opposite);
      }
    }
  }

  bool _isIntersection(int col, int row) =>
      col % kStreetStep == 0 && row % kStreetStep == 0;

  void render(Canvas canvas) {
    final isHorizontal = direction.dx != 0;
    final long  = cellSize * 1.7;
    final short = cellSize * 0.55;

    final w = isHorizontal ? long  : short;
    final h = isHorizontal ? short : long;

    final cx = centerX.clamp(w / 2, kCols * cellSize - w / 2);
    final cy = centerY.clamp(h / 2, kRows * cellSize - h / 2);

    // Body — yellow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
        Radius.circular(cellSize * 0.12),
      ),
      Paint()..color = const Color(0xFFF1C40F),
    );

    // Direction indicator at the front
    final notchOffset = Offset(direction.dx * w * 0.38, direction.dy * h * 0.38);
    canvas.drawCircle(
      Offset(cx + notchOffset.dx, cy + notchOffset.dy),
      cellSize * 0.1,
      Paint()..color = const Color(0xFF2C2C2C),
    );
  }
}

/// Fixed spawn points spread around the grid (all on intersections).
const List<(int, int)> kEnemySpawns = [
  (20, 20), // bottom-right
  (0,  20), // bottom-left
  (20,  0), // top-right
  (10, 10), // centre
  (10,  0), // top-centre
];
