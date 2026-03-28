import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/models.dart';
import 'game/trolley_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(
    GameWidget(
      game: TrolleyGame(),
      overlayBuilderMap: {
        'dpad':           (context, game) => GameController(game: game as TrolleyGame),
        'round_complete': (context, game) => RoundCompleteOverlay(game: game as TrolleyGame),
        'game_over':      (context, game) => GameOverOverlay(game: game as TrolleyGame),
      },
    ),
  );
}

// ── Round complete overlay ────────────────────────────────────────────────────

class RoundCompleteOverlay extends StatelessWidget {
  const RoundCompleteOverlay({super.key, required this.game});
  final TrolleyGame game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Round ${game.currentRound} Complete!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${game.passengersCollected} passengers boarded',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: game.nextRound,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'NEXT ROUND',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Game over overlay ─────────────────────────────────────────────────────────

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.game});
  final TrolleyGame game;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Color(0xFFE74C3C),
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You reached round ${game.currentRound}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: game.restartGame,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'PLAY AGAIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Controller layout ────────────────────────────────────────────────────────

class GameController extends StatelessWidget {
  const GameController({super.key, required this.game});
  final TrolleyGame game;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        color: Colors.black54,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Left: D-pad
            DPad(onDirection: game.pressDirection),

            // Right: Stop / Go buttons
            ActionButtons(onStop: game.stop, onGo: game.go),
          ],
        ),
      ),
    );
  }
}

// ── D-pad ────────────────────────────────────────────────────────────────────

class DPad extends StatelessWidget {
  const DPad({super.key, required this.onDirection});
  final void Function(Direction) onDirection;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DPadBtn(icon: Icons.arrow_upward,   onTap: () => onDirection(Direction.up)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DPadBtn(icon: Icons.arrow_back,    onTap: () => onDirection(Direction.left)),
            const SizedBox(width: 44, height: 44), // centre gap
            _DPadBtn(icon: Icons.arrow_forward,  onTap: () => onDirection(Direction.right)),
          ],
        ),
        _DPadBtn(icon: Icons.arrow_downward, onTap: () => onDirection(Direction.down)),
      ],
    );
  }
}

class _DPadBtn extends StatelessWidget {
  const _DPadBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white70, size: 26),
      ),
    );
  }
}

// ── Action buttons ───────────────────────────────────────────────────────────

class ActionButtons extends StatelessWidget {
  const ActionButtons({super.key, required this.onStop, required this.onGo});
  final VoidCallback onStop;
  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _ActionBtn(label: 'GO',   color: const Color(0xFF27AE60), onTap: onGo),
        const SizedBox(height: 12),
        _ActionBtn(label: 'STOP', color: const Color(0xFFC0392B), onTap: onStop),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 52,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
