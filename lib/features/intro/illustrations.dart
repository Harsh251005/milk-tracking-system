import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/theme.dart';

const _navy = Color(0xFF1E3A5F);
const _glass = Color(0xFF5C7CA3);
const _cream = Color(0xFFF7F3EC);

/// Runs [builder] with a repeating 0→1 animation, or a still frame at
/// [stillAt] when the phone asks for reduced motion.
class _Looping extends StatefulWidget {
  const _Looping({
    required this.duration,
    required this.builder,
    this.stillAt = 1,
  });

  final Duration duration;
  final double stillAt;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<_Looping> createState() => _LoopingState();
}

class _LoopingState extends State<_Looping>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.duration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = widget.stillAt;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => widget.builder(context, _c.value),
  );
}

double _ease(double t) => Curves.easeInOutCubic.transform(t.clamp(0, 1));

/// Interval [a, b] of the loop mapped to 0→1.
double _span(double t, double a, double b) => ((t - a) / (b - a)).clamp(0, 1);

// --- 1. Bottle filling ------------------------------------------------------

/// The app's milk bottle filling up, then a check popping in.
class BottleIllustration extends StatelessWidget {
  const BottleIllustration({super.key});

  @override
  Widget build(BuildContext context) => _Looping(
    duration: const Duration(milliseconds: 4200),
    stillAt: 0.7,
    builder: (context, t) {
      // 0–0.55 fill, 0.55–0.85 hold with check, 0.85–1 drain quietly.
      final fill = t < 0.85 ? _ease(_span(t, 0, 0.55)) : 1 - _span(t, 0.85, 1);
      final check =
          Curves.elasticOut.transform(_span(t, 0.55, 0.75)) *
          (1 - _span(t, 0.82, 0.88));
      return CustomPaint(
        painter: _BottlePainter(
          fill: fill,
          wave: t * 2 * math.pi * 3,
          check: check,
          green: context.colors.got,
        ),
      );
    },
  );
}

class _BottlePainter extends CustomPainter {
  _BottlePainter({
    required this.fill,
    required this.wave,
    required this.check,
    required this.green,
  });

  final double fill;
  final double wave;
  final double check;
  final Color green;

