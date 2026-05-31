import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../design/tokens/app_colors.dart';
import '../../design/tokens/app_typography.dart';
import '../../design/tokens/app_spacing.dart';
import 'panic_service.dart';
import '../../services/location_service.dart';

/// Panic Button states as per FRONTEND-SPEC.md Section 4.2
enum PanicButtonState {
  idle,        // Red, subtle pulse animation
  pressed,     // Scale 1.08, intense glow
  countdown,   // Tap to cancel countdown
  loading,     // Spinner + "Mengirim..."
  sent,        // Green checkmark, "Telah dikirim"
  acknowledged, // Green + responder name + ETA
  error,       // Red + retry icon
}

/// Premium Panic Button Widget
/// Revenue-critical feature - built to spec with all states and animations
class PanicButtonPremium extends StatefulWidget {
  final String jamaaahId;
  final String grupId;
  final LocationData? initialLocation;
  final VoidCallback? onPanicSent;
  final Function(String error)? onPanicFailed;
  final Function(String responderName, String eta)? onAcknowledged;
  final int countdownSeconds;
  final bool showConfirmationDialog;

  const PanicButtonPremium({
    super.key,
    required this.jamaaahId,
    required this.grupId,
    this.initialLocation,
    this.onPanicSent,
    this.onPanicFailed,
    this.onAcknowledged,
    this.countdownSeconds = 5,
    this.showConfirmationDialog = true,
  });

  @override
  State<PanicButtonPremium> createState() => _PanicButtonPremiumState();
}

