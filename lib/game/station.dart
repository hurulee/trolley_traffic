import 'dart:math';
import 'package:flutter/material.dart';
import 'maze.dart';

const double kBoardingRate = 1.0; // passengers boarded per second

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

    final px = col * cs;
    final py = row * cs;

    if (isVertical) {
      // Platform extends left and right into building cells
      _drawPlatform(canvas, cs, col - 1, row, Axis.vertical);
      _drawPlatform(canvas, cs, col + 1, row, Axis.vertical);
    } else {
      // Platform extends up and down into building cells
      _drawPlatform(canvas, cs, col, row - 1, Axis.horizontal);
      _drawPlatform(canvas, cs, col, row + 1, Axis.horizontal);
    }

    // Passenger count badge on the street cell
    _drawBadge(canvas, cs, px + cs / 2, py + cs / 2);
  }

  void _drawPlatform(Canvas canvas, double cs, int pcol, int prow, Axis axis) {
    // Only draw into valid building cells
    if (pcol < 0 || pcol >= kCols || prow < 0 || prow >= kRows) return;
    if (isMazeStreet(pcol, prow)) return;

    final inset = cs * 0.12;
    final rect  = Rect.fromLTWH(
      pcol * cs + inset, prow * cs + inset,
      cs - inset * 2, cs - inset * 2,
    );
    canvas.drawRect(rect, Paint()..color = _platformColor);
    canvas.drawRect(
      rect,
      Paint()
        ..color     = _platformEdge
        ..style     = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Roof line across the top of the platform
    final roofPaint = Paint()
      ..color       = _platformEdge
      ..strokeWidth = 3.0;
    if (axis == Axis.horizontal) {
      canvas.drawLine(
        Offset(pcol * cs + inset, prow * cs + inset + 4),
        Offset((pcol + 1) * cs - inset, prow * cs + inset + 4),
        roofPaint,
      );
    } else {
      canvas.drawLine(
        Offset(pcol * cs + inset + 4, prow * cs + inset),
        Offset(pcol * cs + inset + 4, (prow + 1) * cs - inset),
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
