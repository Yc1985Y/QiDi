import 'dart:math' as math;

import 'package:flutter/material.dart';

const _background = Color(0xFFFFF8F2);
const _surfaceLowest = Color(0xFFFFFFFF);
const _surfaceContainer = Color(0xFFFFEBCB);
const _surfaceHighest = Color(0xFFFFDEA1);
const _surfaceDim = Color(0xFFE3D8CA);
const _primary = Color(0xFF003528);
const _primaryContainer = Color(0xFF0B4D3D);
const _primaryFixed = Color(0xFFB2EFD9);
const _secondaryContainer = Color(0xFFFE8989);
const _onSecondaryContainer = Color(0xFF5D0014);
const _onSurface = Color(0xFF261900);
const _onSurfaceVariant = Color(0xFF404945);
const _outline = Color(0xFF707975);

class AppLoadingOverlay extends StatefulWidget {
  const AppLoadingOverlay({
    super.key,
    required this.isVisible,
    required this.currentStage,
    required this.onCancel,
  });

  final bool isVisible;
  final int currentStage;
  final VoidCallback onCancel;

  @override
  State<AppLoadingOverlay> createState() => _AppLoadingOverlayState();
}

class _AppLoadingOverlayState extends State<AppLoadingOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _spinController;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      lowerBound: 0.88,
      upperBound: 1,
    )..repeat(reverse: true);
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _spinController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final stage = widget.currentStage.clamp(0, 2);
    return Positioned.fill(
      child: Material(
        color: _background,
        child: Stack(
          children: [
            const Positioned(
              left: -70,
              top: -30,
              child: _RadialGlow(size: 340, color: Color(0x80B2EFD9)),
            ),
            const Positioned(
              right: -50,
              bottom: -50,
              child: _RadialGlow(size: 260, color: Color(0x8CFFE0DC)),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        decoration: BoxDecoration(
                          color: _surfaceLowest.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _surfaceHighest.withValues(alpha: 0.50),
                          ),
                        ),
                        child: Column(
                          children: [
                            _LoadingIllustration(
                              pulseController: _pulseController,
                            ),
                            const SizedBox(height: 20),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '正在整理通知...',
                                style: TextStyle(
                                  color: _primary,
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 25,
                                  height: 31 / 25,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _LoadingStepRow(
                              label: '正在识别事项',
                              icon: Icons.search_rounded,
                              index: 0,
                              stage: stage,
                              spinController: _spinController,
                            ),
                            const SizedBox(height: 8),
                            _LoadingStepRow(
                              label: '时间、地点...',
                              icon: Icons.schedule_rounded,
                              index: 1,
                              stage: stage,
                              spinController: _spinController,
                            ),
                            const SizedBox(height: 8),
                            _LoadingStepRow(
                              label: '很快就好',
                              icon: Icons.hourglass_empty_rounded,
                              index: 2,
                              stage: stage,
                              spinController: _spinController,
                            ),
                            const SizedBox(height: 24),
                            _LoadingProgressBar(
                              stage: stage,
                              shimmerController: _shimmerController,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _onSurfaceVariant,
                            backgroundColor: _surfaceHighest,
                            side: BorderSide.none,
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text(
                            '取消',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _LoadingIllustration extends StatelessWidget {
  const _LoadingIllustration({required this.pulseController});

  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      height: 176,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) =>
                Transform.scale(scale: pulseController.value, child: child),
            child: Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryFixed.withValues(alpha: 0.22),
              ),
            ),
          ),
          Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _primaryContainer,
            ),
            child: const Icon(
              Icons.document_scanner_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
          const Positioned(
            right: 8,
            top: 12,
            child: _FloatingChip(
              size: 32,
              radius: 16,
              color: _secondaryContainer,
              icon: Icons.schedule_rounded,
              iconColor: _onSecondaryContainer,
              iconSize: 16,
            ),
          ),
          Positioned(
            left: 4,
            bottom: 12,
            child: Transform.rotate(
              angle: 12 * math.pi / 180,
              child: const _FloatingChip(
                size: 38,
                radius: 12,
                color: _surfaceDim,
                icon: Icons.location_on_rounded,
                iconColor: _onSurface,
                iconSize: 20,
              ),
            ),
          ),
          Positioned(
            left: 6,
            top: 64,
            child: Transform.rotate(
              angle: -12 * math.pi / 180,
              child: const _FloatingChip(
                size: 24,
                radius: 8,
                color: _primaryFixed,
                icon: Icons.check_rounded,
                iconColor: _primaryContainer,
                iconSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingChip extends StatelessWidget {
  const _FloatingChip({
    required this.size,
    required this.radius,
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.iconSize,
  });

  final double size;
  final double radius;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: iconColor, size: iconSize),
    );
  }
}

class _LoadingStepRow extends StatelessWidget {
  const _LoadingStepRow({
    required this.label,
    required this.icon,
    required this.index,
    required this.stage,
    required this.spinController,
  });

  final String label;
  final IconData icon;
  final int index;
  final int stage;
  final AnimationController spinController;

  @override
  Widget build(BuildContext context) {
    final isDone = index < stage;
    final isActive = index == stage;
    final iconColor = isDone
        ? _primary
        : isActive
        ? _primaryContainer
        : _outline;
    final textColor = !isDone && !isActive ? _outline : _onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _surfaceContainer.withValues(alpha: isActive ? 0.55 : 0.30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : icon,
            size: 20,
            color: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: isActive ? 14 : 12.5,
                height: isActive ? 20 / 14 : 18 / 12.5,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
          if (isActive)
            AnimatedBuilder(
              animation: spinController,
              builder: (context, child) => Transform.rotate(
                angle: spinController.value * math.pi * 2,
                child: child,
              ),
              child: const Icon(
                Icons.autorenew_rounded,
                size: 18,
                color: _primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _LoadingProgressBar extends StatelessWidget {
  const _LoadingProgressBar({
    required this.stage,
    required this.shimmerController,
  });

  final int stage;
  final AnimationController shimmerController;

  @override
  Widget build(BuildContext context) {
    final target = switch (stage) {
      0 => 0.28,
      1 => 0.65,
      _ => 0.92,
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 10,
        color: _surfaceHighest,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: target),
          duration: const Duration(milliseconds: 720),
          curve: Curves.fastOutSlowIn,
          builder: (context, fraction, _) => FractionallySizedBox(
            widthFactor: fraction,
            heightFactor: 1,
            child: AnimatedBuilder(
              animation: shimmerController,
              builder: (context, _) => DecoratedBox(
                decoration: BoxDecoration(
                  color: _primaryContainer,
                  gradient: LinearGradient(
                    begin: Alignment(-2 + shimmerController.value * 4, 0),
                    end: Alignment(-1 + shimmerController.value * 4, 0),
                    colors: const [
                      _primaryContainer,
                      Color(0xFF6B9B8E),
                      _primaryContainer,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppErrorOverlay extends StatelessWidget {
  const AppErrorOverlay({
    super.key,
    required this.errorMessage,
    required this.showRetry,
    required this.onRetry,
    required this.onDismiss,
  });

  final String? errorMessage;
  final bool showRetry;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final message = errorMessage?.trim();
    if (message == null || message.isEmpty) return const SizedBox.shrink();

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surfaceLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _onSurface,
                    fontSize: 12.5,
                    height: 18 / 12.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showRetry) ...[
                      OutlinedButton(
                        onPressed: onRetry,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _onSurface,
                          side: const BorderSide(color: _outline),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('重试'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    FilledButton(
                      onPressed: onDismiss,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('关闭'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TimelineTransferOverlay extends StatefulWidget {
  const TimelineTransferOverlay({
    super.key,
    required this.isVisible,
    this.label = '已加入日程',
  });

  final bool isVisible;
  final String label;

  @override
  State<TimelineTransferOverlay> createState() =>
      _TimelineTransferOverlayState();
}

class _TimelineTransferOverlayState extends State<TimelineTransferOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final AnimationController _alphaController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _alphaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    if (widget.isVisible) {
      _progressController.value = 1;
      _alphaController.value = 1;
    }
  }

  @override
  void didUpdateWidget(TimelineTransferOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible == oldWidget.isVisible) return;
    if (widget.isVisible) {
      _progressController.forward(from: 0);
      _alphaController.forward(from: 0);
    } else {
      _progressController.reverse();
      _alphaController.reverse();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _alphaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_progressController, _alphaController]),
      builder: (context, _) {
        if (!widget.isVisible && _alphaController.isDismissed) {
          return const SizedBox.shrink();
        }
        final progress = Curves.fastOutSlowIn.transform(
          _progressController.value,
        );
        return Positioned.fill(
          child: IgnorePointer(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final x = constraints.maxWidth * (0.42 + 0.25 * progress);
                final y = constraints.maxHeight * (0.68 + 0.22 * progress);
                final scale = 1 - 0.32 * progress;
                return Stack(
                  children: [
                    Positioned(
                      left: x,
                      top: y,
                      child: Opacity(
                        opacity: _alphaController.value,
                        child: Transform.scale(
                          scale: scale,
                          alignment: Alignment.topLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_primary, Color(0xFF97D3BD)],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timeline_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _RadialGlow extends StatelessWidget {
  const _RadialGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
