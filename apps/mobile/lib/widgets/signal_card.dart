// ISOTOPE — Signal Card Widget
// Displays individual signal in list view

import 'package:flutter/material.dart';
import '../models/signal.dart';

class SignalCard extends StatelessWidget {
  final Signal signal;
  final VoidCallback onTap;

  const SignalCard({
    Key? key,
    required this.signal,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isBuy = signal.direction == 'BUY';
    final isClosed = signal.status == 'CLOSED_WIN' || signal.status == 'CLOSED_LOSS';
    final isWin = signal.status == 'CLOSED_WIN';

    return Card(
      color: const Color(0xFF13172F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Instrument + Direction
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isBuy ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isBuy ? Colors.green : Colors.red,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          signal.direction,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isBuy ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        signal.instrument,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusBadge(),
                ],
              ),

              const SizedBox(height: 16),

              // Key levels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLevelColumn('Entry', signal.formattedEntry, Colors.white),
                  _buildDivider(),
                  _buildLevelColumn('SL', signal.formattedSL, Colors.red),
                  _buildDivider(),
                  _buildLevelColumn('TP1', signal.formattedTP1, Colors.green),
                  _buildDivider(),
                  _buildLevelColumn('TP2', signal.formattedTP2, Colors.green),
                ],
              ),

              const SizedBox(height: 16),

              // Confidence + R:R
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildConfidenceBadge(),
                  Text(
                    'R:R 1:${signal.riskReward.toStringAsFixed(1)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    _formatTime(signal.timestamp),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),

              // Outcome if closed
              if (isClosed) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isWin ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isWin ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isWin ? Icons.trending_up : Icons.trending_down,
                        color: isWin ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        signal.outcome != null
                            ? '${isWin ? '+' : ''}R${signal.outcome!.toStringAsFixed(2)}'
                            : '-1R',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isWin ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    IconData icon;
    Color color;
    String label;

    switch (signal.status) {
      case 'ACTIVE':
        icon = Icons.play_circle;
        color = Colors.green;
        label = 'Active';
        break;
      case 'CLOSED_WIN':
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'Won';
        break;
      case 'CLOSED_LOSS':
        icon = Icons.cancel;
        color = Colors.red;
        label = 'Lost';
        break;
      default:
        icon = Icons.schedule;
        color = Colors.grey;
        label = 'Pending';
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildLevelColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.grey[800],
    );
  }

  Widget _buildConfidenceBadge() {
    final confidence = signal.confidence * 100;
    Color color;

    if (confidence >= 70) {
      color = Colors.green;
    } else if (confidence >= 50) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            '${confidence.toInt()}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
