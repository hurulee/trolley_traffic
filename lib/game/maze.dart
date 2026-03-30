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

  // 8×3 block (cols 3-12, rows 13-17): vertical strip at col 8 (offset for variety)
  (8, 14), (8, 15), (8, 16),

  // 8×3 block (cols 3-12, rows 17-21): vertical strip at col 7
  (7, 18), (7, 19), (7, 20),

  // 8×3 block (cols 3-12, rows 21-25): vertical strip at col 8
  (8, 22), (8, 23), (8, 24),

  // 3×8 block (cols 12-16, rows 4-13): horizontal strip at row 9
  (13, 9), (14, 9), (15, 9),

  // 3×8 block (cols 16-20, rows 4-13): horizontal strip at row 8
  (17, 8), (18, 8), (19, 8),
];

final _innerStreetSet = Set<(int, int)>.unmodifiable(kInnerStreetCells);

// ── Perimeter gaps ────────────────────────────────────────────────────────────
// Cells that are on a street row/col but are blocked, forcing players to turn
// rather than travel straight along the full perimeter.
const List<(int, int)> kExcludedStreetCells = [
  // Top (row 0): remove long middle segment cols 4–11
  (4,0),(5,0),(6,0),(7,0),(8,0),(9,0),(10,0),(11,0),
  // Bottom (row 25): remove segment cols 13–15
  (13,25),(14,25),(15,25),
  // Left (col 0): remove long middle segment rows 5–12
  (0,5),(0,6),(0,7),(0,8),(0,9),(0,10),(0,11),(0,12),
  // Right (col 20): remove segment rows 14–16
  (20,14),(20,15),(20,16),
];

final _excludedStreetSet = Set<(int, int)>.unmodifiable(kExcludedStreetCells);

bool isMazeStreet(int col, int row) {
  if (_excludedStreetSet.contains((col, row))) return false;
  return _streetColSet.contains(col) ||
      _streetRowSet.contains(row) ||
      _innerStreetSet.contains((col, row));
}

/// Like [isMazeStreet] but returns false for out-of-bounds cells.
bool _isStreet(int col, int row) {
  if (col < 0 || col >= kCols || row < 0 || row >= kRows) return false;
  return isMazeStreet(col, row);
}

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
    final streetPaint = Paint()..color = _streetColor;
    final buildPaint  = Paint()..color = _buildingColor;
    final edgePaint   = Paint()
      ..color       = _buildingEdge
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 1. Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, kCols * cellSize, kRows * cellSize),
      Paint()..color = _bgColor,
    );

    // 2. Streets
    for (int row = 0; row < kRows; row++) {
      for (int col = 0; col < kCols; col++) {
        if (isMazeStreet(col, row)) {
          canvas.drawRect(
            Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
            streetPaint,
          );
        }
      }
    }

    // 3. Draw block fills
    for (int i = 0; i < kStreetCols.length - 1; i++) {
      for (int j = 0; j < kStreetRows.length - 1; j++) {
        final c1 = kStreetCols[i] + 1;
        final c2 = kStreetCols[i + 1] - 1;
        final r1 = kStreetRows[j] + 1;
        final r2 = kStreetRows[j + 1] - 1;
        if (c1 > c2 || r1 > r2) continue;
        canvas.drawRect(
          Rect.fromLTRB(c1 * cellSize, r1 * cellSize,
                        (c2 + 1) * cellSize, (r2 + 1) * cellSize),
          buildPaint,
        );
      }
    }

    // 4. Inner streets on top of block fills
    for (final (col, row) in kInnerStreetCells) {
      canvas.drawRect(
        Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
        streetPaint,
      );
    }

    // 5. Per-cell rounded corners — round any building-cell corner where
    //    both orthogonal neighbours are streets.
    final cr = cellSize * 0.45;
    for (int row = 0; row < kRows; row++) {
      for (int col = 0; col < kCols; col++) {
        if (isMazeStreet(col, row)) continue;
        final x = col * cellSize;
        final y = row * cellSize;
        final cs = cellSize; // alias for readability

        // Top-left
        if (_isStreet(col - 1, row) && _isStreet(col, row - 1)) {
          canvas.drawRect(Rect.fromLTWH(x, y, cr, cr), streetPaint);
          canvas.drawCircle(Offset(x + cr, y + cr), cr, buildPaint);
        }
        // Top-right
        if (_isStreet(col + 1, row) && _isStreet(col, row - 1)) {
          canvas.drawRect(Rect.fromLTWH(x + cs - cr, y, cr, cr), streetPaint);
          canvas.drawCircle(Offset(x + cs - cr, y + cr), cr, buildPaint);
        }
        // Bottom-left
        if (_isStreet(col - 1, row) && _isStreet(col, row + 1)) {
          canvas.drawRect(Rect.fromLTWH(x, y + cs - cr, cr, cr), streetPaint);
          canvas.drawCircle(Offset(x + cr, y + cs - cr), cr, buildPaint);
        }
        // Bottom-right
        if (_isStreet(col + 1, row) && _isStreet(col, row + 1)) {
          canvas.drawRect(Rect.fromLTWH(x + cs - cr, y + cs - cr, cr, cr), streetPaint);
          canvas.drawCircle(Offset(x + cs - cr, y + cs - cr), cr, buildPaint);
        }
      }
    }

    // 6. Border strokes for outer-grid blocks
    for (int i = 0; i < kStreetCols.length - 1; i++) {
      for (int j = 0; j < kStreetRows.length - 1; j++) {
        final c1 = kStreetCols[i] + 1;
        final c2 = kStreetCols[i + 1] - 1;
        final r1 = kStreetRows[j] + 1;
        final r2 = kStreetRows[j + 1] - 1;
        if (c1 > c2 || r1 > r2) continue;

        final l = c1 * cellSize;
        final t = r1 * cellSize;
        final r = (c2 + 1) * cellSize;
        final b = (r2 + 1) * cellSize;
        final blockRect = Rect.fromLTRB(l, t, r, b);

        final maxR = ((r - l) < (b - t) ? (r - l) : (b - t)) / 2;
        final bCr = cr < maxR ? cr : maxR;

        final sc1 = kStreetCols[i];
        final sc2 = kStreetCols[i + 1];
        final sr1 = kStreetRows[j];
        final sr2 = kStreetRows[j + 1];

        canvas.drawRRect(
          RRect.fromRectAndCorners(
            blockRect.deflate(1.5),
            topLeft:     Radius.circular(_isStreet(sc1, sr1) ? bCr : 0),
            topRight:    Radius.circular(_isStreet(sc2, sr1) ? bCr : 0),
            bottomLeft:  Radius.circular(_isStreet(sc1, sr2) ? bCr : 0),
            bottomRight: Radius.circular(_isStreet(sc2, sr2) ? bCr : 0),
          ),
          edgePaint,
        );
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
