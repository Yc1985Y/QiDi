import 'package:flutter/material.dart';

import '../app.dart';

class WeavingBackground extends StatelessWidget {
  const WeavingBackground({
    super.key,
    required this.child,
    this.showStarField = false,
    this.interactiveStars = false,
  });

  final Widget child;
  final bool showStarField;
  final bool interactiveStars;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background,
                AppColors.surface,
                AppColors.background,
              ],
            ),
          ),
        ),
        const Positioned(
          left: 0,
          top: 0,
          child: _DiffuseGlow(size: 280, color: AppColors.mint, opacity: 0.55),
        ),
        const Positioned(
          right: 0,
          top: 80,
          child: _DiffuseGlow(size: 320, color: AppColors.gold, opacity: 0.50),
        ),
        const Positioned(
          right: 0,
          bottom: 0,
          child: _DiffuseGlow(size: 260, color: AppColors.coral, opacity: 0.45),
        ),
        if (showStarField || interactiveStars)
          Positioned.fill(
            child: _ConstellationField(interactive: interactiveStars),
          ),
        child,
      ],
    );
  }
}

class _DiffuseGlow extends StatelessWidget {
  const _DiffuseGlow({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConstellationField extends StatefulWidget {
  const _ConstellationField({required this.interactive});

  final bool interactive;

  @override
  State<_ConstellationField> createState() => _ConstellationFieldState();
}

class _ConstellationFieldState extends State<_ConstellationField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..addListener(() => setState(() {}));
  int? _pulseIndex;

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final field = CustomPaint(
          painter: _ConstellationPainter(
            pulseIndex: _pulseIndex,
            pulseProgress: Curves.fastOutSlowIn.transform(
              _pulseController.value,
            ),
          ),
        );
        if (!widget.interactive) return IgnorePointer(child: field);
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            var nearestIndex = -1;
            var nearestDistance = double.infinity;
            for (
              var index = 0;
              index < _ConstellationPainter.points.length;
              index++
            ) {
              final point = _ConstellationPainter.scalePoint(
                _ConstellationPainter.points[index],
                size,
              );
              final distance = (point - details.localPosition).distance;
              if (distance <= 14 && distance < nearestDistance) {
                nearestIndex = index;
                nearestDistance = distance;
              }
            }
            if (nearestIndex < 0) return;
            setState(() => _pulseIndex = nearestIndex);
            _pulseController.forward(from: 0);
          },
          child: field,
        );
      },
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  static const points = <Offset>[
    Offset(.09, .16),
    Offset(.22, .11),
    Offset(.34, .20),
    Offset(.18, .27),
    Offset(.47, .18),
    Offset(.61, .13),
    Offset(.76, .18),
    Offset(.92, .35),
    Offset(.06, .58),
    Offset(.91, .70),
    Offset(.18, .88),
    Offset(.66, .92),
  ];
  static const sizes = <double>[3, 2, 3, 2, 2, 2, 3, 1, 1, 2, 1, 1];

  const _ConstellationPainter({this.pulseIndex, this.pulseProgress = 1});

  final int? pulseIndex;
  final double pulseProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      AppColors.primarySoft,
      AppColors.gold,
      AppColors.mint,
      AppColors.coral,
    ];
    final line = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 6; index++) {
      line.color = colors[(index + 1) % colors.length].withValues(alpha: 0.16);
      canvas.drawLine(
        scalePoint(points[index], size),
        scalePoint(points[index + 1], size),
        line,
      );
    }
    for (var index = 0; index < points.length; index++) {
      final center = scalePoint(points[index], size);
      final radius = sizes[index];
      final color = colors[index % colors.length];
      canvas.drawCircle(
        center,
        radius * 4.2,
        Paint()..color = color.withValues(alpha: 0.13),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = color.withValues(alpha: 0.54),
      );
      if (radius >= 3) {
        canvas.drawLine(
          Offset(center.dx - radius * 3, center.dy),
          Offset(center.dx + radius * 3, center.dy),
          Paint()
            ..strokeWidth = 0.8
            ..color = color.withValues(alpha: 0.22),
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - radius * 3),
          Offset(center.dx, center.dy + radius * 3),
          Paint()
            ..strokeWidth = 0.8
            ..color = color.withValues(alpha: 0.18),
        );
      }
    }
    if (pulseIndex != null && pulseProgress < 1) {
      final index = pulseIndex!.clamp(0, points.length - 1);
      final center = scalePoint(points[index], size);
      final color = colors[index % colors.length];
      final alpha = 1 - pulseProgress;
      canvas.drawCircle(
        center,
        10 + 42 * pulseProgress,
        Paint()..color = color.withValues(alpha: 0.055 * alpha),
      );
      canvas.drawCircle(
        center,
        2 + 5 * pulseProgress,
        Paint()..color = Colors.white.withValues(alpha: 0.18 * alpha),
      );
      canvas.drawCircle(
        center,
        6 + 26 * pulseProgress,
        Paint()..color = color.withValues(alpha: 0.18 * alpha),
      );
    }
  }

  static Offset scalePoint(Offset point, Size size) =>
      Offset(point.dx * size.width, point.dy * size.height);

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) =>
      oldDelegate.pulseIndex != pulseIndex ||
      oldDelegate.pulseProgress != pulseProgress;
}

