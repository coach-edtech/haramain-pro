import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ibadah_mode_service.dart';

/// Ibadah mode toggle widget
/// Switch to enable/disable ibadah mode with haptic feedback
class IbadahModeToggle extends StatefulWidget {
  /// If true, shows compact version for home screen
  final bool compact;

  /// Callback when toggle is changed
  final Function(bool enabled)? onToggle;

  const IbadahModeToggle({
    super.key,
    this.compact = false,
    this.onToggle,
  });

  @override
  State<IbadahModeToggle> createState() => _IbadahModeToggleState();
}

class _IbadahModeToggleState extends State<IbadahModeToggle> {
  final IbadahModeService _service = IbadahModeService.instance;

  void _onChanged(bool value) {
    // Haptic feedback
    HapticFeedback.mediumImpact();

    if (value) {
      _service.enableIbadahMode().then((_) {
        widget.onToggle?.call(true);
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to enable Ibadah Mode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      });
    } else {
      _service.disableIbadahMode().then((_) {
        widget.onToggle?.call(false);
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disable Ibadah Mode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactToggle();
    }
    return _buildFullToggle();
  }

  Widget _buildCompactToggle() {
    return GestureDetector(
      onTap: () => _onChanged(!_service.isEnabled),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _service.isEnabled
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _service.isEnabled ? Icons.mosque : Icons.mosque_outlined,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              _service.isEnabled ? 'Ibadah' : 'Normal',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _service.isEnabled
            ? const Color(0xFF1B5E20).withValues(alpha: 0.1)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _service.isEnabled
              ? const Color(0xFF1B5E20)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _service.isEnabled
                      ? const Color(0xFF1B5E20)
                      : Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _service.isEnabled ? Icons.mosque : Icons.mosque_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ' режим Ibadah',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _service.isEnabled
                            ? const Color(0xFF1B5E20)
                            : Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      _service.isEnabled
                          ? 'Semua notifikasi dibisukan'
                          : 'Tekan untuk mengaktifkan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _service.isEnabled,
                onChanged: _onChanged,
                activeTrackColor: const Color(0xFF1B5E20).withValues(alpha: 0.5),
                activeThumbColor: const Color(0xFF1B5E20),
              ),
            ],
          ),
          if (_service.isEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.volume_off,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notifikasi dibisukan, Panic tetap aktif',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Small ibadah mode indicator badge for home screen
class IbadahModeBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const IbadahModeBadge({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final service = IbadahModeService.instance;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: service.isEnabled
              ? const Color(0xFF1B5E20)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              service.isEnabled ? Icons.mosque : Icons.mosque_outlined,
              color: service.isEnabled ? Colors.white : Colors.grey.shade600,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              service.isEnabled ? 'Ibadah Mode' : 'Normal',
              style: TextStyle(
                color: service.isEnabled ? Colors.white : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
