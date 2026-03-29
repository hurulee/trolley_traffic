import 'package:flutter/material.dart';
import 'models.dart';

// Grid dimensions — streets fall on every kStreetStep-th column and row,
// producing a regular city-block pattern with no dead ends.
const int kCols       = 21;
const int kRows       = 26;
const int kStreetStep =  5; // street at indices 0, 5, 10, 15, 20, 25

bool isMazeStreet(int col, int row) =>
    col % kStreetStep == 0 || row % kStreetStep == 0;

class MazeComponent {
  final double cellSize;

  MazeComponent({required this.cellSize});

  // ── Colours ──────────────────────────────────────────────────────────────
  static const _bgColor       = Color(0xFF1A1A2E);
  static const _buildingColor = Color(0xFF16213E);
  static const _buildingEdge  = Color(0xFF0F3460);
  static const _streetColor   = Color(0xFF4A4A5A);
  static const _centerLine    = Color(0xFF6A6A7A);

  // ── Queries ───────────────────────────────────────────────────────────────
  bool isWalkable(int col, int row) {
    if (col < 0 || col >= kCols || row < 0 || row >= kRows) return false;
    return isMazeStreet(col, row);
  }

  bool canMove(int col, int row, Direction dir) =>
      isWalkable(col + dir.dx, row + dir.dy);

  // ── Rendering ─────────────────────────────────────────────────────────────
  void render(Canvas canvas) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, kCols * cellSize, kRows * cellSize),
      Paint()..color = _bgColor,
    );

    for (int row = 0; row < kRows; row++) {
      for (int col = 0; col < kCols; col++) {
        final rect = Rect.fromLTWH(
          col * cellSize, row * cellSize, cellSize, cellSize,
        );
        if (isMazeStreet(col, row)) {
          canvas.drawRect(rect, Paint()..color = _streetColor);
        } else {
          // Building body
          canvas.drawRect(rect, Paint()..color = _buildingColor);
          // Building edge highlight
          canvas.drawRect(
            rect.deflate(1.5),
            Paint()
              ..color = _buildingEdge
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0,
          );
        }
      }
    }

    _drawCenterLines(canvas);
  }

  void _drawCenterLines(Canvas canvas) {
    final paint = Paint()
      ..color = _centerLine.withValues(alpha: 0.25)
      ..strokeWidth = 1.0;

    for (int col = 0; col < kCols; col++) {
      if (col % kStreetStep == 0) {
        final x = col * cellSize + cellSize / 2;
        canvas.drawLine(
          Offset(x, 0), Offset(x, kRows * cellSize), paint,
        );
      }
    }
    for (int row = 0; row < kRows; row++) {
      if (row % kStreetStep == 0) {
        final y = row * cellSize + cellSize / 2;
        canvas.drawLine(
          Offset(0, y), Offset(kCols * cellSize, y), paint,
        );
      }
    }
  }
}
