import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'enemy_trolley.dart';
import 'maze.dart';
import 'models.dart';
import 'player_trolley.dart';
import 'station.dart';

const int    _kStationsForRound1    = 3;
const int    _kMaxLives             = 3;
const String _kOverlayDpad          = 'dpad';
const String _kOverlayRoundComplete = 'round_complete';
const String _kOverlayGameOver      = 'game_over';

/// Collision radius: fraction of a cell. If pixel distance < this, it's a hit.
const double _kCollisionRadius = 0.55;

class TrolleyGame extends FlameGame with PanDetector {
  late MazeComponent    _maze;
  late PlayerTrolley    _player;
  late List<Station>    _stations;
  late List<EnemyTrolley> _enemies;

  int  _passengersCollected = 0;
  int  _currentRound        = 1;
  int  _lives               = _kMaxLives;
  bool _roundComplete       = false;
  bool _gameOver            = false;

  /// Brief invincibility window after a hit so the player doesn't lose two
  /// lives from a single collision (same idea as Pac-Man respawn flash).
  double _invincibleTimer = 0.0;
  static const double _kInvincibleDuration = 1.5; // seconds

  Offset? _panStart;
  Offset? _panCurrent;

  static const double _minSwipeDistance = 20.0;

  // ── Init ──────────────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    final cellSize = size.x / kCols;

    _maze = MazeComponent(cellSize: cellSize);

    _player = PlayerTrolley(
      gridCol:  0,
      gridRow:  0,
      cellSize: cellSize,
      maze:     _maze,
    );

    _stations = generateStations(_stationCountForRound(_currentRound));
    _enemies  = _buildEnemies(cellSize, _currentRound);

    overlays.add(_kOverlayDpad);
  }

  static int _stationCountForRound(int round) =>
      (_kStationsForRound1 + (round - 1) * 2).clamp(3, 15);

  static int _enemyCountForRound(int round) => round.clamp(1, kEnemySpawns.length);

  List<EnemyTrolley> _buildEnemies(double cellSize, int round) {
    final count = _enemyCountForRound(round);
    return List.generate(count, (i) {
      final spawn = kEnemySpawns[i];
      return EnemyTrolley(
        cellSize: cellSize,
        maze:     _maze,
        startCol: spawn.$1,
        startRow: spawn.$2,
      );
    });
  }

  // ── Public controls ───────────────────────────────────────────────────────

  void pressDirection(Direction dir) => _player.queueDirection(dir);
  void stop() => _player.snapStop();
  void go()   => _player.isMoving = true;

  /// Called by the round-complete overlay.
  void nextRound() {
    _currentRound++;
    _roundComplete        = false;
    _passengersCollected  = 0;
    _stations = generateStations(_stationCountForRound(_currentRound));

    final cellSize = size.x / kCols;
    _enemies  = _buildEnemies(cellSize, _currentRound);
    _respawnPlayer();
    overlays.remove(_kOverlayRoundComplete);
  }

  /// Called by the game-over overlay to restart from round 1.
  void restartGame() {
    _currentRound        = 1;
    _lives               = _kMaxLives;
    _roundComplete       = false;
    _gameOver            = false;
    _passengersCollected = 0;
    _stations = generateStations(_stationCountForRound(_currentRound));

    final cellSize = size.x / kCols;
    _enemies  = _buildEnemies(cellSize, _currentRound);
    _respawnPlayer();
    overlays.remove(_kOverlayGameOver);
  }

  void _respawnPlayer() {
    final cs = size.x / kCols;
    _player
      ..gridCol  = 0
      ..gridRow  = 0
      ..centerX  = 0.5 * cs
      ..centerY  = 0.5 * cs
      ..isMoving = true;
    for (final e in _enemies) {
      e.reset();
    }
    _invincibleTimer = _kInvincibleDuration;
  }

  // ── Collision ─────────────────────────────────────────────────────────────

  void _checkCollisions() {
    if (_invincibleTimer > 0 || _roundComplete || _gameOver) return;
    final threshold = (size.x / kCols) * _kCollisionRadius;
    for (final e in _enemies) {
      final dx = _player.centerX - e.centerX;
      final dy = _player.centerY - e.centerY;
      if (dx * dx + dy * dy < threshold * threshold) {
        _onHit();
        return;
      }
    }
  }

  void _onHit() {
    _lives--;
    if (_lives <= 0) {
      _gameOver = true;
      _player.isMoving = false;
      overlays.add(_kOverlayGameOver);
    } else {
      _respawnPlayer();
    }
  }

  // ── Win condition ─────────────────────────────────────────────────────────

  void _checkWin() {
    if (_roundComplete || _gameOver) return;
    if (_stations.every((s) => s.isComplete)) {
      _roundComplete = true;
      _player.isMoving = false;
      overlays.add(_kOverlayRoundComplete);
    }
  }

  // ── Station boarding ───────────────────────────────────────────────────────

  Station? get _activeStation {
    if (_player.isMoving) return null;
    for (final s in _stations) {
      if (!s.isComplete && s.col == _player.gridCol && s.row == _player.gridRow) {
        return s;
      }
    }
    return null;
  }

  void _updateBoarding(double dt) {
    final station = _activeStation;
    if (station == null) return;
    final boarded = station.board(dt);
    _passengersCollected += boarded;
  }

  // ── Input ─────────────────────────────────────────────────────────────────

  @override
  void onPanStart(DragStartInfo info) {
    _panStart   = Offset(info.eventPosition.global.x, info.eventPosition.global.y);
    _panCurrent = _panStart;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    _panCurrent = Offset(info.eventPosition.global.x, info.eventPosition.global.y);
  }

  @override
  void onPanEnd(DragEndInfo info) {
    final start   = _panStart;
    final current = _panCurrent;
    if (start == null || current == null) return;

    final delta = current - start;
    if (delta.distance >= _minSwipeDistance) {
      final dir = delta.dx.abs() > delta.dy.abs()
          ? (delta.dx > 0 ? Direction.right : Direction.left)
          : (delta.dy > 0 ? Direction.down  : Direction.up);
      _player.queueDirection(dir);
    }

    _panStart   = null;
    _panCurrent = null;
  }

  // ── Game loop ─────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameOver || _roundComplete) return;

    if (_invincibleTimer > 0) _invincibleTimer -= dt;

    _player.update(dt);
    for (final e in _enemies) {
      e.update(dt);
    }
    _updateBoarding(dt);
    _checkCollisions();
    _checkWin();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final cs       = size.x / kCols;
    final offsetX  = (size.x - kCols * cs) / 2;
    const offsetY  = 0.0;

    canvas.save();
    canvas.translate(offsetX, offsetY);

    _maze.render(canvas);

    for (final s in _stations) {
      s.render(canvas, cs);
    }

    for (final e in _enemies) {
      e.render(canvas);
    }

    // Flash player during invincibility
    final showPlayer = _invincibleTimer <= 0 ||
        (_invincibleTimer * 6).floor().isEven;
    if (showPlayer) _player.render(canvas);

    canvas.restore();

    _renderHud(canvas);
  }

  void _renderHud(Canvas canvas) {
    final remaining = _stations.fold(0, (sum, s) => sum + s.passengersWaiting);
    final hearts    = '♥ ' * _lives + '♡ ' * (_kMaxLives - _lives);
    final text      = 'Round $_currentRound   $hearts  |  ✓ $_passengersCollected  ·  Remaining: $remaining';

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(16, 16));
  }

  // Expose state for overlay widgets
  int get currentRound        => _currentRound;
  int get passengersCollected => _passengersCollected;
  int get lives               => _lives;
}
