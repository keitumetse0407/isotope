// ISOTOPE — Signal Detail Screen
// Full signal information with copy/disclaimer

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/signal.dart';
import '../models/user.dart';

class SignalDetailScreen extends StatelessWidget {
  final Signal signal;
  final User? user;

  const SignalDetailScreen({
    Key? key,
    required this.signal,
    this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: Text(signal.instrument),
        backgroundColor: const Color(0xFF13172F),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareSignal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Direction badge
            _buildDirectionBadge(),

            const SizedBox(height: 24),

            // Key levels card
            _buildLevelsCard(),

            const SizedBox(height: 16),

            // Risk/Reward card
            _buildRiskRewardCard(),

            const SizedBox(height: 16),

            // Rationale card
            _buildRationaleCard(),

            const SizedBox(height: 16),

            // Disclaimer
            _buildDisclaimer(),

            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionBadge() {
    final isBuy = signal.direction == 'BUY';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isBuy ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBuy ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            signal.direction,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isBuy ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            signal.instrument,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelsCard() {
    return Card(
      color: const Color(0xFF13172F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KEY LEVELS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildLevelRow('Entry', signal.formattedEntry, Colors.white),
            const SizedBox(height: 12),
            _buildLevelRow('Stop Loss', signal.formattedSL, Colors.red),
            const SizedBox(height: 12),
            _buildLevelRow('TP 1', signal.formattedTP1, Colors.green),
            const SizedBox(height: 12),
            _buildLevelRow('TP 2', signal.formattedTP2, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRiskRewardCard() {
    return Card(
      color: const Color(0xFF13172F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn('Confidence', signal.formattedConfidence),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[800],
            ),
            _buildStatColumn('R:R', '1:${signal.riskReward.toStringAsFixed(1)}'),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[800],
            ),
            _buildStatColumn('Time', _formatTime(signal.timestamp)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildRationaleCard() {
    return Card(
      color: const Color(0xFF13172F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WHY THIS SIGNAL',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              signal.rationale,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'DISCLAIMER',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Educational only. Not financial advice. Past performance ≠ future results. Trade at own risk. We are NOT FSCA licensed.',
            style: TextStyle(fontSize: 12, color: const Color(0xFFE69500)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _copySignal(context),
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amber,
              side: const BorderSide(color: Colors.amber),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _shareSignal(context),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _copySignal(BuildContext context) {
    final text = '''
${signal.direction} ${signal.instrument}
Entry: ${signal.formattedEntry}
SL: ${signal.formattedSL}
TP1: ${signal.formattedTP1}
TP2: ${signal.formattedTP2}
Confidence: ${signal.formattedConfidence}
''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signal copied to clipboard')),
    );
  }

  void _shareSignal(BuildContext context) {
    // In production: use share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon')),
    );
  }
}
