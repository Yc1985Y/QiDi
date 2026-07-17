import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.isSubmitting,
    required this.message,
    required this.onLogin,
    required this.onRegister,
  });

  final bool isSubmitting;
  final String message;
  final void Function(String account, String password) onLogin;
  final void Function(String account, String password, String nickname)
  onRegister;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    final account = _accountController.text.trim();
    final password = _passwordController.text.trim();
    if (account.isEmpty || password.isEmpty) return;
    if (_isRegisterMode) {
      widget.onRegister(account, password, _nicknameController.text.trim());
      return;
    }
    widget.onLogin(account, password);
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF0C24A);
    const onBackground = Color(0xFF4A3810);
    const muted = Color(0xFF8B7337);
    const card = Color(0xFFFFFDF8);
    const glowBottom = Color(0xFFFFD98A);
    const error = Color(0xFFB3261E);

    final successMessage =
        widget.message.contains('成功') ||
        widget.message.contains('欢迎') ||
        widget.message.contains('退出');

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBEF), Color(0xFFFFFCF8), Color(0xFFFFF2CC)],
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: const Alignment(-0.78, -0.68),
              child: Container(
                width: 280,
                height: 260,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x8CFFE8A6), Colors.transparent],
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0.86, 0.58),
              child: Container(
                width: 240,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowBottom.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            const Positioned.fill(child: _LoginDustField()),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 72,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          widthFactor: 1,
                          child: Text(
                            '织时',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '织时',
                        style: TextStyle(
                          color: onBackground,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '将校园信息碎片整理成清晰时间线',
                        style: TextStyle(
                          color: muted,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 36),
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: 4,
                        color: card,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _isRegisterMode ? '创建账号' : '欢迎回来',
                                          style: const TextStyle(
                                            color: onBackground,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _isRegisterMode
                                              ? '本地账号会保存在当前设备中'
                                              : '使用本地账号进入个人时间线',
                                          style: const TextStyle(
                                            color: muted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() {
                                        _isRegisterMode = !_isRegisterMode;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        _isRegisterMode ? '去登录' : '去注册',
                                        style: const TextStyle(
                                          color: primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_isRegisterMode) ...[
                                _LoginTextField(
                                  controller: _nicknameController,
                                  label: '昵称',
                                  icon: Icons.badge_rounded,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 16),
                              ],
                              _LoginTextField(
                                controller: _accountController,
                                label: '学号或邮箱',
                                icon: Icons.person_rounded,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              _LoginTextField(
                                controller: _passwordController,
                                label: '密码',
                                icon: Icons.lock_rounded,
                                obscureText: true,
                                keyboardType: TextInputType.visiblePassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                              ),
                              if (widget.message.trim().isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  widget.message,
                                  style: TextStyle(
                                    color: successMessage ? muted : error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 54,
                                child: FilledButton(
                                  onPressed: widget.isSubmitting
                                      ? null
                                      : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: primary,
                                    disabledBackgroundColor: primary.withValues(
                                      alpha: 0.55,
                                    ),
                                    shape: const StadiumBorder(),
                                  ),
                                  child: Text(
                                    widget.isSubmitting
                                        ? '正在校验账号'
                                        : _isRegisterMode
                                        ? '注册并进入织时'
                                        : '进入织时',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
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
          ],
        ),
      ),
    );
  }
}

class _LoginDustField extends StatefulWidget {
  const _LoginDustField();

  @override
  State<_LoginDustField> createState() => _LoginDustFieldState();
}

class _LoginDustFieldState extends State<_LoginDustField> {
  int? _pulseStarIndex;
  int _pulseNonce = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) {
            final size = constraints.biggest;
            int? tappedIndex;
            for (
              var index = 0;
              index < _LoginDustPainter.points.length;
              index++
            ) {
              final point = _LoginDustPainter.scalePoint(
                _LoginDustPainter.points[index],
                size,
              );
              if ((point - details.localPosition).distance <= 18) {
                tappedIndex = index;
                break;
              }
            }
            if (tappedIndex == null) return;
            setState(() {
              _pulseStarIndex = tappedIndex;
              _pulseNonce++;
            });
          },
          child: TweenAnimationBuilder<double>(
            key: ValueKey(_pulseNonce),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 620),
            curve: Curves.fastOutSlowIn,
            builder: (context, progress, _) {
              return CustomPaint(
                size: constraints.biggest,
                painter: _LoginDustPainter(
                  pulseStarIndex: _pulseStarIndex,
                  pulseProgress: progress,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _LoginDustPainter extends CustomPainter {
  const _LoginDustPainter({
    required this.pulseStarIndex,
    required this.pulseProgress,
  });

  final int? pulseStarIndex;
  final double pulseProgress;

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

  static const _sizes = <double>[3, 2, 3, 2, 2, 2, 3, 1, 1, 2, 1, 1];

  static const _palette = <Color>[
    Color(0xFFF0C24A),
    Color(0xFFFFE8A6),
    Color(0xFFFFD98A),
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < 6; index++) {
      canvas.drawLine(
        _scale(points[index], size),
        _scale(points[index + 1], size),
        Paint()
          ..color = _palette[(index + 1) % _palette.length].withValues(
            alpha: 0.16,
          )
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round,
      );
    }
    for (var index = 0; index < points.length; index++) {
      final center = _scale(points[index], size);
      final radius = _sizes[index];
      final color = _palette[index % _palette.length];
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
            ..color = color.withValues(alpha: 0.22)
            ..strokeWidth = 0.8,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - radius * 3),
          Offset(center.dx, center.dy + radius * 3),
          Paint()
            ..color = color.withValues(alpha: 0.18)
            ..strokeWidth = 0.8,
        );
      }
    }
    final pulseIndex = pulseStarIndex;
    if (pulseIndex != null && pulseProgress < 1) {
      final pulse = _scale(points[pulseIndex], size);
      final color = _palette[pulseIndex % _palette.length];
      final alpha = 1 - pulseProgress;
      canvas.drawCircle(
        pulse,
        10 + 42 * pulseProgress,
        Paint()..color = color.withValues(alpha: .055 * alpha),
      );
      canvas.drawCircle(
        pulse,
        2 + 5 * pulseProgress,
        Paint()..color = Colors.white.withValues(alpha: .18 * alpha),
      );
      canvas.drawCircle(
        pulse,
        6 + 26 * pulseProgress,
        Paint()..color = color.withValues(alpha: .18 * alpha),
      );
    }
  }

  Offset _scale(Offset point, Size size) {
    return scalePoint(point, size);
  }

  static Offset scalePoint(Offset point, Size size) =>
      Offset(point.dx * size.width, point.dy * size.height);

  @override
  bool shouldRepaint(covariant _LoginDustPainter oldDelegate) {
    return pulseStarIndex != oldDelegate.pulseStarIndex ||
        pulseProgress != oldDelegate.pulseProgress;
  }
}

class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.textInputAction,
    this.keyboardType,
    this.obscureText = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFF0C24A);
    const outline = Color(0xFFEEDDA1);
    const muted = Color(0xFF8B7337);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        prefixIcon: Icon(icon, color: primary),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: muted),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: outline),
          borderRadius: BorderRadius.circular(18),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: primary),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
