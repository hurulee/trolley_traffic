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

  static const _platformColor = Color(0xFFD4B483);
  static const _platformEdge  = Color(0xFF9B7D3E);
  static const _badgeColor    = Color(0xFFFF9500);

  void render(Canvas canvas, double cs) {
    if (isComplete) return;

    // Half the platform length on each side of the station along the street.
    // Total platform = halfLen * 2 + 1 cells long.
    const int halfLen = 1;

    if (isVertical) {
      // Vertical street: platforms run north-south in col-1 and col+1
      for (final sideCol in [col - 1, col + 1]) {
        final edge = sideCol < col ? _CanopyEdge.right : _CanopyEdge.left;
        int startRow = row - halfLen;
        if (isMazeStreet(sideCol, startRow)) {
          startRow++; // top end touches street → shift down
        } else if (isMazeStreet(sideCol, startRow + halfLen * 2)) {
          startRow--; // bottom end touches street → shift up
        }
        _drawPlatformStrip(canvas, cs,
          startCol: sideCol, startRow: startRow,
          cols: 1, rows: halfLen * 2 + 1,
          canopyEdge: edge);
      }
    } else {
      // Horizontal street: platforms run east-west in row-1 and row+1
      for (final sideRow in [row - 1, row + 1]) {
        final edge = sideRow < row ? _CanopyEdge.bottom : _CanopyEdge.top;
        int startCol = col - halfLen;
        if (isMazeStreet(startCol, sideRow)) {
          startCol++; // left end touches street → shift right
        } else if (isMazeStreet(startCol + halfLen * 2, sideRow)) {
          startCol--; // right end touches street → shift left
        }
        _drawPlatformStrip(canvas, cs,
          startCol: startCol, startRow: sideRow,
          cols: halfLen * 2 + 1, rows: 1,
          canopyEdge: edge);
      }
    }

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

    // Don't draw over any street cell.
    for (int c = startCol; c <= endCol; c++) {
      for (int r = startRow; r <= endRow; r++) {
        if (isMazeStreet(c, r)) return;
      }
    }

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

/// Generate [count] randomly placed stations with 3–6 passengers each.
List<Station> generateStations(int count) {
  final rng        = Random();
  final candidates = _allCandidates()..shuffle(rng);
  return candidates.take(count).map((p) => Station(
    col: p.col,
    row: p.row,
    passengersWaiting: 3 + rng.nextInt(4), // 3–6
  )).toList();
}