  @override
  void paint(Canvas canvas, Size size) {
    final h = math.min(size.height * 0.86, size.width * 1.2);
    final w = h * 0.54;
    final cx = size.width / 2;
    final top = (size.height - h) / 2;
    final neckW = w * 0.5;

    final bottle = Path()
      ..addRRect(
        RRect.fromLTRBR(
          cx - neckW * 0.6,
          top,
          cx + neckW * 0.6,
          top + h * 0.1,
          Radius.circular(h * 0.035),
        ),
      )
      ..addRect(
        Rect.fromLTRB(
          cx - neckW / 2,
          top + h * 0.085,
          cx + neckW / 2,
          top + h * 0.3,
        ),
      )
      ..addOval(
        Rect.fromLTRB(cx - w / 2, top + h * 0.22, cx + w / 2, top + h * 0.59),
      )
      // Body: only the bottom corners are rounded, so it meets the
      // shoulders without a notch.
      ..addRRect(
        RRect.fromLTRBAndCorners(
          cx - w / 2,
          top + h * 0.4,
          cx + w / 2,
          top + h,
          bottomLeft: Radius.circular(w * 0.18),
          bottomRight: Radius.circular(w * 0.18),
        ),
      );

    // Soft shadow, then glass.
    canvas.drawPath(
      bottle.shift(Offset(0, h * 0.03)),
      Paint()
        ..color = _navy.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawPath(bottle, Paint()..color = _glass);

    // Milk: everything below a wave whose level rises with [fill].
    final bottom = top + h;
    final full = top + h * 0.42;
    final level = bottom - (bottom - full) * fill;
    final amp = h * 0.022 * (fill > 0 ? 1 : 0);
    final milk = Path()..moveTo(cx - w, level);
    for (var x = -w; x <= w; x += 4) {
      milk.lineTo(cx + x, level + math.sin(x / w * 2 * math.pi + wave) * amp);
    }
    milk
      ..lineTo(cx + w, bottom + 10)
      ..lineTo(cx - w, bottom + 10)
      ..close();
    canvas
      ..save()
      ..clipPath(bottle)
      ..drawPath(milk, Paint()..color = _cream)
      ..restore();

    // Check badge.
    if (check > 0) {
      final c = Offset(cx + w * 0.42, bottom - w * 0.28);
      final r = w * 0.2 * check;
      canvas
        ..drawCircle(c, r + w * 0.03, Paint()..color = _cream)
        ..drawCircle(c, r, Paint()..color = green);
      final tick = Path()
        ..moveTo(c.dx - r * 0.42, c.dy + r * 0.02)
        ..lineTo(c.dx - r * 0.1, c.dy + r * 0.34)
        ..lineTo(c.dx + r * 0.45, c.dy - r * 0.32);
      canvas.drawPath(
        tick,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.17
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_BottlePainter old) =>
      old.fill != fill || old.wave != wave || old.check != check;
}

// --- 2. Family sync ---------------------------------------------------------

/// Two phones; a "1 L" card glides from Mom's to Dad's.
class SyncIllustration extends StatelessWidget {
  const SyncIllustration({super.key});

  @override
  Widget build(BuildContext context) => _Looping(
    duration: const Duration(milliseconds: 3000),
    stillAt: 0.75,
    builder: (context, t) => LayoutBuilder(
      builder: (context, box) {
        final phoneW = box.maxWidth * 0.3;
        final phoneH = phoneW * 1.75;
        final travel = _ease(_span(t, 0.2, 0.6));
        final arrived = _span(t, 0.6, 0.7);
        final fadeOut = 1 - _span(t, 0.9, 1);
        final leftX = box.maxWidth * 0.12;
        final rightX = box.maxWidth * 0.88 - phoneW;
        final cardW = phoneW * 0.72;
        final cardX = leftX + (phoneW - cardW) / 2 + (rightX - leftX) * travel;
        final cardY =
            box.maxHeight / 2 - phoneH * 0.12 - math.sin(travel * math.pi) * 34;

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DotsPainter(progress: travel, color: _glass),
              ),
            ),
            for (final (x, name, lit) in [
              (leftX, 'Mom', 1.0),
              (rightX, 'Dad', arrived * fadeOut),
            ])
              Positioned(
                left: x,
                top: (box.maxHeight - phoneH) / 2 - 14,
                child: _Phone(width: phoneW, name: name, glow: lit),
              ),
            Positioned(
              left: cardX,
              top: cardY,
              child: Opacity(
                opacity: fadeOut,
                child: _LogCard(width: cardW, green: context.colors.got),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _Phone extends StatelessWidget {
  const _Phone({required this.width, required this.name, required this.glow});

  final double width;
  final String name;
  final double glow;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        Container(
          width: width,
          height: width * 1.75,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(width * 0.16),
            border: Border.all(color: _navy, width: 4),
            boxShadow: [
              BoxShadow(
                color: context.colors.got.withValues(alpha: 0.35 * glow),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(width * 0.12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final f in [0.55, 0.85, 0.4])
                  Container(
                    margin: EdgeInsets.only(bottom: width * 0.07),
                    width: width * 0.76 * f,
                    height: width * 0.07,
                    decoration: BoxDecoration(
                      color: context.colors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(name, style: t.titleMedium),
      ],
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.width, required this.green});

  final double width;
  final Color green;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: EdgeInsets.symmetric(vertical: width * 0.12),
    decoration: BoxDecoration(
      color: context.colors.gotSoft,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(color: _navy.withValues(alpha: 0.15), blurRadius: 10),
      ],
    ),
    // Scales down rather than overflowing on narrow screens.
    child: FittedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: green, size: width * 0.24),
          const SizedBox(width: 4),
          Text(
            '1 L',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2 - 14;
    final from = size.width * 0.36;
    final to = size.width * 0.64;
    for (var x = from; x <= to; x += 12) {
      final lit = (x - from) / (to - from) <= progress;
      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = color.withValues(alpha: lit ? 0.9 : 0.25),
      );
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.progress != progress;
}

// --- 3. WhatsApp bill -------------------------------------------------------

/// A chat bubble slides up and the bill's lines type in one by one.
class BillIllustration extends StatelessWidget {
  const BillIllustration({super.key});

  static const _lines = [
    ('Namaste Ramesh,', false),
    ('Milk for October:', false),
    ('Total: 30 L', true),
    ('Amount: ₹2,100', true),
  ];

  @override
  Widget build(BuildContext context) => _Looping(
    duration: const Duration(milliseconds: 4200),
    stillAt: 0.8,
    builder: (context, t) {
      final t2 = Theme.of(context).textTheme;
      final rise = _ease(_span(t, 0, 0.18));
      final fadeOut = 1 - _span(t, 0.92, 1);
      return Center(
        child: Opacity(
          opacity: fadeOut,
          child: Transform.translate(
            offset: Offset(0, (1 - rise) * 60),
            child: Opacity(
              opacity: rise,
              child: Container(
                width: 260,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCF8C6),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _navy.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, (text, bold)) in _lines.indexed)
                      Opacity(
                        opacity: _span(t, 0.22 + i * 0.12, 0.3 + i * 0.12),
                        child: Padding(
                          padding: EdgeInsets.only(top: i == 2 ? 10 : 2),
                          child: Text(
                            text,
                            style: t2.bodyLarge?.copyWith(
                              color: const Color(0xFF1F2328),
                              fontWeight: bold ? FontWeight.w800 : null,
                            ),
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Opacity(
                        opacity: _span(t, 0.75, 0.82),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '9:41',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF667781),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.done_all_rounded,
                              size: 16,
                              color: Color(0xFF53BDEB),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
