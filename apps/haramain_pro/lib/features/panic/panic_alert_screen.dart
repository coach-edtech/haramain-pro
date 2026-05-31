import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'panic_service.dart';

/// Panic alert screen for Muthawif/Team-Support to respond to alerts
/// Shows alert with audio beep + haptic, map view, and response buttons
class PanicAlertScreen extends StatefulWidget {
  final PanicAlert alert;
  final String responderId;
  final VoidCallback? onResponded;
  final VoidCallback? onDismissed;

  const PanicAlertScreen({
    super.key,
    required this.alert,
    required this.responderId,
    this.onResponded,
    this.onDismissed,
  });

  @override
  State<PanicAlertScreen> createState() => _PanicAlertScreenState();
}

class _PanicAlertScreenState extends State<PanicAlertScreen> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  bool _isResponding = false;
  PanicResponseAction? _selectedAction;
  Timer? _alertTimer;
  bool _audioPlaying = false;

  @override
  void initState() {
    super.initState();
    _markers.add(Marker(
      point: LatLng(widget.alert.latitude, widget.alert.longitude),
      child: const Icon(
        Icons.location_on,
        color: Colors.red,
        size: 48,
      ),
    ));
    _startAlertNotification();
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }

  void _startAlertNotification() {
    HapticFeedback.heavyImpact();
    _alertTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _stopAlertNotification() {
    _alertTimer?.cancel();
    _alertTimer = null;
  }

  Future<void> _respond(PanicResponseAction action) async {
    if (_isResponding) return;
    
    setState(() {
      _isResponding = true;
      _selectedAction = action;
    });
    
    _stopAlertNotification();
    HapticFeedback.mediumImpact();

    // Update panic status
    await PanicService.instance.updatePanicStatus(
      alertId: widget.alert.id,
      status: PanicStatus.responded,
      responderId: widget.responderId,
      responseType: action.name,
    );

    if (mounted) {
      setState(() {
        _isResponding = false;
      });
      
      widget.onResponded?.call();
      
      // Show confirmation and pop
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getActionConfirmationMessage(action)),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).pop();
    }
  }

  String _getActionConfirmationMessage(PanicResponseAction action) {
    switch (action) {
      case PanicResponseAction.stayJemput:
        return 'Response sent: Stay, saya jemput';
      case PanicResponseAction.sayaDiSini:
        return 'Response sent: Saya di sini';
      case PanicResponseAction.telepon:
        return 'Opening phone dialer...';
      default:
        return 'Response sent';
    }
  }

  Future<void> _makePhoneCall() async {
    // In production, this would get the Jamaah's phone number from the alert
    // For now, we show a placeholder
    final Uri phoneUri = Uri(scheme: 'tel', path: '+1234567890');
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch phone dialer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching phone: $e');
    }
  }

  void _dismissAlert() {
    _stopAlertNotification();
    HapticFeedback.lightImpact();
    widget.onDismissed?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final jamaahLocation = LatLng(widget.alert.latitude, widget.alert.longitude);
    
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text('PANIC ALERT'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _dismissAlert,
          ),
        ],
      ),
      body: Column(
        children: [
          // Alert header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.red,
            child: Column(
              children: [
                const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 8),
                const Text(
                  'JAMA AH NEEDS HELP!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Alert ID: ${widget.alert.id.substring(0, 8)}...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Time: ${_formatTime(widget.alert.timestamp)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Map view
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(widget.alert.latitude, widget.alert.longitude),
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.haramain.pro',
                  ),
                  MarkerLayer(
                    markers: _markers,
                  ),
                ],
              ),
            ),
          ),
          
          // Coordinates info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Lat: ${widget.alert.latitude.toStringAsFixed(6)}, Lng: ${widget.alert.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Response buttons
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ResponseButton(
                          label: 'Stay,\nSaya Jemput',
                          icon: Icons.directions_car,
                          color: Colors.blue,
                          isLoading: _isResponding && _selectedAction == PanicResponseAction.stayJemput,
                          onPressed: () => _respond(PanicResponseAction.stayJemput),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ResponseButton(
                          label: 'Saya\nDi Sini',
                          icon: Icons.person,
                          color: Colors.green,
                          isLoading: _isResponding && _selectedAction == PanicResponseAction.sayaDiSini,
                          onPressed: () => _respond(PanicResponseAction.sayaDiSini),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ResponseButton(
                          label: 'Telepon',
                          icon: Icons.phone,
                          color: Colors.orange,
                          isLoading: _isResponding && _selectedAction == PanicResponseAction.telepon,
                          onPressed: () {
                            _respond(PanicResponseAction.telepon);
                            _makePhoneCall();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ResponseButton(
                          label: 'Dismiss',
                          icon: Icons.close,
                          color: Colors.grey,
                          isLoading: false,
                          onPressed: _dismissAlert,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}

/// Individual response button widget
class _ResponseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ResponseButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Debug print helper
void debugPrint(String message) {
  // ignore: avoid_print
  print('[PanicAlertScreen] $message');
}
