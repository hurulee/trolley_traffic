// Cells per second — shared by player and enemy trolleys
const double kTrolleySpeed = 5.0;

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
}
