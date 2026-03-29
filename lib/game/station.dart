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

  /// True when this station sits on a vertical street (platform extends
  /// left/right into building cells).
  bool get isVertical => col % kStreetStep == 0;

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
      _drawPlatformStrip(
        canvas, cs,
        startCol: col - 1, startRow: row - halfLen,
        cols: 1, rows: halfLen * 2 + 1,
        canopyEdge: _CanopyEdge.right,   // faces the street on the right
      );
      _drawPlatformStrip(
        canvas, cs,
        startCol: col + 1, startRow: row - halfLen,
        cols: 1, rows: halfLen * 2 + 1,
        canopyEdge: _CanopyEdge.left,    // faces the street on the left
      );
    } else {
      // Horizontal street: platforms run east-west in row-1 and row+1
      _drawPlatformStrip(
        canvas, cs,
        startCol: col - halfLen, startRow: row - 1,
        cols: halfLen * 2 + 1, rows: 1,
        canopyEdge: _CanopyEdge.bottom,  // faces the street below
      );
      _drawPlatformStrip(
        canvas, cs,
        startCol: col - halfLen, startRow: row + 1,
        cols: halfLen * 2 + 1, rows: 1,
        canopyEdge: _CanopyEdge.top,     // faces the street above
      );
    }

    _drawBadge(canvas, cs, (col + 0.5) * cs, (row + 0.5) * cs);
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
  final mid  = kStreetStep ~/ 2; // = 2 for step=5

  // Horizontal streets (row is intersection): station cols at seg*step + mid
  for (int row = 0; row < kRows; row += kStreetStep) {
    for (int seg = 0; seg < kCols ~/ kStreetStep; seg++) {
      list.add((col: seg * kStreetStep + mid, row: row));
    }
  }

  // Vertical streets (col is intersection): station rows at seg*step + mid
  for (int col = 0; col < kCols; col += kStreetStep) {
    for (int seg = 0; seg < kRows ~/ kStreetStep; seg++) {
      list.add((col: col, row: seg * kStreetStep + mid));
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
