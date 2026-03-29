// ISOTOPE — Upgrade Screen
// Paywall with pricing tiers (Yoco integration)

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/payment_service.dart';

class UpgradeScreen extends StatelessWidget {
  final String userId;

  const UpgradeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final paymentService = PaymentService();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text('Upgrade'),
        backgroundColor: const Color(0xFF13172F),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'CHOOSE YOUR PLAN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Invest in your trading edge',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 32),

            // Trial tier (free)
            paymentService.buildPricingCard(
              tier: PaymentService.tiers['trial']!,
              context: context,
              userId: userId,
              onUpgrade: () {
                _showSuccess(context, 'Trial activated!');
              },
              onError: _showError,
            ),

            const SizedBox(height: 16),

            // Pro tier
            paymentService.buildPricingCard(
              tier: PaymentService.tiers['pro']!,
              context: context,
              userId: userId,
              onUpgrade: () {
                _showSuccess(context, 'Welcome to Pro!');
              },
              onError: _showError,
            ),

            const SizedBox(height: 16),

            // Elite tier
            paymentService.buildPricingCard(
              tier: PaymentService.tiers['elite']!,
              context: context,
              userId: userId,
              onUpgrade: () {
                _showSuccess(context, 'Welcome to Elite!');
              },
              onError: _showError,
            ),

            const SizedBox(height: 16),

            // Annual tier
            paymentService.buildPricingCard(
              tier: PaymentService.tiers['annual']!,
              context: context,
              userId: userId,
              onUpgrade: () {
                _showSuccess(context, 'Annual plan activated!');
              },
              onError: _showError,
            ),

            const SizedBox(height: 32),

            // Trust indicators
            _buildTrustSection(),

            const SizedBox(height: 24),

            // FAQ
            _buildFAQ(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13172F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildTrustRow(
            Icons.security,
            'Secure Payments',
            'Powered by Yoco (SA)',
          ),
          const SizedBox(height: 12),
          _buildTrustRow(
            Icons.cancel,
            'Cancel Anytime',
            'No questions asked',
          ),
          const SizedBox(height: 12),
          _buildTrustRow(
            Icons.support,
            '24/7 Support',
            'Direct founder access',
          ),
        ],
      ),
    );
  }

  Widget _buildTrustRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFAQ() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FREQUENTLY ASKED QUESTIONS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        _buildFAQItem(
          'Can I cancel anytime?',
          'Yes! Cancel anytime from your profile. No questions asked.',
        ),
        _buildFAQItem(
          'When do signals arrive?',
          'Signals are generated at 6AM, 12PM, and 4PM SAST when high-confidence setups are detected.',
        ),
        _buildFAQItem(
          'What if signals lose?',
          'Not all signals win. Our target is 55-65% win rate. Always use proper risk management.',
        ),
        _buildFAQItem(
          'Is this FSCA regulated?',
          'No. ISOTOPE provides educational information only, not financial advice.',
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String error) {
    // Show error dialog
  }
}
