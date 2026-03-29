// ISOTOPE — Admin Dashboard Screen
// Exclusive for founders and admins — lifetime free access

import 'package:flutter/material.dart';
import '../models/admin_user.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'manage_admins_screen.dart';

class AdminDashboard extends StatefulWidget {
  final AdminUser admin;

  const AdminDashboard({Key? key, required this.admin}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  AdminStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      // In production, fetch from backend
      final stats = await _api.getAdminStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF13172F),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin badge
          _buildAdminBadge(),

          const SizedBox(height: 24),

          // Revenue stats
          _buildRevenueSection(),

          const SizedBox(height: 24),

          // User stats
          _buildUserSection(),

          const SizedBox(height: 24),

          // Signal stats
          _buildSignalSection(),

          const SizedBox(height: 24),

          // Automation status
          _buildAutomationSection(),

          const SizedBox(height: 32),

          // Admin actions
          _buildAdminActions(),
        ],
      ),
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.admin.isFounder
              ? [Colors.purple.withOpacity(0.3), Colors.purple.withOpacity(0.1)]
              : [Colors.amber.withOpacity(0.3), Colors.amber.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.admin.isFounder ? Colors.purple : Colors.amber,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.admin.isFounder ? Colors.purple : Colors.amber,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.black,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.admin.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIFETIME FREE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.admin.role.toUpperCase(),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSection() {
    return Card(
      color: const Color(0xFF13172F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'REVENUE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildRevenueCard('MRR', 'R7,500', Colors.green),
                const SizedBox(width: 12),
                _buildRevenueCard('Today', 'R450', Colors.amber),
                const SizedBox(width: 12),
                _buildRevenueCard('Total', 'R45,000', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    return Card(
      color: const Color(0xFF13172F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'USERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildUserStat('Total', '342'),
                const SizedBox(width: 12),
                _buildUserStat('Trial', '45'),
                const SizedBox(width: 12),
                _buildUserStat('Pro', '54'),
                const SizedBox(width: 12),
                _buildUserStat('Elite', '8'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalSection() {
    return Card(
      color: const Color(0xFF13172F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SIGNAL PERFORMANCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSignalStat('Win Rate', '58%', Colors.green),
                Container(width: 1, height: 40, color: Colors.grey[800]),
                _buildSignalStat('Today', '3/5', Colors.amber),
                Container(width: 1, height: 40, color: Colors.grey[800]),
                _buildSignalStat('Total', '127/218', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildAutomationSection() {
    return Card(
      color: const Color(0xFF13172F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AUTOMATION STATUS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildAutomationItem('n8n', true),
            const SizedBox(height: 8),
            _buildAutomationItem('WAHA (WhatsApp)', true),
            const SizedBox(height: 8),
            _buildAutomationItem('Telegram Bot', true),
            const SizedBox(height: 8),
            _buildAutomationItem('Signal Engine', true),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomationItem(String name, bool isRunning) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: const TextStyle(color: Colors.white),
        ),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isRunning ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isRunning ? 'Running' : 'Offline',
              style: TextStyle(
                color: isRunning ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminActions() {
    return Column(
      children: [
        // Manage Admins (Founder only)
        if (widget.admin.isFounder)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageAdminsScreen(currentAdmin: widget.admin),
                  ),
                );
              },
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('Manage Admins'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        
        const SizedBox(height: 12),
        
        // View all users
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // View all users
            },
            icon: const Icon(Icons.people),
            label: const Text('Manage Users'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // View revenue details
            },
            icon: const Icon(Icons.attach_money),
            label: const Text('Revenue Details'),
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
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // View signal logs
            },
            icon: const Icon(Icons.analytics),
            label: const Text('Signal Analytics'),
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
      ],
    );
  }
}

// ============================================
// ADMIN STATS MODEL
// ============================================

class AdminStats {
  final int totalUsers;
  final int trialUsers;
  final int proUsers;
  final int eliteUsers;
  final double mrr;
  final double todayRevenue;
  final double totalRevenue;
  final int totalSignals;
  final int wins;
  final int losses;
  final Map<String, bool> automationStatus;

  AdminStats({
    required this.totalUsers,
    required this.trialUsers,
    required this.proUsers,
    required this.eliteUsers,
    required this.mrr,
    required this.todayRevenue,
    required this.totalRevenue,
    required this.totalSignals,
    required this.wins,
    required this.losses,
    required this.automationStatus,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['totalUsers'] ?? 0,
      trialUsers: json['trialUsers'] ?? 0,
      proUsers: json['proUsers'] ?? 0,
      eliteUsers: json['eliteUsers'] ?? 0,
      mrr: (json['mrr'] ?? 0).toDouble(),
      todayRevenue: (json['todayRevenue'] ?? 0).toDouble(),
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      totalSignals: json['totalSignals'] ?? 0,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      automationStatus: Map<String, bool>.from(json['automationStatus'] ?? {}),
    );
  }
}
