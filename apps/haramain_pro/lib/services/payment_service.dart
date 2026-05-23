import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// DEPRECATED: PaymentService using Midtrans
/// 
/// This class is kept for reference only. All B2C payments now use [XenditService].
/// 
/// To be removed after B2B payment features are implemented.
/// 
/// @deprecated Use [XenditService] instead for B2C Safety Pass purchases.
@Deprecated('Use XenditService instead. Kept for future B2B payment reference.')
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  static PaymentService get instance => _instance;
  PaymentService._internal();

  // TODO: Move to environment variables - never hardcode credentials
  static const String _baseUrl = 'https://app.sandbox.midtrans.com/snap/v1';
  // Using placeholder - actual key should be in environment
  static const String _serverKey = 'SB-Mid-server-PLACEHOLDER';
  
  final SupabaseClient _client = Supabase.instance.client;

  static String get clientKey => 'SB-Mid-client-PLACEHOLDER';

  /// @deprecated Use XenditService for B2C payments
  @Deprecated('Use XenditService instead')
  Future<bool> hasActiveSubscription() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'active')
          .gte('end_date', DateTime.now().toIso8601String())
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'active')
          .gte('end_date', DateTime.now().toIso8601String())
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error getting subscription: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getTrialStatus() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return {
          'isInTrial': false,
          'remainingDays': 0,
          'trialStartDate': null,
        };
      }

      final profile = await _client
          .from('profiles')
          .select('consent_given_at')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        return {
          'isInTrial': false,
          'remainingDays': 0,
          'trialStartDate': null,
        };
      }

      final consentDateStr = profile['consent_given_at'] as String?;
      if (consentDateStr == null) {
        return {
          'isInTrial': false,
          'remainingDays': 0,
          'trialStartDate': null,
        };
      }

      final consentDate = DateTime.parse(consentDateStr);
      final trialEndDate = consentDate.add(const Duration(days: 7));
      final now = DateTime.now();
      final remainingDays = trialEndDate.difference(now).inDays;

      return {
        'isInTrial': remainingDays > 0,
        'remainingDays': remainingDays > 0 ? remainingDays : 0,
        'trialStartDate': consentDate.toIso8601String(),
        'trialEndDate': trialEndDate.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting trial status: $e');
      return {
        'isInTrial': false,
        'remainingDays': 0,
        'trialStartDate': null,
      };
    }
  }

  /// @deprecated Use XenditService.createInvoice() instead
  @Deprecated('Use XenditService.createInvoice() instead')
  Future<Map<String, dynamic>?> createTransaction({
    required String tier,
    required int amount,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final profile = await _client
          .from('profiles')
          .select('name')
          .eq('id', user.id)
          .maybeSingle();

      final orderId = 'HP-${user.id.substring(0, 8)}-${DateTime.now().millisecondsSinceEpoch}';

      final response = await http.post(
        Uri.parse('$_baseUrl/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_serverKey:'))}',
        },
        body: jsonEncode({
          'transaction_details': {
            'order_id': orderId,
            'gross_amount': amount,
          },
          'customer_details': {
            'first_name': profile?['name'] ?? 'User',
            'email': user.email,
            'user_id': user.id,
          },
          'item_details': [
            {
              'id': tier,
              'price': amount,
              'quantity': 1,
              'name': 'Haramain Pro $tier Package',
            }
          ],
          'callbacks': {
            'finish': 'haramainpro://payment/finish',
          },
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'token': data['token'],
          'redirect_url': data['redirect_url'],
          'order_id': orderId,
        };
      }

      debugPrint('Midtrans error: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error creating transaction: $e');
      return null;
    }
  }

  Future<bool> handleWebhook(Map<String, dynamic> data) async {
    try {
      final orderId = data['order_id'] as String?;
      final transactionStatus = data['transaction_status'] as String?;
      final paymentType = data['payment_type'] as String?;

      if (orderId == null || transactionStatus == null) {
        return false;
      }

      final existingPayment = await _client
          .from('payments')
          .select('id, user_id')
          .eq('midtrans_order_id', orderId)
          .maybeSingle();

      if (existingPayment == null) {
        final userId = _extractUserIdFromOrderId(orderId);
        if (userId == null) return false;

        await _client.from('payments').insert({
          'user_id': userId,
          'amount': (data['gross_amount'] as num?)?.toDouble() ?? 0,
          'currency': 'SAR',
          'status': _mapTransactionStatus(transactionStatus),
          'midtrans_order_id': orderId,
          'midtrans_transaction_id': data['transaction_id'],
          'payment_type': paymentType,
        });

        if (transactionStatus == 'settlement') {
          await _activateSubscription(userId, data['subscription_id'] as String?);
        }
      } else {
        await _client.from('payments').update({
          'status': _mapTransactionStatus(transactionStatus),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existingPayment['id']);

        if (transactionStatus == 'settlement') {
          await _activateSubscription(
            existingPayment['user_id'] as String,
            data['subscription_id'] as String?,
          );
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error handling webhook: $e');
      return false;
    }
  }

  String? _extractUserIdFromOrderId(String orderId) {
    final parts = orderId.split('-');
    if (parts.length >= 2) {
      return parts[1];
    }
    return null;
  }

  String _mapTransactionStatus(String status) {
    switch (status) {
      case 'capture':
      case 'settlement':
        return 'settlement';
      case 'pending':
        return 'pending';
      case 'deny':
        return 'deny';
      case 'cancel':
        return 'cancel';
      case 'expire':
        return 'expire';
      case 'refund':
        return 'refund';
      default:
        return 'pending';
    }
  }

  Future<void> _activateSubscription(String userId, String? tier) async {
    try {
      final endDate = DateTime.now().add(const Duration(days: 365));

      await _client.from('subscriptions').insert({
        'user_id': userId,
        'tier': tier ?? 'basic',
        'status': 'active',
        'start_date': DateTime.now().toIso8601String(),
        'end_date': endDate.toIso8601String(),
      });

      await _client.from('profiles').update({
        'subscription_tier': 'active',
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Error activating subscription: $e');
    }
  }

  Future<bool> cancelSubscription() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client.from('subscriptions').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', user.id).eq('status', 'active');

      await _client.from('profiles').update({
        'subscription_tier': 'expired',
      }).eq('id', user.id);

      return true;
    } catch (e) {
      debugPrint('Error cancelling subscription: $e');
      return false;
    }
  }
}
