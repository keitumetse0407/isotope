// ISOTOPE v3.0 — Saitama Easter Egg Screen
// ONE PUNCH MAN MODE
// Built by Keitumetse (Elkai) | ELEV8 DIGITAL

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SaitamaScreen extends StatefulWidget {
  final bool isUnlocked;
  
  const SaitamaScreen({Key? key, this.isUnlocked = false}) : super(key: key);

  @override
  State<SaitamaScreen> createState() => _SaitamaScreenState();
}

class _SaitamaScreenState extends State<SaitamaScreen> with SingleTickerProviderStateMixin {
  final String baseUrl = 'http://185.167.97.193:8100';
  bool _isUnlocked = false;
  final _codeController = TextEditingController();
  List<Map<String, dynamic>> _saitamaSignals = [];
  int _punchCount = 0;
  late AnimationController _animationController;
  late Animation<double> _punchAnimation;

  @override
  void initState() {
    super.initState();
    _isUnlocked = widget.isUnlocked;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _punchAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _unlockSaitama() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/saitama/unlock/user_001?secret_code=${_codeController.text}'),
      );
      final result = jsonDecode(response.body);
      
      if (result['success'] == true) {
        setState(() {
          _isUnlocked = true;
          _punchCount = 1;
        });
        _animationController.forward().then((_) => _animationController.reverse());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('👊 ONE PUNCH MAN UNLOCKED!'),
            backgroundColor: Colors.amber,
            duration: Duration(seconds: 3),
          ),
        );
        _loadSignals();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Wrong code')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _loadSignals() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/saitama/signals'));
      if (response.statusCode == 200) {
        setState(() {
          _saitamaSignals = jsonDecode(response.body) as List<Map<String, dynamic>>;
        });
      }
    } catch (e) {
      print('Error loading signals: $e');
    }
  }

  void _doPunch() {
    setState(() {
      _punchCount++;
    });
    _animationController.forward().then((_) => _animationController.reverse());
    
    if (_punchCount >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🏆 SERIOUS SERIES COMPLETE! You\'re a true hero!'),
          backgroundColor: Colors.amber,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return _buildLockScreen();
    }
    return _buildUnlockedScreen();
  }

  Widget _buildLockScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13172F),
        title: const Text('👊 Secret Mode'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(height: 32),
            const Text(
              'ONE PUNCH MAN MODE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter the secret code to unlock the most powerful AI agent. Only for those who train hard enough.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter secret code...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF13172F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _unlockSaitama,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'UNLOCK',
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hint: What does Saitama do?',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('👊 ONE PUNCH MAN', style: TextStyle(color: Colors.black)),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'Punches: $_punchCount',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Saitama Avatar
            ScaleTransition(
              scale: _punchAnimation,
              child: GestureDetector(
                onTap: _doPunch,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.amber.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt,
                    size: 80,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Punch Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _doPunch,
                icon: const Icon(Icons.bolt, color: Colors.black),
                label: const Text(
                  'ONE PUNCH',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap for power! 10 punches = achievement!',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Achievement Progress
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF13172F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _punchCount >= 10 ? Colors.amber : Colors.grey.shade800),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _punchCount >= 10 ? Icons.emoji_events : Icons.emoji_events_outlined,
                        color: _punchCount >= 10 ? Colors.amber : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SERIES: ONE PUNCH',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$_punchCount/10 punches',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _punchCount / 10,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                      minHeight: 8,
                    ),
                  ),
                  if (_punchCount >= 10) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.celebration, color: Colors.amber),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '🏆 ACHIEVEMENT UNLOCKED: You\'re a true hero!',
                              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Saitama Signals
            const Text(
              '👊 ONE PUNCH SIGNALS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_saitamaSignals.isEmpty) ...[
              const Text(
                'No ONE PUNCH signals yet...',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'These only appear at 100% confidence. Extremely rare.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              ..._saitamaSignals.map((signal) => _buildSaitamaSignalCard(signal)),
            ],

            const SizedBox(height: 32),
            
            // Features List
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF13172F),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'UNLOCKED FEATURES',
                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem('👊 ONE PUNCH MAN AI Agent', '100% confidence trades only'),
                  _buildFeatureItem('🎨 Bald Mode Theme', 'Coming soon'),
                  _buildFeatureItem('🏆 Serious Series', 'Achievement tracking'),
                  _buildFeatureItem('⚡ Secret Signals', 'Ultra-rare, high conviction'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text.split('\n').first, style: const TextStyle(color: Colors.white)),
                if (text.contains('\n'))
                  Text(text.split('\n').last, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaitamaSignalCard(Map<String, dynamic> signal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade700, Colors.red.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ONE PUNCH SIGNAL',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '100%',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSignalStat(signal['direction'], 'Direction'),
              _buildSignalStat('\$${signal['entry']}', 'Entry'),
              _buildSignalStat('\$${signal['takeProfit1']}', 'TP1'),
              _buildSignalStat('\$${signal['takeProfit2']}', 'TP2'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            signal['rationale'] ?? 'ONE PUNCH = ONE TRADE',
            style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSignalStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}
