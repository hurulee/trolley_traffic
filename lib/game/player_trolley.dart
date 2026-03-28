import 'package:flutter/material.dart';
import 'maze.dart';
import 'models.dart';

class PlayerTrolley {
  final double cellSize;
  final MazeComponent maze;

  int gridCol;
  int gridRow;
  late double centerX;
  late double centerY;

  Direction direction = Direction.right;
  Direction? _queued;
  bool isMoving = true;

  PlayerTrolley({
    required this.gridCol,
    required this.gridRow,
    required this.cellSize,
    required this.maze,
  }) {
    centerX = _cellCenter(gridCol);
    centerY = _cellCenter(gridRow);
  }

  double _cellCenter(int index) => (index + 0.5) * cellSize;

  void queueDirection(Direction dir) {
    if (dir == direction.opposite) {
      // Reversal — apply immediately so the trolley backs up without waiting
      // for the next intersection.
      direction = dir;
      _queued   = null;
    } else {
      _queued = dir;
    }
  }

  /// Snap to the centre of the current grid cell (call on STOP so boarding
  /// detection works cleanly against integer grid coordinates).
  void snapStop() {
    centerX = _cellCenter(gridCol);
    centerY = _cellCenter(gridRow);
    isMoving = false;
  }

  void update(double dt) {
    if (!isMoving) return;
    final speed  = kTrolleySpeed * cellSize;
    final nextCol = gridCol + direction.dx;
    final nextRow = gridRow + direction.dy;

    if (!maze.isWalkable(nextCol, nextRow)) {
      // Blocked — try the queued direction in place
      if (_queued != null && maze.canMove(gridCol, gridRow, _queued!)) {
        direction = _queued!;
        _queued   = null;
      }
      return;
    }

    // Move toward the centre of the next cell
    centerX += direction.dx * speed * dt;
    centerY += direction.dy * speed * dt;

    final targetX = _cellCenter(nextCol);
    final targetY = _cellCenter(nextRow);

    final reached = (direction.dx > 0 && centerX >= targetX) ||
                    (direction.dx < 0 && centerX <= targetX) ||
                    (direction.dy > 0 && centerY >= targetY) ||
                    (direction.dy < 0 && centerY <= targetY);

    if (reached) {
      centerX  = targetX;
      centerY  = targetY;
      gridCol  = nextCol;
      gridRow  = nextRow;

      // Apply queued direction if the turn is valid here
      if (_queued != null && maze.canMove(gridCol, gridRow, _queued!)) {
        direction = _queued!;
        _queued   = null;
      }
    }
  }

  void render(Canvas canvas) {
    final half = cellSize * 0.38;

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, centerY), width: half * 2, height: half * 2),
        Radius.circular(cellSize * 0.12),
      ),
      Paint()..color = const Color(0xFFE74C3C),
    );

    // Direction indicator (small notch on the front)
    final notchOffset = Offset(direction.dx * half * 0.6, direction.dy * half * 0.6);
    canvas.drawCircle(
      Offset(centerX + notchOffset.dx, centerY + notchOffset.dy),
      cellSize * 0.1,
      Paint()..color = const Color(0xFFFFFFFF),
    );
  }
}
