import 'dart:async';
import 'package:flutter/material.dart';
import '../../design/design.dart';
import '../../models/user_model.dart';
import 'panic_service.dart';

class PanicAlertScreenPremium extends StatefulWidget {
  final String jamaaahId;
  final String grupId;
  final VoidCallback? onPanicSent;
  final Function(String)? onPanicFailed;

  const PanicAlertScreenPremium({
    super.key,
    required this.jamaaahId,
    this.grupId = '',
    this.onPanicSent,
    this.onPanicFailed,
  });

  @override
  State<PanicAlertScreenPremium> createState() => _PanicAlertScreenPremiumState();
}

class _PanicAlertScreenPremiumState extends State<PanicAlertScreenPremium>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _countdownController;
  late Animation<double> _countdownAnimation;

  int _countdown = 5;
  bool _isCountingDown = true;
  bool _isSending = false;
  bool _isSent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _countdownController = AnimationController(
      duration: Duration(seconds: _countdown),
      vsync: this,
    );

    _countdownAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.linear),
    );

    _startCountdown();
  }

  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
      });
      if (_countdown <= 0) {
        timer.cancel();
        _sendPanicAlert();
      }
    });
    _countdownController.forward();
  }

  void _cancelPanic() {
    Navigator.of(context).pop();
  }

  Future<void> _sendPanicAlert() async {
    setState(() {
      _isSending = true;
      _isCountingDown = false;
    });

    try {
      await PanicService.instance.sendPanic(
        jamaaahId: widget.jamaaahId,
        caravanaId: widget.grupId,
      );

      if (mounted) {
        setState(() {
          _isSent = true;
          _isSending = false;
        });
        widget.onPanicSent?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSending = false;
        });
        widget.onPanicFailed?.call(_error!);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),
              if (_isSent)
                _buildSuccessState(isDark)
              else
                _buildPanicState(isDark),
              const Spacer(),
              if (!_isSent && !_isSending)
                _buildCancelButton(isDark),
              if (_isSent)
                _buildDoneButton(isDark),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanicState(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isSending) ...[
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.1),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Mengirim Alert...',
            style: AppTypography.headlineSmall.copyWith(
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ] else if (_isCountingDown) ...[
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.error.withValues(alpha: 0.3),
                    AppColors.error.withValues(alpha: 0.1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$_countdown',
                      style: AppTypography.displayLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'PANIC ALERT',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tekan CANCEL untuk membatalkan',
            style: AppTypography.bodyLarge.copyWith(
              color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                  .withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                _error!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSuccessState(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.1),
          ),
          child: Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                size: 80,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'ALERT TERKIRIM',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Tim responsif telah diberitahu.\nAnda akan segera dibantu.',
          style: AppTypography.bodyLarge.copyWith(
            color: (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                .withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCancelButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _cancelPanic,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          side: BorderSide(
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        child: Text(
          'CANCEL',
          style: AppTypography.labelLarge.copyWith(
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildDoneButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          backgroundColor: AppColors.gold,
        ),
        child: Text(
          'SELESAI',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
