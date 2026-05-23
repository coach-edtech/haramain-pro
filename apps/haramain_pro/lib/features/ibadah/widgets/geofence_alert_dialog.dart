import 'package:flutter/material.dart';
import '../services/geofence_service.dart';
import '../services/ibadah_mode_service.dart';

/// Geofence alert dialog
/// Shows when entering mosque area, asks to enable Ibadah Mode
class GeofenceAlertDialog extends StatefulWidget {
  final MosqueLocation mosque;

  const GeofenceAlertDialog({
    super.key,
    required this.mosque,
  });

  /// Show the geofence alert dialog
  /// Returns true if user confirmed, false otherwise
  static Future<bool?> show(BuildContext context, MosqueLocation mosque) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GeofenceAlertDialog(mosque: mosque),
    );
  }

  @override
  State<GeofenceAlertDialog> createState() => _GeofenceAlertDialogState();
}

class _GeofenceAlertDialogState extends State<GeofenceAlertDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mosque,
              size: 36,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.mosque.nameArabic,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.mosque.name,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Anda masuk area masjid',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.volume_off,
                      color: Color(0xFF1B5E20),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Aktifkan режим Ibadah?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Semua notifikasi akan dibisukan, kecuali Panic Alert',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _dontShowAgain,
            onChanged: (value) {
              setState(() => _dontShowAgain = value ?? false);
            },
            title: const Text(
              'Jangan tampilkan lagi',
              style: TextStyle(fontSize: 14),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('Nanti Saja'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Save don't show again preference if checked
            if (_dontShowAgain) {
              await IbadahModeService.instance.setDontShowGeofenceAlert(true);
            }

            // Enable ibadah mode
            await IbadahModeService.instance.enableIbadahMode();

            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B5E20),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Aktifkan'),
        ),
      ],
    );
  }
}

/// Exit geofence alert dialog
/// Shows when exiting mosque area, asks to disable Ibadah Mode
class GeofenceExitDialog extends StatefulWidget {
  final MosqueLocation mosque;

  const GeofenceExitDialog({
    super.key,
    required this.mosque,
  });

  /// Show the exit geofence dialog
  static Future<bool?> show(BuildContext context, MosqueLocation mosque) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GeofenceExitDialog(mosque: mosque),
    );
  }

  @override
  State<GeofenceExitDialog> createState() => _GeofenceExitDialogState();
}

class _GeofenceExitDialogState extends State<GeofenceExitDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.exit_to_app,
              size: 36,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.mosque.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Anda keluar dari area masjid',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            'Apakah Anda ingin menonaktifkan режим Ibadah?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('Tetap Aktif'),
        ),
        ElevatedButton(
          onPressed: () async {
            await IbadahModeService.instance.disableIbadahMode();
            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Nonaktifkan'),
        ),
      ],
    );
  }
}