enum WeavingInteractionStyle { cardLift, primaryPress, iconGlow, timelineSlide }

class WeavingCard extends StatefulWidget {
  const WeavingCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    this.color,
    this.onTap,
    this.interactionStyle = WeavingInteractionStyle.cardLift,
    this.borderRadius = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final WeavingInteractionStyle interactionStyle;
  final double borderRadius;

  @override
  State<WeavingCard> createState() => _WeavingCardState();
}

class _WeavingCardState extends State<WeavingCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final pressedScale = switch (widget.interactionStyle) {
      WeavingInteractionStyle.primaryPress => 0.965,
      WeavingInteractionStyle.iconGlow => 0.92,
      _ => 0.985,
    };
    final pressedOffsetY = switch (widget.interactionStyle) {
      WeavingInteractionStyle.timelineSlide => 6.0,
      WeavingInteractionStyle.cardLift => 2.0,
      _ => 0.0,
    };
    final pressedOpacity =
        widget.interactionStyle == WeavingInteractionStyle.iconGlow
        ? 0.88
        : 1.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.onTap != null && _pressed ? 1 : 0),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      builder: (context, pressProgress, child) {
        return Transform.translate(
          offset: Offset(0, pressedOffsetY * pressProgress),
          child: Transform.scale(
            scale: 1 - ((1 - pressedScale) * pressProgress),
            child: Opacity(
              opacity: 1 - ((1 - pressedOpacity) * pressProgress),
              child: child,
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: widget.color ?? AppColors.glass,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          side: BorderSide(
            color: AppColors.border.withValues(alpha: 0.68),
            width: 0.6,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          onTap: widget.onTap,
          onHighlightChanged: widget.onTap == null
              ? null
              : (pressed) => setState(() => _pressed = pressed),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 21,
            height: 27 / 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class StatusStrip extends StatelessWidget {
  const StatusStrip({
    super.key,
    required this.message,
    this.error,
    this.busy = false,
  });

  final String message;
  final String? error;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: hasError ? const Color(0xFFFFE5E0) : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              hasError ? Icons.error_outline_rounded : Icons.auto_awesome,
              color: AppColors.primary,
              size: 20,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasError ? error! : message,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor = AppColors.surfaceWarm,
    this.contentColor = AppColors.primary,
  });

  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color contentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: contentColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
              height: 13 / 10.5,
            ).copyWith(color: contentColor),
          ),
        ],
      ),
    );
  }
}
