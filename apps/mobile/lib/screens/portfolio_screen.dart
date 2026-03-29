// ISOTOPE — Portfolio Screen
// Track trading performance with charts and stats

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/portfolio.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class PortfolioScreen extends StatefulWidget {
  final User? user;

  const PortfolioScreen({Key? key, this.user}) : super(key: key);

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final ApiService _api = ApiService();
  Portfolio? _portfolio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    if (widget.user == null) return;

    setState(() => _isLoading = true);

    try {
      final portfolio = await _api.getPortfolio(widget.user!.id);
      setState(() {
        _portfolio = portfolio;
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
        title: const Text('Portfolio'),
        backgroundColor: const Color(0xFF13172F),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPortfolio,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _portfolio == null
              ? _buildEmptyState()
              : _buildPortfolioContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No trades yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your closed trades will appear here',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Win rate card
          _buildWinRateCard(),

          const SizedBox(height: 16),

          // Stats grid
          _buildStatsGrid(),

          const SizedBox(height: 24),

          // Performance chart
          _buildPerformanceChart(),

          const SizedBox(height: 24),

          // Trade history
          _buildTradeHistory(),
        ],
      ),
    );
  }

  Widget _buildWinRateCard() {
    final winRate = _portfolio!.winRate * 100;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            winRate >= 60 ? Colors.green : winRate >= 40 ? Colors.orange : Colors.red,
            Colors.transparent,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: winRate >= 60 ? Colors.green : winRate >= 40 ? Colors.orange : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'WIN RATE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${winRate.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: winRate >= 60 ? Colors.green : winRate >= 40 ? Colors.orange : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_portfolio!.wins}W / ${_portfolio!.losses}L',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Signals',
          _portfolio!.totalSignals.toString(),
          Icons.signal_cellular_alt,
        ),
        _buildStatCard(
          'Total Profit',
          _portfolio!.formattedProfit,
          Icons.attach_money,
        ),
        _buildStatCard(
          'Avg Win',
          _portfolio!.wins > 0 
              ? 'R${(_portfolio!.totalProfit / _portfolio!.wins).toStringAsFixed(0)}'
              : 'R0',
          Icons.trending_up,
        ),
        _buildStatCard(
          'Streak',
          '${_portfolio!.wins > _portfolio!.losses ? '+' : ''}${_portfolio!.wins - _portfolio!.losses}',
          Icons.local_fire_department,
        ),
      ],
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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.amber, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
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
              'PERFORMANCE TREND',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _portfolio!.signalHistory.isEmpty
                  ? Center(
                      child: Text(
                        'No data yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _portfolio!.signalHistory
                                .asMap()
                                .entries
                                .map((e) => FlSpot(
                                      e.key.toDouble(),
                                      e.value.profitLoss,
                                    ))
                                .toList(),
                            isCurved: true,
                            color: Colors.amber,
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.amber.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TRADE HISTORY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ..._portfolio!.signalHistory.map((trade) => _buildTradeTile(trade)),
      ],
    );
  }

  Widget _buildTradeTile(dynamic trade) {
    final isWin = trade.profitLoss > 0;
    return Card(
      color: const Color(0xFF13172F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          isWin ? Icons.check_circle : Icons.cancel,
          color: isWin ? Colors.green : Colors.red,
        ),
        title: Text(
          '${trade.direction} ${trade.instrument}',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          'Entry: R${trade.entry} → Exit: R${trade.exit}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Text(
          trade.formattedProfitLoss,
          style: TextStyle(
            color: isWin ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
