import 'dart:math';
import 'package:flutter/material.dart';
import 'maze.dart';

const double kBoardingRate = 1.0; // passengers boarded per second

enum _CanopyEdge { top, bottom, left, right }

class Station {
  final int col;
  final int row;
  int passengersWaiting;
  double _boardingAccum = 0.0;

  Station({
    required this.col,
    required this.row,
    required this.passengersWaiting,
  });

  bool get isComplete => passengersWaiting == 0;

  /// True when this station sits on a vertical street.
  bool get isVertical => kStreetCols.contains(col);

  /// Board passengers based on elapsed time. Returns the number boarded.
  int board(double dt) {
    if (passengersWaiting <= 0) return 0;
    _boardingAccum += dt * kBoardingRate;
    final boarded = _boardingAccum.floor().clamp(0, passengersWaiting);
    if (boarded > 0) {
      passengersWaiting -= boarded;
      _boardingAccum   -= boarded;
    }
    return boarded;
  }

  void resetBoardingAccum() => _boardingAccum = 0.0;

  // ── Rendering ─────────────────────────────────────────────────────────────

  static const _platformColor = Color(0xFFFF9500);  // bright orange
  static const _platformEdge  = Color(0xFFCC6600);
  static const _badgeColor    = Color(0xFFFF9500);

  void render(Canvas canvas, double cs) {
    if (isComplete) return;

    const int halfLen = 1;
    const int len     = halfLen * 2 + 1;

    if (isVertical) {
      for (final sideCol in [col - 1, col + 1]) {
        if (sideCol < 0 || sideCol >= kCols) continue;
        final startRow = _findSharedRow(sideCol, sideCol, row - halfLen, len);
        if (startRow != null) {
          final edge = sideCol < col ? _CanopyEdge.right : _CanopyEdge.left;
          _drawPlatformStrip(canvas, cs,
            startCol: sideCol, startRow: startRow,
            cols: 1, rows: len, canopyEdge: edge);
          break; // only one platform
        }
      }
    } else {
      for (final sideRow in [row - 1, row + 1]) {
        if (sideRow < 0 || sideRow >= kRows) continue;
        final startCol = _findSharedCol(sideRow, sideRow, col - halfLen, len);
        if (startCol != null) {
          final edge = sideRow < row ? _CanopyEdge.bottom : _CanopyEdge.top;
          _drawPlatformStrip(canvas, cs,
            startCol: startCol, startRow: sideRow,
            cols: len, rows: 1, canopyEdge: edge);
          break; // only one platform
        }
      }
    }
  }

  /// Find a shared startRow that works for at least one of the two side columns.
  /// Prefers offsets where both sides are clear; falls back to one-side-only.
  static int? _findSharedRow(int sideCol1, int sideCol2, int start, int len) {
    int? fallback;
    for (final offset in [0, 1, -1, 2, -2]) {
      final s = start + offset;
      final e = s + len - 1;
      if (s < 0 || e >= kRows) continue;
      final ok1 = sideCol1 >= 0 && _stripClear(sideCol1, s, sideCol1, e);
      final ok2 = sideCol2 < kCols && _stripClear(sideCol2, s, sideCol2, e);
      if (ok1 && ok2) return s;
      if (fallback == null && (ok1 || ok2)) fallback = s;
    }
    return fallback;
  }

  /// Find a shared startCol that works for at least one of the two side rows.
  static int? _findSharedCol(int sideRow1, int sideRow2, int start, int len) {
    int? fallback;
    for (final offset in [0, 1, -1, 2, -2]) {
      final s = start + offset;
      final e = s + len - 1;
      if (s < 0 || e >= kCols) continue;
      final ok1 = sideRow1 >= 0 && _stripClear(s, sideRow1, e, sideRow1);
      final ok2 = sideRow2 < kRows && _stripClear(s, sideRow2, e, sideRow2);
      if (ok1 && ok2) return s;
      if (fallback == null && (ok1 || ok2)) fallback = s;
    }
    return fallback;
  }

  /// True when no cell in the rectangle [c1,r1]..[c2,r2] is a street.
  static bool _stripClear(int c1, int r1, int c2, int r2) {
    for (int c = c1; c <= c2; c++) {
      for (int r = r1; r <= r2; r++) {
        if (isMazeStreet(c, r)) return false;
      }
    }
    return true;
  }

