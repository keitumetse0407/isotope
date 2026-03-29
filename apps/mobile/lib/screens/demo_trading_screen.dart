// ISOTOPE — Demo Trading Screen
// Paper trading mode — No real money, track virtual performance

import 'package:flutter/material.dart';
import '../models/signal.dart';
import '../services/api_service.dart';

class DemoTradingScreen extends StatefulWidget {
  const DemoTradingScreen({Key? key}) : super(key: key);

  @override
  State<DemoTradingScreen> createState() => _DemoTradingScreenState();
}

class _DemoTradingScreenState extends State<DemoTradingScreen> {
  final ApiService _api = ApiService();
  
  // Demo account state
  double _demoBalance = 10000.0; // Start with $10,000 virtual
  List<DemoTrade> _trades = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDemoTrades();
  }

  Future<void> _loadDemoTrades() async {
    setState(() => _isLoading = true);
    // In production: Load from Firebase/SQLite
    setState(() => _isLoading = false);
  }

  Future<void> _executeDemoTrade(Signal signal, double lotSize) async {
    final trade = DemoTrade(
      signal: signal,
      lotSize: lotSize,
      entryPrice: signal.entry,
      entryTime: DateTime.now(),
      status: 'open',
    );

    setState(() {
      _trades.insert(0, trade);
    });

    // Save to local storage (in production: Firebase)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demo ${signal.direction} executed: ${signal.entry}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _closeDemoTrade(DemoTrade trade, double exitPrice) async {
    final profit = _calculateProfit(trade, exitPrice);
    
    setState(() {
      _demoBalance += profit;
      trade.status = 'closed';
      trade.exitPrice = exitPrice;
      trade.exitTime = DateTime.now();
      trade.profit = profit;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Trade closed: ${profit >= 0 ? '+' : ''}\$${profit.toStringAsFixed(2)}'),
        backgroundColor: profit >= 0 ? Colors.green : Colors.red,
      ),
    );
  }

  double _calculateProfit(DemoTrade trade, double exitPrice) {
    final priceDiff = exitPrice - trade.entryPrice;
    final pipValue = 10.0; // Standard for gold
    final pips = (priceDiff / 0.01);
    return pips * pipValue * trade.lotSize * (trade.signal.direction == 'BUY' ? 1 : -1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text('Demo Trading'),
        backgroundColor: const Color(0xFF13172F),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDemoTrades,
          ),
        ],
      ),
      body: Column(
        children: [
          // Demo Balance Card
          _buildBalanceCard(),
          
          // Active Signal
          _buildActiveSignalSection(),
          
          // Open Trades
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _trades.isEmpty
                    ? _buildEmptyState()
                    : _buildTradesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade700, Colors.amber.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'DEMO BALANCE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_demoBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '📝 Paper Trading — No Real Money',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSignalSection() {
    return FutureBuilder<Signal?>(
      future: _api.getLatestSignal(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final signal = snapshot.data!;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF13172F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: signal.direction == 'BUY' ? Colors.green : Colors.red,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: signal.direction == 'BUY' ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      signal.direction,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'XAU/USD',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${(signal.confidence * 100).toStringAsFixed(0)}% Confidence',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem('Entry', '\$${signal.entry}'),
                  ),
                  Expanded(
                    child: _buildStatItem('Stop Loss', '\$${signal.stopLoss}'),
                  ),
                  Expanded(
                    child: _buildStatItem('TP1', '\$${signal.takeProfit1}'),
                  ),
                  Expanded(
                    child: _buildStatItem('TP2', '\$${signal.takeProfit2}'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showTradeDialog(signal, 'BUY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('BUY', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showTradeDialog(signal, 'SELL'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('SELL', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          Text(
            'No trades yet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Execute a demo trade to start tracking',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildTradesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trades.length,
      itemBuilder: (context, index) {
        final trade = _trades[index];
        return _buildTradeCard(trade);
      },
    );
  }

  Widget _buildTradeCard(DemoTrade trade) {
    final profit = trade.profit ?? 0.0;
    final isProfitable = profit >= 0;
    
    return Card(
      color: const Color(0xFF13172F),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: trade.signal.direction == 'BUY' ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            trade.signal.direction[0],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          'XAU/USD — ${trade.signal.direction}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entry: \$${trade.entryPrice} | Lot: ${trade.lotSize}', style: const TextStyle(color: Colors.grey)),
            if (trade.status == 'closed')
              Text(
                'P/L: ${isProfitable ? '+' : ''}\$${trade.profit?.toStringAsFixed(2)}',
                style: TextStyle(color: isProfitable ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: trade.status == 'open'
            ? ElevatedButton(
                onPressed: () => _showCloseTradeDialog(trade),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: const Text('Close', style: TextStyle(color: Colors.black)),
              )
            : Icon(isProfitable ? Icons.check_circle : Icons.cancel, color: isProfitable ? Colors.green : Colors.red),
      ),
    );
  }

  void _showTradeDialog(Signal signal, String direction) {
    double lotSize = 0.01;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF13172F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Execute Demo Trade', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Direction: $direction', style: const TextStyle(color: Colors.white)),
            Text('Entry: \$${signal.entry}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            const Text('Lot Size', style: TextStyle(color: Colors.white)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: () => setState(() => lotSize = 0.01), icon: const Icon(Icons.remove)),
                Text(lotSize.toString(), style: const TextStyle(color: Colors.white, fontSize: 18)),
                IconButton(onPressed: () => setState(() => lotSize = 0.1), icon: const Icon(Icons.add)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _executeDemoTrade(signal, lotSize);
              Navigator.pop(context);
            },
            child: const Text('Execute'),
          ),
        ],
      ),
    );
  }

  void _showCloseTradeDialog(DemoTrade trade) {
    final controller = TextEditingController(text: trade.exitPrice.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF13172F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Close Trade', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Entry: \$${trade.entryPrice}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Exit Price',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final exitPrice = double.tryParse(controller.text) ?? trade.entryPrice;
              _closeDemoTrade(trade, exitPrice);
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class DemoTrade {
  final Signal signal;
  final double lotSize;
  final double entryPrice;
  final DateTime entryTime;
  String status;
  double? exitPrice;
  DateTime? exitTime;
  double? profit;

  DemoTrade({
    required this.signal,
    required this.lotSize,
    required this.entryPrice,
    required this.entryTime,
    this.status = 'open',
    this.exitPrice,
    this.exitTime,
    this.profit,
  });
}
