import 'dart:math';

// Cells per second — shared by player and enemy trolleys
const double kTrolleySpeed = 5.0;

// Rotation speed for smooth turning (radians per second)
const double kTurnSpeed = 10.0;

enum Direction { up, down, left, right }

extension DirectionExt on Direction {
  int get dx => switch (this) {
    Direction.left  => -1,
    Direction.right =>  1,
    _               =>  0,
  };

  int get dy => switch (this) {
    Direction.up   => -1,
    Direction.down =>  1,
    _              =>  0,
  };

  Direction get opposite => switch (this) {
    Direction.up    => Direction.down,
    Direction.down  => Direction.up,
    Direction.left  => Direction.right,
    Direction.right => Direction.left,
  };

  /// Angle in radians, measured clockwise from right (canvas convention).
  double get angle => switch (this) {
    Direction.right =>  0,
    Direction.down  =>  pi / 2,
    Direction.left  =>  pi,
    Direction.up    => -pi / 2,
  };
}
