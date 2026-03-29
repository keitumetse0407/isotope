// ISOTOPE v3.0 — Kalshi-Style Prediction Market Screen
// Trade YES/NO contracts on real-world events
// Built by Keitumetse (Elkai) | ELEV8 DIGITAL

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PredictionMarketScreen extends StatefulWidget {
  const PredictionMarketScreen({Key? key}) : super(key: key);

  @override
  State<PredictionMarketScreen> createState() => _PredictionMarketScreenState();
}

class _PredictionMarketScreenState extends State<PredictionMarketScreen> {
  final String baseUrl = 'http://185.167.97.193:8100';
  List<Map<String, dynamic>> _markets = [];
  bool _isLoading = false;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadMarkets();
  }

  Future<void> _loadMarkets() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/markets'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _markets = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading markets: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _tradeContract(String marketId, String contractType, int quantity) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/market/$marketId/trade?contract_type=$contractType&quantity=$quantity&user_id=user_001'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Trade executed!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadMarkets();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trade failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTradeDialog(Map<String, dynamic> market) {
    int quantity = 10;
    String selectedType = 'YES';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF13172F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            market['question'],
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Contract type selector
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => selectedType = 'YES'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selectedType == 'YES' ? Colors.green : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text('YES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('${market['yes_ask']}¢', style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => selectedType = 'NO'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selectedType == 'NO' ? Colors.red : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text('NO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('${market['no_ask']}¢', style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Quantity selector
              const Text('Quantity', style: TextStyle(color: Colors.white)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => setDialogState(() => quantity = (quantity - 10).clamp(10, 1000)),
                    icon: const Icon(Icons.remove, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setDialogState(() => quantity = (quantity + 10).clamp(10, 1000)),
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Cost display
              Text(
                'Cost: \$${(quantity * (selectedType == 'YES' ? market['yes_ask'] : market['no_ask']) / 100).toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Potential Win: \$${quantity}.00',
                style: TextStyle(color: Colors.green.shade400, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                _tradeContract(market['id'], selectedType, quantity);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedType == 'YES' ? Colors.green : Colors.red,
              ),
              child: Text('Buy $selectedType', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13172F),
        title: const Text('Prediction Market'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMarkets,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade700, Colors.amber.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'KALSHI-STYLE PREDICTIONS',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Trade YES/NO contracts. Win \$1 per contract if correct. Platform takes 2% fee.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatChip('\$10K', 'Demo Balance'),
                    const SizedBox(width: 8),
                    _buildStatChip('2%', 'Fee'),
                    const SizedBox(width: 8),
                    _buildStatChip('Anytime', 'Exit'),
                  ],
                ),
              ],
            ),
          ),
          
          // Category Filter
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('All', 'all'),
                _buildCategoryChip('🏆 Gold', 'gold'),
                _buildCategoryChip('💱 Forex', 'forex'),
                _buildCategoryChip('₿ Crypto', 'crypto'),
                _buildCategoryChip('📰 Events', 'events'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Markets List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _markets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.poll, size: 64, color: Colors.grey.shade700),
                            const SizedBox(height: 16),
                            Text(
                              'No active markets',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _markets.length,
                        itemBuilder: (context, index) {
                          final market = _markets[index];
                          return _buildMarketCard(market);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : const Color(0xFF13172F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.amber : Colors.grey.shade800),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMarketCard(Map<String, dynamic> market) {
    final closesAt = DateTime.parse(market['closes_at']);
    final timeLeft = closesAt.difference(DateTime.now());
    
    return Card(
      color: const Color(0xFF13172F),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showTradeDialog(market),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question
              Text(
                market['question'],
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              // Category & Volume
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      market['category'].toUpperCase(),
                      style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Vol: ${market['volume']}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    timeLeft.inDays > 0 ? '${timeLeft.inDays}d left' : '${timeLeft.inHours}h left',
                    style: TextStyle(color: timeLeft.inDays < 2 ? Colors.red : Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Price Bars
              Row(
                children: [
                  Expanded(
                    child: _buildPriceBar(
                      label: 'YES',
                      price: market['yes_bid'],
                      isYes: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPriceBar(
                      label: 'NO',
                      price: market['no_bid'],
                      isYes: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Last Price Indicator
              Row(
                children: [
                  const Text('Last: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: market['last_price'] > 50 ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${market['last_price']}¢',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '= ${(market['last_price'] / 100 * 100 - 100).toStringAsFixed(0)}% implied prob',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceBar({required String label, required num price, required bool isYes}) {
    final percent = price / 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: isYes ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            Text('$price¢', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey.shade800,
            valueColor: AlwaysStoppedAnimation<Color>(isYes ? Colors.green : Colors.red),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
