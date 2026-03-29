import 'package:flutter/material.dart';
import 'models.dart';

// Overall grid dimensions (cells)
const int kCols = 21;
const int kRows = 26;

// Irregular street positions — varying block sizes make the layout more
// interesting than a uniform grid. Must include 0 and the last index.
// Street positions — deliberately irregular to produce a mix of block shapes:
//   col gaps  : 2, 8, 3, 3  (one dominant wide gap)
//   row gaps  : 3, 8, 3, 3, 3  (one dominant tall gap)
// The intersection of the two 8-wide/tall gaps forms the single 8×8 block.
const List<int> kStreetCols = [0, 3, 12, 16, 20];
const List<int> kStreetRows = [0, 4, 13, 17, 21, 25];

// Fast lookup sets
final _streetColSet = Set<int>.unmodifiable(kStreetCols);
final _streetRowSet = Set<int>.unmodifiable(kStreetRows);

// ── Inner L-shaped paths ───────────────────────────────────────────────────
//
// Each group of 3 cells forms an L connecting two outer streets, enclosing a
// 1-cell island building block in the corner of a large block.
//
// Pattern: two cells run along one axis, one cell turns the corner.
// The island cell (not listed here) sits in the enclosed corner.
//
// L-shaped inner paths live only inside the 8×8 block (building cols 4–11,
// rows 5–12). Each uses 5 inner-street cells to enclose a 2×2 island.
// The two arms of the L each connect to a different outer street — no dead ends.
//
//  Arm layout for a top-right island (■■):
//
//    outer row ─────────────────
//              ·  ■ ■  ·         row n   (■ = island building cells)
//    left arm  ·  ■ ■  ·         row n+1
//              · [c][c][c] ·     row n+2  ← bottom arm
//                           │
//                      outer col (right)
//
const List<(int, int)> kInnerStreetCells = [
  // ── 8×8 block (cols 3-12, rows 4-13): single L-path with 3×3 island ──────
  //
  // Island: cols 9-11, rows 5-7 (top-right corner)
  //   top faces outer street row 4, right faces outer street col 12
  //   left arm: col 8, rows 5-8
  //   bottom arm: row 8, cols 9-11
  //
  (8, 5),  (8, 6),  (8, 7),  (8, 8),  (9, 8),  (10, 8), (11, 8),

  // ── Rectangle splitters ───────────────────────────────────────────────────
  // Each strip connects the two outer streets on the long sides, splitting
  // the rectangle along its narrow dimension.

  // 8×3 block (cols 3-12, rows 0-4): vertical strip at col 7
  (7, 1),  (7, 2),  (7, 3),

  // 8×3 block (cols 3-12, rows 13-17): vertical strip at col 8 (offset for variety)
  (8, 14), (8, 15), (8, 16),

  // 8×3 block (cols 3-12, rows 17-21): vertical strip at col 7
  (7, 18), (7, 19), (7, 20),

  // 8×3 block (cols 3-12, rows 21-25): vertical strip at col 8
  (8, 22), (8, 23), (8, 24),

  // 2×8 block (cols 0-3, rows 4-13): horizontal strip at row 8
  (1, 8),  (2, 8),

  // 3×8 block (cols 12-16, rows 4-13): horizontal strip at row 9
  (13, 9), (14, 9), (15, 9),

  // 3×8 block (cols 16-20, rows 4-13): horizontal strip at row 8
  (17, 8), (18, 8), (19, 8),
];

final _innerStreetSet = Set<(int, int)>.unmodifiable(kInnerStreetCells);

bool isMazeStreet(int col, int row) =>
    _streetColSet.contains(col) ||
    _streetRowSet.contains(row) ||
    _innerStreetSet.contains((col, row));

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
          canvas.drawRect(rect, Paint()..color = _buildingColor);
          canvas.drawRect(
            rect.deflate(1.5),
            Paint()
              ..color       = _buildingEdge
              ..style       = PaintingStyle.stroke
              ..strokeWidth = 1.0,
          );
        }
      }
    }

    _drawCenterLines(canvas);
  }

  void _drawCenterLines(Canvas canvas) {
    final paint = Paint()
      ..color       = _centerLine.withValues(alpha: 0.25)
      ..strokeWidth = 1.0;

    for (final col in kStreetCols) {
      final x = col * cellSize + cellSize / 2;
      canvas.drawLine(Offset(x, 0), Offset(x, kRows * cellSize), paint);
    }
    for (final row in kStreetRows) {
      final y = row * cellSize + cellSize / 2;
      canvas.drawLine(Offset(0, y), Offset(kCols * cellSize, y), paint);
    }
  }
}
