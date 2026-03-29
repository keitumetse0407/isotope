// ISOTOPE v3.0 — 24/7 Autonomous Trading Mode
// Let AI agents trade while you sleep
// Built by Keitumetse (Elkai) | ELEV8 DIGITAL

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Trading247Screen extends StatefulWidget {
  const Trading247Screen({Key? key}) : super(key: key);

  @override
  State<Trading247Screen> createState() => _Trading247ScreenState();
}

class _Trading247ScreenState extends State<Trading247Screen> {
  final String baseUrl = 'http://185.167.97.193:8100';
  bool _is24_7Enabled = false;
  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _myAllocations = [];
  double _todayPnL = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load agents
      final agentsResponse = await http.get(Uri.parse('$baseUrl/agents'));
      if (agentsResponse.statusCode == 200) {
        final data = jsonDecode(agentsResponse.body);
        setState(() {
          _agents = List<Map<String, dynamic>>.from(data);
        });
      }

      // Load 24/7 status
      final statusResponse = await http.get(Uri.parse('$baseUrl/user/user_001/247-status'));
      if (statusResponse.statusCode == 200) {
        final data = jsonDecode(statusResponse.body);
        setState(() {
          _is24_7Enabled = data['enabled'] ?? false;
          _todayPnL = data['today_pnl'] ?? 0.0;
        });
      }

      // Load my allocations
      final allocResponse = await http.get(Uri.parse('$baseUrl/copy-trades/user_001'));
      if (allocResponse.statusCode == 200) {
        final data = jsonDecode(allocResponse.body);
        setState(() {
          _myAllocations = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      print('Error loading data: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggle24_7() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/user_001/toggle-247?enable=${!_is24_7Enabled}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _is24_7Enabled = !_is24_7Enabled;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_is24_7Enabled 
                ? '🤖 24/7 Mode ENABLED - AI trading while you sleep!' 
                : '24/7 Mode disabled'),
            backgroundColor: _is24_7Enabled ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      print('Error toggling 24/7: $e');
    }
  }

  Future<void> _copyAgent(String agentId, String agentName, double minAllocation) async {
    double amount = minAllocation;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF13172F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Copy $agentName', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Allocation Amount (\$)', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => setState(() => amount = (amount - 100).clamp(minAllocation, 10000.0)),
                  icon: const Icon(Icons.remove, color: Colors.white),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$${amount.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => amount = (amount + 100).clamp(minAllocation, 10000.0)),
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Min: \$${minAllocation.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final response = await http.post(
                  Uri.parse('$baseUrl/agent/$agentId/copy?user_id=user_001&allocation_amount=$amount'),
                );
                if (response.statusCode == 200) {
                  final result = jsonDecode(response.body);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'] ?? 'Copied!'), backgroundColor: Colors.green),
                  );
                  _loadData();
                }
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('Start Copying', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13172F),
        title: const Text('24/7 AI Trading'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 24/7 Toggle Card
                  _build24_7ToggleCard(),
                  const SizedBox(height: 24),

                  // Today's P/L
                  _buildTodayPnLCard(),
                  const SizedBox(height: 24),

                  // My Active Allocations
                  if (_myAllocations.isNotEmpty) ...[
                    const Text('My Active Allocations', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._myAllocations.map((alloc) => _buildAllocationCard(alloc)),
                    const SizedBox(height: 24),
                  ],

                  // Available Agents
                  const Text('AI Agents Available', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ..._agents.map((agent) => _buildAgentCard(agent)),
                ],
              ),
            ),
    );
  }

  Widget _build24_7ToggleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _is24_7Enabled 
              ? [Colors.green.shade700, Colors.green.shade900]
              : [Colors.grey.shade700, Colors.grey.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _is24_7Enabled ? Icons.rocket : Icons.rocket_launch_outlined,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _is24_7Enabled ? '24/7 MODE ACTIVE' : '24/7 MODE OFF',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      _is24_7Enabled 
                          ? 'AI agents trading while you sleep' 
                          : 'Tap to enable autonomous trading',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _is24_7Enabled,
                onChanged: (_) => _toggle24_7(),
                activeColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPnLCard() {
    final isProfitable = _todayPnL >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13172F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isProfitable ? Colors.green : Colors.red),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Today\'s P/L', style: TextStyle(color: Colors.grey, fontSize: 14)),
              SizedBox(height: 4),
              Text('24/7 autonomous trading', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isProfitable ? '+' : ''}\$${_todayPnL.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isProfitable ? Colors.green : Colors.red,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isProfitable ? '🚀 To the moon!' : '💀 Rekt',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationCard(Map<String, dynamic> alloc) {
    final agent = _agents.firstWhere((a) => a['id'] == alloc['agent_id'], orElse: () => alloc);
    final pnl = alloc['pnl'] ?? 0.0;
    final isProfitable = pnl >= 0;

    return Card(
      color: const Color(0xFF13172F),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.amber,
          child: const Icon(Icons.smart_toy, color: Colors.black),
        ),
        title: Text(agent['name'] ?? 'Unknown Agent', style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          'Allocated: \$${alloc['allocation_amount']} | P/L: ${isProfitable ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
          style: TextStyle(color: isProfitable ? Colors.green : Colors.red),
        ),
        trailing: Text(
          '${alloc['allocation_percent']?.toStringAsFixed(1)}%',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildAgentCard(Map<String, dynamic> agent) {
    final isPremium = agent['is_premium'] ?? false;
    final strategy = (agent['strategy'] ?? '').toString().split('_').map((s) => s.capitalize()).join(' ');
    
    return Card(
      color: const Color(0xFF13172F),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _copyAgent(agent['id'], agent['name'], agent['min_allocation'] ?? 100.0),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isPremium ? Colors.purple : Colors.amber,
                    child: Icon(
                      agent['strategy'] == 'saitama_mode' ? Icons.bolt : Icons.smart_toy,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              agent['name'] ?? 'Unknown',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            if (isPremium) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('ELITE', style: TextStyle(color: Colors.white, fontSize: 10)),
                              ),
                            ],
                          ],
                        ),
                        Text(strategy, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+${agent['performance_30d']}%',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text('30d', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildAgentStat('${(agent['win_rate'] ?? 0) * 100}%', 'Win Rate'),
                  const SizedBox(width: 16),
                  _buildAgentStat('${agent['followers']}', 'Followers'),
                  const SizedBox(width: 16),
                  _buildAgentStat('${agent['management_fee'] ?? 0}%', 'Fee'),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => _copyAgent(agent['id'], agent['name'], agent['min_allocation'] ?? 100.0),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                    child: const Text('Copy', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgentStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return this[0].toUpperCase() + substring(1);
  }
}
