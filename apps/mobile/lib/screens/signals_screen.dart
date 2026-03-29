// ISOTOPE — Signals Screen
// Displays all trading signals with free/premium indicators

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/signal.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/signal_card.dart';
import '../widgets/paywall_trigger.dart';
import 'signal_detail_screen.dart';

class SignalsScreen extends StatefulWidget {
  final User? user;

  const SignalsScreen({Key? key, this.user}) : super(key: key);

  @override
  State<SignalsScreen> createState() => _SignalsScreenState();
}

class _SignalsScreenState extends State<SignalsScreen> {
  final ApiService _api = ApiService();
  List<Signal> _signals = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, active, closed

  @override
  void initState() {
    super.initState();
    _loadSignals();
  }

  Future<void> _loadSignals() async {
    setState(() => _isLoading = true);

    try {
      final signals = await _api.getSignals();
      setState(() {
        _signals = signals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load signals: $e')),
        );
      }
    }
  }

  List<Signal> get _filteredSignals {
    switch (_filter) {
      case 'active':
        return _signals.where((s) => s.status == 'ACTIVE' || s.status == 'PENDING').toList();
      case 'closed':
        return _signals.where((s) => s.status == 'CLOSED_WIN' || s.status == 'CLOSED_LOSS').toList();
      default:
        return _signals;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text('Signals'),
        backgroundColor: const Color(0xFF13172F),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSignals,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterBar(),

          // Signals list or loading
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSignals.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredSignals.length,
                        itemBuilder: (context, index) {
                          final signal = _filteredSignals[index];
                          
                          // Check if this is a free signal or premium
                          final isFreeSignal = signal.confidence < 0.7 || 
                                              widget.user?.hasActiveSubscription == true;

                          return PaywallTrigger(
                            isLocked: !isFreeSignal,
                            user: widget.user,
                            child: SignalCard(
                              signal: signal,
                              onTap: () => _openSignalDetail(signal),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF13172F),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Active', 'active'),
          const SizedBox(width: 8),
          _buildFilterChip('Closed', 'closed'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filter = value);
      },
      backgroundColor: const Color(0xFF0A0E21),
      selectedColor: Colors.amber.withOpacity(0.3),
      checkmarkColor: Colors.amber,
      labelStyle: TextStyle(
        color: isSelected ? Colors.amber : Colors.white70,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }

  void _openSignalDetail(Signal signal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignalDetailScreen(
          signal: signal,
          user: widget.user,
        ),
      ),
    );
  }
}
