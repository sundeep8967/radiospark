import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../audio/audio_provider.dart';

/// Centre crosshair — dashed ring that spins when snapped onto a station
class Crosshair extends ConsumerStatefulWidget {
  const Crosshair({super.key});

  @override
  ConsumerState<Crosshair> createState() => _CrosshairState();
}

class _CrosshairState extends ConsumerState<Crosshair>
    with TickerProviderStateMixin {
  // Spin controller (rotation when on a dot)
  late AnimationController _spinCtrl;
  // Pulse/ripple controller (playing state)
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.7).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );

    _pulseOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioState = ref.watch(audioControllerProvider);
    final isOnDot = audioState.status == AudioStatus.playing ||
        audioState.status == AudioStatus.loading;

    // Control spin
    if (isOnDot) {
      if (!_spinCtrl.isAnimating) _spinCtrl.repeat();
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat();
    } else {
      _spinCtrl.stop();
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple ring when playing
          if (isOnDot)
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Transform.scale(
                scale: _pulseScale.value,
                child: Opacity(
                  opacity: _pulseOpacity.value,
                  child: CustomPaint(
                    size: const Size(56, 56),
                    painter: _DashedCirclePainter(
                      color: const Color(0xFF00E676),
                      strokeWidth: 1.5,
                      dashCount: 12,
                      gapRatio: 0.45,
                      rotation: 0,
                    ),
                  ),
                ),
              ),
            ),

          // Main dashed ring — spins when on a dot
          AnimatedBuilder(
            animation: _spinCtrl,
            builder: (_, __) => CustomPaint(
              size: const Size(56, 56),
              painter: _DashedCirclePainter(
                color: const Color(0xFF00E676),
                strokeWidth: 2.2,
                dashCount: 10,
                gapRatio: 0.35,
                rotation: isOnDot ? _spinCtrl.value * 2 * math.pi : 0,
                glowColor: const Color(0xFF00E676),
              ),
            ),
          ),

          // Centre dot
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: isOnDot ? const Color(0xFF00E676) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isOnDot
                      ? const Color(0xFF00E676).withValues(alpha: 0.7)
                      : Colors.black26,
                  blurRadius: isOnDot ? 10 : 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter — draws a dashed circle
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashCount;      // number of dashes
  final double gapRatio;    // fraction of each segment that is gap
  final double rotation;    // radians
  final Color? glowColor;

  _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashCount,
    required this.gapRatio,
    required this.rotation,
    this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.shortestSide / 2) - strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final segmentAngle = (2 * math.pi) / dashCount;
    final gapAngle = segmentAngle * gapRatio;
    final dashAngle = segmentAngle - gapAngle;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (glowColor != null) {
      // Glow pass
      final glowPaint = Paint()
        ..color = glowColor!.withValues(alpha: 0.35)
        ..strokeWidth = strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      for (int i = 0; i < dashCount; i++) {
        final start = rotation + i * segmentAngle + gapAngle / 2;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          start, dashAngle, false, glowPaint,
        );
      }
    }

    // Main dashes
    for (int i = 0; i < dashCount; i++) {
      final start = rotation + i * segmentAngle + gapAngle / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start, dashAngle, false, paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) =>
      old.rotation != rotation ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