class _PanicButtonPremiumState extends State<PanicButtonPremium>
    with TickerProviderStateMixin {
  PanicButtonState _state = PanicButtonState.idle;
  String? _lastError;
  String? _responderName;
  String? _responderEta;
  Timer? _countdownTimer;
  int _remainingSeconds = 5;

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _pressedScaleController;
  late Animation<double> _pressedScaleAnimation;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.countdownSeconds;

    // Idle pulse animation: scale 1.0 -> 1.02, 2s infinite
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    // Pressed scale animation: scale 1.0 -> 1.08, 300ms
    _pressedScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pressedScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pressedScaleController, curve: Curves.easeOut),
    );

    // Glow intensity animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _glowAnimation = Tween<double>(begin: 0.4, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _pressedScaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onPanicPressed() {
    if (_state != PanicButtonState.idle) return;

    HapticFeedback.heavyImpact();

    setState(() {
      _state = PanicButtonState.pressed;
    });

    // Animate scale up
    _pulseController.stop();
    _pressedScaleController.forward();
    _glowController.forward();

    // Start countdown after press animation
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _startCountdown();
      }
    });
  }

  void _startCountdown() {
    setState(() {
      _state = PanicButtonState.countdown;
      _remainingSeconds = widget.countdownSeconds;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });

      HapticFeedback.lightImpact();

      if (_remainingSeconds <= 0) {
        timer.cancel();
        _sendPanic();
      }
    });
  }

  void _cancelPanic() {
    _countdownTimer?.cancel();
    _pressedScaleController.reverse();
    _glowController.reverse();
    _pulseController.repeat(reverse: true);

    HapticFeedback.mediumImpact();

    setState(() {
      _state = PanicButtonState.idle;
      _remainingSeconds = widget.countdownSeconds;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Panic alert dibatalkan'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.slate600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }

  Future<void> _sendPanic() async {
    setState(() {
      _state = PanicButtonState.loading;
      _lastError = null;
    });

    try {
      final result = await PanicService.instance.sendPanic(
        jamaaahId: widget.jamaaahId,
        caravanaId: widget.grupId,
        coordinates: widget.initialLocation,
      );

      if (result.success) {
        HapticFeedback.mediumImpact();

        setState(() {
          _state = PanicButtonState.sent;
        });

        widget.onPanicSent?.call();

        // Auto-reset after 5 seconds
        await Future.delayed(const Duration(seconds: 5));
        if (mounted) {
          _resetToIdle();
        }
      } else {
        _handleError(result.error ?? 'Gagal mengirim alert');
      }
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _handleError(String error) {
    HapticFeedback.vibrate();

    setState(() {
      _state = PanicButtonState.error;
      _lastError = error;
    });

    widget.onPanicFailed?.call(error);

    // Auto-reset after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        _resetToIdle();
      }
    });
  }

  void _retry() {
    _resetToIdle();
    _startCountdown();
  }

  void _resetToIdle() {
    _pressedScaleController.reverse();
    _glowController.reverse();
    _pulseController.repeat(reverse: true);

    setState(() {
      _state = PanicButtonState.idle;
      _remainingSeconds = widget.countdownSeconds;
      _lastError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status banners
        if (_state == PanicButtonState.error && _lastError != null)
          _ErrorBanner(error: _lastError!, onRetry: _retry),
        if (_state == PanicButtonState.sent) const _SentBanner(),
        if (_state == PanicButtonState.acknowledged && _responderName != null)
          _AcknowledgedBanner(name: _responderName!, eta: _responderEta),
        if (_state == PanicButtonState.countdown)
          _CountdownBanner(
            seconds: _remainingSeconds,
            onCancel: _cancelPanic,
          ),

        // The panic button itself
        GestureDetector(
          onTap: _canTrigger() ? _onPanicPressed : null,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _pulseAnimation,
              _pressedScaleAnimation,
              _glowAnimation,
            ]),
            builder: (context, child) {
              double scale = 1.0;
              if (_state == PanicButtonState.idle) {
                scale = _pulseAnimation.value;
              } else if (_state == PanicButtonState.pressed) {
                scale = _pressedScaleAnimation.value;
              }

              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getButtonColor(),
                boxShadow: [
                  BoxShadow(
                    color: _getButtonColor().withValues(
                      alpha: _state == PanicButtonState.pressed
                          ? _glowAnimation.value
                          : 0.4,
                    ),
                    blurRadius: _state == PanicButtonState.pressed ? 20 : 12,
                    spreadRadius: _state == PanicButtonState.pressed ? 4 : 2,
                  ),
                ],
              ),
              child: Center(
                child: _buildButtonContent(),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Label below button
        Text(
          _getButtonLabel(),
          style: AppTypography.labelMedium.copyWith(
            color: _getLabelColor(),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  bool _canTrigger() {
    return _state == PanicButtonState.idle;
  }

  Color _getButtonColor() {
    switch (_state) {
      case PanicButtonState.idle:
        return AppColors.red600;
      case PanicButtonState.pressed:
        return AppColors.red500;
      case PanicButtonState.countdown:
        return AppColors.amber500;
      case PanicButtonState.loading:
        return AppColors.red600.withValues(alpha: 0.7);
      case PanicButtonState.sent:
      case PanicButtonState.acknowledged:
        return AppColors.emerald500;
      case PanicButtonState.error:
        return AppColors.red900;
    }
  }

  Color _getLabelColor() {
    switch (_state) {
      case PanicButtonState.idle:
        return AppColors.red600;
      case PanicButtonState.countdown:
        return AppColors.amber600;
      case PanicButtonState.loading:
        return AppColors.slate600;
      case PanicButtonState.sent:
      case PanicButtonState.acknowledged:
        return AppColors.emerald700;
      case PanicButtonState.error:
        return AppColors.red600;
      case PanicButtonState.pressed:
        return AppColors.red500;
    }
  }

  Widget _buildButtonContent() {
    switch (_state) {
      case PanicButtonState.idle:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emergency,
              color: Colors.white,
              size: 32,
            ),
            SizedBox(height: 2),
            Text(
              'PANIC',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        );

      case PanicButtonState.pressed:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emergency,
              color: Colors.white,
              size: 36,
            ),
            SizedBox(height: 2),
            Text(
              'HOLD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        );

      case PanicButtonState.countdown:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_remainingSeconds',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'TAP TO CANCEL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        );

      case PanicButtonState.loading:
        return const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );

      case PanicButtonState.sent:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check,
              color: Colors.white,
              size: 36,
            ),
            SizedBox(height: 2),
            Text(
              'SENT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        );

      case PanicButtonState.acknowledged:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              color: Colors.white,
              size: 32,
            ),
            SizedBox(height: 2),
            Text(
              'HELP\nCOMING',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );

      case PanicButtonState.error:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh,
              color: Colors.white,
              size: 32,
            ),
            SizedBox(height: 2),
            Text(
              'RETRY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        );
    }
  }

  String _getButtonLabel() {
    switch (_state) {
      case PanicButtonState.idle:
        return 'Tekan jika butuh bantuan';
      case PanicButtonState.pressed:
        return 'Lepaskan untuk batal';
      case PanicButtonState.countdown:
        return 'Mengirim dalam $_remainingSeconds...';
      case PanicButtonState.loading:
        return 'Mengirim alert...';
      case PanicButtonState.sent:
        return 'Alert terkirim!';
      case PanicButtonState.acknowledged:
        return '$_responderName menuju lokasi Anda';
      case PanicButtonState.error:
        return 'Gagal - Tekan untuk retry';
    }
  }
}

/// Error banner with retry action
class _ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorBanner({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.red100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.red600, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.red600,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              error,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.red600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.red600,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
              child: Text(
                'RETRY',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Success banner
class _SentBanner extends StatelessWidget {
  const _SentBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.emerald100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.emerald500, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.emerald700,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Alert terkirim ke Muthawif',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.emerald700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Acknowledged banner showing responder info
class _AcknowledgedBanner extends StatelessWidget {
  final String name;
  final String? eta;

  const _AcknowledgedBanner({
    required this.name,
    this.eta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.emerald100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.emerald500, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on,
            color: AppColors.emerald700,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$name sedang menuju lokasi Anda',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.emerald700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (eta != null)
                  Text(
                    'ETA: $eta',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.emerald600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Countdown banner with cancel button
class _CountdownBanner extends StatelessWidget {
  final int seconds;
  final VoidCallback onCancel;

  const _CountdownBanner({
    required this.seconds,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.amber50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.amber500, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber,
            color: AppColors.amber600,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Emergency alert dalam $seconds detik',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.amber600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.amber500,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
              child: Text(
                'BATAL',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Positioned panic button for home screen
class PanicButtonPositioned extends StatelessWidget {
  final Widget panicButton;
  final double bottomPadding;

  const PanicButtonPositioned({
    super.key,
    required this.panicButton,
    this.bottomPadding = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottomPadding,
      left: 0,
      right: 0,
      child: Center(child: panicButton),
    );
  }
}
