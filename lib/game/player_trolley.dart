import 'dart:math';
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
  double _renderAngle = 0.0; // smoothly follows direction.angle

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

  void snapStop() => isMoving = false;

  static double _shortestDelta(double from, double to) {
    double d = to - from;
    while (d >  pi) d -= 2 * pi;
    while (d < -pi) d += 2 * pi;
    return d;
  }

  void update(double dt) {
    // Smoothly rotate render angle toward current direction
    final delta = _shortestDelta(_renderAngle, direction.angle);
    if (delta.abs() <= kTurnSpeed * dt) {
      _renderAngle = direction.angle;
    } else {
      _renderAngle += delta.sign * kTurnSpeed * dt;
    }

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
    final long  = cellSize * 1.7;
    final short = cellSize * 0.55;

    // Clamp using direction-aligned extents (game direction is always up-to-date)
    final isHorizontal = direction.dx != 0;
    final w = isHorizontal ? long : short;
    final h = isHorizontal ? short : long;
    final cx = centerX.clamp(w / 2, kCols * cellSize - w / 2);
    final cy = centerY.clamp(h / 2, kRows * cellSize - h / 2);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_renderAngle);

    // Body drawn as horizontal; rotation handles orientation
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: long, height: short),
        Radius.circular(cellSize * 0.12),
      ),
      Paint()..color = const Color(0xFFE74C3C),
    );

    // Front notch always at the +x side before rotation
    canvas.drawCircle(
      Offset(long * 0.38, 0),
      cellSize * 0.1,
      Paint()..color = const Color(0xFFFFFFFF),
    );

    canvas.restore();
  }
}
