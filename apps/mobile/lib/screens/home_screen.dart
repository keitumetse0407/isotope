// ISOTOPE — Home Screen
// Main dashboard with active signals, portfolio summary, quick actions

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/signal.dart';
import '../services/api_service.dart';
import '../widgets/signal_card.dart';
import 'signals_screen.dart';
import 'portfolio_screen.dart';
import 'profile_screen.dart';
import 'upgrade_screen.dart';

class HomeScreen extends StatefulWidget {
  final User? user;

  const HomeScreen({Key? key, this.user}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  int _currentIndex = 0;
  List<Signal> _recentSignals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentSignals();
  }

  Future<void> _loadRecentSignals() async {
    setState(() => _isLoading = true);

    try {
      final signals = await _api.getSignals();
      setState(() {
        _recentSignals = signals.take(5).toList();
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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          SignalsScreen(user: widget.user),
          PortfolioScreen(user: widget.user),
          ProfileScreen(
            user: widget.user!,
            onLogout: _handleLogout,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          floating: true,
          backgroundColor: const Color(0xFF13172F),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ISOTOPE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  letterSpacing: 2,
                ),
              ),
              Text(
                widget.user?.name ?? 'Trader',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                // Show notifications
              },
            ),
          ],
        ),

        // Welcome card
        SliverToBoxAdapter(
          child: _buildWelcomeCard(),
        ),

        // Quick stats
        SliverToBoxAdapter(
          child: _buildQuickStats(),
        ),

        // Recent signals header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENT SIGNALS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _currentIndex = 1);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
        ),

        // Signals list
        _isLoading
            ? const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            : _recentSignals.isEmpty
                ? SliverToBoxAdapter(
                    child: _buildNoSignalsState(),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final signal = _recentSignals[index];
                          return SignalCard(
                            signal: signal,
                            onTap: () {
                              // Navigate to signal detail
                            },
                          );
                        },
                        childCount: _recentSignals.length,
                      ),
                    ),
                  ),

        // Bottom padding for nav
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    final hasSubscription = widget.user?.hasActiveSubscription ?? false;
    final isTrial = widget.user?.isTrial ?? false;
    final daysLeft = widget.user?.daysUntilTrialEnd ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasSubscription
              ? [Colors.amber.withOpacity(0.3), Colors.amber.withOpacity(0.1)]
              : [Colors.grey[800]!, Colors.grey[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSubscription ? Colors.amber : Colors.grey[700]!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasSubscription ? Icons.check_circle : Icons.error,
                color: hasSubscription ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasSubscription
                      ? isTrial
                          ? 'Trial Active'
                          : 'Pro Member'
                      : 'Free Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hasSubscription ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasSubscription
                ? isTrial && daysLeft > 0
                    ? '$daysLeft days remaining - Upgrade to keep access'
                    : 'Full access unlocked'
                : '2 signals/day • Delayed by 1 hour',
            style: const TextStyle(color: Colors.white70),
          ),
          if (!hasSubscription || isTrial) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpgradeScreen(userId: widget.user?.id ?? ''),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  hasSubscription ? 'UPGRADE' : 'START FREE TRIAL',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Signals Today',
              _recentSignals.length.toString(),
              Icons.signal_cellular_alt,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Win Rate',
              widget.user != null ? '58%' : '--',
              Icons.show_chart,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Streak',
              '+3',
              Icons.local_fire_department,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      color: const Color(0xFF13172F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Colors.amber, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSignalsState() {
    return Container(
      margin: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.signal_cellular_off,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No signals yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Signals appear at 6AM, 12PM, 4PM SAST',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13172F),
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Signals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    // Handle logout logic
    Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (route) => false);
  }
}
