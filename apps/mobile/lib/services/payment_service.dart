// ISOTOPE — Payment Service
// Yoco Integration for South Africa
// R99 trial, R139/mo Pro, R299/mo Elite

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class PaymentService {
  final ApiService _api = ApiService();

  // ============================================
  // PRICING TIERS (ZAR)
  // ============================================

  static const Map<String, PricingTier> tiers = {
    'trial': PricingTier(
      id: 'trial',
      name: '7-Day Trial',
      price: 0,
      currency: 'ZAR',
      description: 'Test drive ISOTOPE',
      features: [
        '2 signals/week',
        'Delayed by 1 hour',
        'Public signal log access',
        'Basic confidence scores',
      ],
      buttonText: 'Start Free Trial',
      popular: false,
    ),
    'pro': PricingTier(
      id: 'pro',
      name: 'Pro',
      price: 139,
      currency: 'ZAR',
      description: 'For serious traders',
      features: [
        'Real-time signals (6AM, 12PM, 4PM)',
        '5-7 signals/week',
        'Confidence scores (60-85%)',
        'Weekly performance recap',
        'Private Telegram group',
        'Cancel anytime',
      ],
      buttonText: 'Upgrade to Pro',
      popular: true,
    ),
    'elite': PricingTier(
      id: 'elite',
      name: 'Elite',
      price: 299,
      currency: 'ZAR',
      description: 'Maximum edge',
      features: [
        'Everything in Pro',
        'Private WhatsApp group',
        'Monthly 30-min audio Q&A',
        'Priority signal review',
        'Direct founder access',
      ],
      buttonText: 'Upgrade to Elite',
      popular: false,
    ),
    'annual': PricingTier(
      id: 'annual',
      name: 'Annual',
      price: 1499,
      currency: 'ZAR',
      description: 'Save R169/year',
      features: [
        'All Pro features',
        '2 months free',
        'Priority support',
        'Exclusive annual reports',
      ],
      buttonText: 'Go Annual',
      popular: false,
    ),
  };

  // Founding member offer (first month discount)
  static const int foundingMemberDiscount = 99; // R99 first month

  // ============================================
  // PAYMENT FLOW
  // ============================================

  Future<void> initiatePayment({
    required BuildContext context,
    required String userId,
    required String tierId,
    required VoidCallback onSuccess,
    required Function(String) onError,
    bool isAdmin = false,
  }) async {
    // Admin users get lifetime free access - skip payment
    if (isAdmin) {
      _showAdminAccessGranted(context);
      onSuccess();
      return;
    }

    try {
      // Create payment link via backend
      final paymentUrl = await _api.createPaymentLink(userId, tierId);

      if (paymentUrl == null) {
        onError('Failed to create payment link');
        return;
      }

      // Launch Yoco payment page
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Show payment pending dialog
        _showPaymentPending(context, onSuccess, onError);
      } else {
        onError('Could not open payment page');
      }
    } catch (e) {
      onError('Payment failed: ${e.toString()}');
    }
  }

  void _showAdminAccessGranted(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF13172F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.purple, width: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.purple,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ADMIN ACCESS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lifetime free access granted.\nThank you for building ISOTOPE.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentPending(
    BuildContext context,
    VoidCallback onSuccess,
    Function(String) onError,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF13172F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
            const SizedBox(height: 24),
            const Text(
              'Waiting for payment...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Complete your payment in the browser,\nthen return here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                // Verify payment
                Navigator.pop(context);
                // In production, poll backend for payment status
                await Future.delayed(const Duration(seconds: 2));
                onSuccess();
              },
              child: const Text('I\'ve Completed Payment'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // PRICING WIDGET
  // ============================================

  Widget buildPricingCard({
    required PricingTier tier,
    required BuildContext context,
    required String userId,
    required VoidCallback onUpgrade,
    required Function(String) onError,
  }) {
    return Card(
      elevation: tier.popular ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: tier.popular
            ? const BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: tier.popular
              ? const LinearGradient(
                  colors: [Color(0xFF13172F), Color(0xFF1A1F3A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Popular badge
            if (tier.popular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            if (tier.popular) const SizedBox(height: 12),

            // Tier name
            Text(
              tier.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              tier.description,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 16),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  'R',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.amber,
                  ),
                ),
                Text(
                  tier.price.toString(),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                Text(
                  '/${tier.id == 'annual' ? 'year' : 'mo'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Features
            ...tier.features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            )),

            const SizedBox(height: 20),

            // CTA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => initiatePayment(
                  context: context,
                  userId: userId,
                  tierId: tier.id,
                  onSuccess: onUpgrade,
                  onError: onError,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tier.popular ? Colors.amber : Colors.amber.withOpacity(0.2),
                  foregroundColor: tier.popular ? Colors.black : Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  tier.buttonText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: tier.popular ? Colors.black : Colors.amber,
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

// ============================================
// PRICING TIER MODEL
// ============================================

class PricingTier {
  final String id;
  final String name;
  final int price;
  final String currency;
  final String description;
  final List<String> features;
  final String buttonText;
  final bool popular;

  const PricingTier({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.description,
    required this.features,
    required this.buttonText,
    this.popular = false,
  });
}
