import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'panic_service.dart';
import '../../services/location_service.dart';

enum PanicButtonState {
  idle,
  countdown,
  loading,
  success,
  error,
}

class PanicButtonWidget extends StatefulWidget {
  final String jamaaahId;
  final String grupId;
  final LocationData? initialLocation;
  final VoidCallback? onPanicSent;
  final Function(String error)? onPanicFailed;
  final int countdownSeconds;

  const PanicButtonWidget({
    super.key,
    required this.jamaaahId,
    required this.grupId,
    this.initialLocation,
    this.onPanicSent,
    this.onPanicFailed,
    this.countdownSeconds = 5,
  });

  @override
  State<PanicButtonWidget> createState() => _PanicButtonWidgetState();
}

class _PanicButtonWidgetState extends State<PanicButtonWidget>
    with SingleTickerProviderStateMixin {
  PanicButtonState _state = PanicButtonState.idle;
  String? _lastError;
  Timer? _countdownTimer;
  int _remainingSeconds = 5;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.countdownSeconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    HapticFeedback.heavyImpact();
    
    setState(() {
      _state = PanicButtonState.countdown;
      _remainingSeconds = widget.countdownSeconds;
    });
    
    _pulseController.stop();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
        
        HapticFeedback.lightImpact();
        
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _sendPanic();
        }
      }
    });
  }

  void _cancelPanic() {
    _countdownTimer?.cancel();
    _pulseController.repeat(reverse: true);
    
    HapticFeedback.mediumImpact();
    
    setState(() {
      _state = PanicButtonState.idle;
      _remainingSeconds = widget.countdownSeconds;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Panic alert cancelled'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.grey,
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
          _state = PanicButtonState.success;
        });
        
        widget.onPanicSent?.call();
        
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          setState(() {
            _state = PanicButtonState.idle;
          });
        }
      } else {
        HapticFeedback.vibrate();
        
        setState(() {
          _state = PanicButtonState.error;
          _lastError = result.error;
        });
        
        widget.onPanicFailed?.call(result.error ?? 'Unknown error');
        
        await Future.delayed(const Duration(seconds: 5));
        if (mounted) {
          setState(() {
            _state = PanicButtonState.idle;
          });
        }
      }
    } catch (e) {
      HapticFeedback.vibrate();
      
      setState(() {
        _state = PanicButtonState.error;
        _lastError = e.toString();
      });
      
      widget.onPanicFailed?.call(e.toString());
      
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _state = PanicButtonState.idle;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_state == PanicButtonState.error && _lastError != null)
          _ErrorBanner(error: _lastError!),
        if (_state == PanicButtonState.success)
          const _SuccessBanner(),
        if (_state == PanicButtonState.countdown)
          _CountdownBanner(
            seconds: _remainingSeconds,
            onCancel: _cancelPanic,
          ),
        GestureDetector(
          onTap: _canTrigger() ? _startCountdown : null,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _state == PanicButtonState.idle ? _pulseAnimation.value : 1.0,
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
                    color: Colors.red.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: _buildButtonContent(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getButtonLabel(),
          style: TextStyle(
            color: Colors.red.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
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
        return Colors.red;
      case PanicButtonState.countdown:
        return Colors.orange;
      case PanicButtonState.loading:
        return Colors.red.shade300;
      case PanicButtonState.success:
        return Colors.green;
      case PanicButtonState.error:
        return Colors.red.shade900;
    }
  }

  Widget _buildButtonContent() {
    switch (_state) {
      case PanicButtonState.idle:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_rounded, color: Colors.white, size: 32),
            SizedBox(height: 2),
            Text(
              'PANIC',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
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
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'TAP TO CANCEL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w600,
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
      case PanicButtonState.success:
        return const Icon(Icons.check, color: Colors.white, size: 40);
      case PanicButtonState.error:
        return const Icon(Icons.error_outline, color: Colors.white, size: 40);
    }
  }

  String _getButtonLabel() {
    switch (_state) {
      case PanicButtonState.idle:
        return 'Hold 5s for Emergency';
      case PanicButtonState.countdown:
        return 'Sending in $_remainingSeconds...';
      case PanicButtonState.loading:
        return 'Sending...';
      case PanicButtonState.success:
        return 'Alert Sent!';
      case PanicButtonState.error:
        return 'Failed - Tap to Retry';
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;

  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade800, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade800, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade800, size: 16),
          const SizedBox(width: 8),
          Text(
            'Panic alert sent!',
            style: TextStyle(color: Colors.green.shade800, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade800, size: 16),
          const SizedBox(width: 8),
          Text(
            'Emergency alert in $seconds seconds',
            style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
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