  void _drawPlatformStrip(
    Canvas canvas,
    double cs, {
    required int startCol,
    required int startRow,
    required int cols,
    required int rows,
    required _CanopyEdge canopyEdge,
  }) {
    final endCol = startCol + cols - 1;
    final endRow = startRow + rows - 1;
    if (startCol < 0 || startRow < 0 || endCol >= kCols || endRow >= kRows) return;

    final inset = cs * 0.12;
    final rect  = Rect.fromLTWH(
      startCol * cs + inset,
      startRow * cs + inset,
      cols * cs - inset * 2,
      rows * cs - inset * 2,
    );

    canvas.drawRect(rect, Paint()..color = _platformColor);
    canvas.drawRect(rect, Paint()
      ..color       = _platformEdge
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Canopy line along the street-facing edge
    final roofPaint = Paint()
      ..color       = _platformEdge
      ..strokeWidth = 3.0;

    switch (canopyEdge) {
      case _CanopyEdge.top:
        canvas.drawLine(
          Offset(rect.left,  rect.top + 4),
          Offset(rect.right, rect.top + 4),
          roofPaint,
        );
      case _CanopyEdge.bottom:
        canvas.drawLine(
          Offset(rect.left,  rect.bottom - 4),
          Offset(rect.right, rect.bottom - 4),
          roofPaint,
        );
      case _CanopyEdge.left:
        canvas.drawLine(
          Offset(rect.left + 4, rect.top),
          Offset(rect.left + 4, rect.bottom),
          roofPaint,
        );
      case _CanopyEdge.right:
        canvas.drawLine(
          Offset(rect.right - 4, rect.top),
          Offset(rect.right - 4, rect.bottom),
          roofPaint,
        );
    }
  }

  void _drawBadge(Canvas canvas, double cs, double cx, double cy) {
    final radius = cs * 0.28;
    canvas.drawCircle(Offset(cx, cy), radius, Paint()..color = _badgeColor);

    final tp = TextPainter(
      text: TextSpan(
        text: '$passengersWaiting',
        style: TextStyle(
          color: Colors.white,
          fontSize: cs * 0.28,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }
}

// ── Station generation ────────────────────────────────────────────────────────

/// Returns all valid station positions: midpoints of street segments between
/// consecutive intersections.
List<({int col, int row})> _allCandidates() {
  final list = <({int col, int row})>[];

  // Horizontal streets: for each street row, place a station at the midpoint
  // of each segment between consecutive street columns.
  for (final row in kStreetRows) {
    for (int i = 0; i < kStreetCols.length - 1; i++) {
      final mid = (kStreetCols[i] + kStreetCols[i + 1]) ~/ 2;
      list.add((col: mid, row: row));
    }
  }

  // Vertical streets: for each street col, place a station at the midpoint
  // of each segment between consecutive street rows.
  for (final col in kStreetCols) {
    for (int i = 0; i < kStreetRows.length - 1; i++) {
      final mid = (kStreetRows[i] + kStreetRows[i + 1]) ~/ 2;
      list.add((col: col, row: mid));
    }
  }

  return list;
}

/// True when [col,row] can show at least one platform strip.
bool _hasValidPlatform(int col, int row) {
  const int halfLen = 1;
  const int len     = halfLen * 2 + 1;
  if (kStreetCols.contains(col)) {
    return Station._findSharedRow(col - 1, col + 1, row - halfLen, len) != null;
  } else {
    return Station._findSharedCol(row - 1, row + 1, col - halfLen, len) != null;
  }
}

/// Generate [count] randomly placed stations with 3–6 passengers each.
List<Station> generateStations(int count) {
  final rng        = Random();
  final candidates = _allCandidates()
      .where((p) => isMazeStreet(p.col, p.row))
      .where((p) => _hasValidPlatform(p.col, p.row))
      .toList()
    ..shuffle(rng);
  return candidates.take(count).map((p) => Station(
    col: p.col,
    row: p.row,
    passengersWaiting: 3 + rng.nextInt(4), // 3–6
  )).toList();
}
