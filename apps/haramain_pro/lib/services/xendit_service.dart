import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Xendit Payment Service for Haramain Pro
/// Handles invoice creation and payment polling for Safety Pass purchases
class XenditService {
  static final XenditService _instance = XenditService._internal();
  static XenditService get instance => _instance;
  XenditService._internal();

  // TODO: Replace with actual Supabase project URL
  static const String _edgeFunctionUrl =
      'https://<project-id>.supabase.co/functions/v1/xendit-invoice';

  final SupabaseClient _client = Supabase.instance.client;

  /// Create Xendit invoice for Safety Pass purchase
  /// 
  /// [amount] - Amount in IDR (e.g., 120000 for Rp 120,000)
  /// [description] - Description for the invoice
  /// 
  /// Returns [XenditInvoice] on success, null on failure
  Future<XenditInvoice?> createInvoice({
    required int amount,
    String description = 'Haramain Pro Safety Pass - Umrah Mandiri',
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('XenditService: No authenticated user');
        return null;
      }

      final session = await _client.auth.getSession();
      if (session == null) {
        debugPrint('XenditService: No active session');
        return null;
      }

      debugPrint('XenditService: Creating invoice for amount=$amount');

      final response = await http.post(
        Uri.parse(_edgeFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'amount': amount,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('XenditService: Invoice created successfully: ${data['invoice_id']}');
        return XenditInvoice.fromJson(data);
      }

      debugPrint('XenditService: Invoice creation failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('XenditService: Error creating invoice: $e');
      return null;
    }
  }

  /// Poll invoice status until paid, expired, or max attempts reached
  /// 
  /// [invoiceId] - The Xendit invoice ID to poll
  /// [maxAttempts] - Maximum number of polling attempts (default: 60)
  /// [interval] - Time between polling attempts (default: 2 seconds)
  /// 
  /// Returns true if invoice is PAID, false if EXPIRED, FAILED, or polling failed
  Future<bool> pollInvoicePayment({
    required String invoiceId,
    int maxAttempts = 60,
    Duration interval = const Duration(seconds: 2),
  }) async {
    debugPrint('XenditService: Starting poll for invoice=$invoiceId');

    for (int i = 0; i < maxAttempts; i++) {
      try {
        final status = await _getInvoiceStatus(invoiceId);
        
        if (status == null) {
          debugPrint('XenditService: Poll attempt $i - status check failed');
        } else {
          debugPrint('XenditService: Poll attempt $i - status=$status');
          
          if (status == 'PAID') {
            debugPrint('XenditService: Invoice paid successfully');
            return true;
          }
          
          if (status == 'EXPIRED' || status == 'FAILED') {
            debugPrint('XenditService: Invoice $status');
            return false;
          }
        }
      } catch (e) {
        debugPrint('XenditService: Poll error on attempt $i: $e');
      }
      
      await Future.delayed(interval);
    }

    debugPrint('XenditService: Poll timed out after $maxAttempts attempts');
    return false;
  }

  /// Get invoice status from Xendit
  /// Returns status string: 'PAID', 'PENDING', 'EXPIRED', 'FAILED', or null on error
  Future<String?> _getInvoiceStatus(String invoiceId) async {
    try {
      // In production, this should call an edge function to check status
      // For now, we rely on the callback/webhook for status updates
      // This is a placeholder - actual implementation would need a status-check edge function
      debugPrint('XenditService: Status check for invoice $invoiceId - relying on callback');
      return null;
    } catch (e) {
      debugPrint('XenditService: Error getting invoice status: $e');
      return null;
    }
  }

  /// Activate premium subscription after successful payment
  /// 
  /// Creates a subscription record and updates the user's profile
  Future<bool> activatePremium() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        debugPrint('XenditService: Cannot activate premium - no user');
        return false;
      }

      final endDate = DateTime.now().add(const Duration(days: 365)); // Lifetime = 1 year

      // Create subscription record
      await _client.from('subscriptions').insert({
        'user_id': user.id,
        'tier': 'safety_pass',
        'status': 'active',
        'start_date': DateTime.now().toIso8601String(),
        'end_date': endDate.toIso8601String(),
      });

      // Update profile
      await _client.from('profiles').update({
        'subscription_tier': 'active',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      debugPrint('XenditService: Premium activated for user ${user.id}');
      return true;
    } catch (e) {
      debugPrint('XenditService: Error activating premium: $e');
      return false;
    }
  }
}

/// Data class representing a Xendit Invoice
class XenditInvoice {
  final String invoiceId;
  final String invoiceUrl;
  final DateTime expiryDate;
  final String? externalId;

  XenditInvoice({
    required this.invoiceId,
    required this.invoiceUrl,
    required this.expiryDate,
    this.externalId,
  });

  factory XenditInvoice.fromJson(Map<String, dynamic> json) {
    return XenditInvoice(
      invoiceId: json['invoice_id'] as String,
      invoiceUrl: json['invoice_url'] as String,
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      externalId: json['external_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_id': invoiceId,
      'invoice_url': invoiceUrl,
      'expiry_date': expiryDate.toIso8601String(),
      if (externalId != null) 'external_id': externalId,
    };
  }

  @override
  String toString() {
    return 'XenditInvoice(id: $invoiceId, url: $invoiceUrl, expires: $expiryDate)';
  }
}
