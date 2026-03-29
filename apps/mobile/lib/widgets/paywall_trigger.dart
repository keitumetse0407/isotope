// ISOTOPE — Paywall Trigger Widget
// Wraps premium content and shows upgrade prompt when locked

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/payment_service.dart';

class PaywallTrigger extends StatelessWidget {
  final Widget child;
  final bool isLocked;
  final User? user;

  const PaywallTrigger({
    Key? key,
    required this.child,
    this.isLocked = false,
    this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isLocked) {
      return child;
    }

    return Stack(
      children: [
        // Blurred content
        ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(1),
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: Opacity(
            opacity: 0.3,
            child: IgnorePointer(child: child),
          ),
        ),

        // Lock overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: () => _showPaywall(context),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0A0E21).withOpacity(0.8),
                    const Color(0xFF0A0E21),
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),
                  
                  // Lock icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Title
                  const Text(
                    'PRO SIGNAL',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  const Text(
                    'Upgrade to unlock',
                    style: TextStyle(color: Colors.grey),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // CTA Button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: ElevatedButton(
                      onPressed: () => _showPaywall(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'UPGRADE TO PRO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPaywall(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaywallSheet(user: user),
    );
  }
}

// ============================================
// PAYWALL BOTTOM SHEET
// ============================================

class _PaywallSheet extends StatelessWidget {
  final User? user;

  const _PaywallSheet({Key? key, this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final paymentService = PaymentService();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF13172F),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'UNLOCK FULL ACCESS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.isTrial ?? true
                      ? 'Start your 7-day free trial'
                      : 'Choose your plan',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // Pricing cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                paymentService.buildPricingCard(
                  tier: PaymentService.tiers['trial']!,
                  context: context,
                  userId: user?.id ?? '',
                  onUpgrade: () {
                    Navigator.pop(context);
                    // Handle success
                  },
                  onError: (error) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                  },
                ),
                const SizedBox(height: 12),
                paymentService.buildPricingCard(
                  tier: PaymentService.tiers['pro']!,
                  context: context,
                  userId: user?.id ?? '',
                  onUpgrade: () {
                    Navigator.pop(context);
                    // Handle success
                  },
                  onError: (error) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Trust indicators
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Secure Payment by Yoco',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'South Africa\'s trusted payment gateway',
                        style: const TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Footer disclaimer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Cancel anytime. No questions asked.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),

          // Safe area for bottom
          SafeArea(
            child: Container(height: 8),
          ),
        ],
      ),
    );
  }
}
