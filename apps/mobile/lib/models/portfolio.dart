// ISOTOPE — Portfolio Model
// User Trading Performance Tracking

class Portfolio {
  final String userId;
  final int totalSignals;
  final int wins;
  final int losses;
  final double totalProfit;
  final double winRate;
  final List<SignalHistory> signalHistory;

  Portfolio({
    required this.userId,
    this.totalSignals = 0,
    this.wins = 0,
    this.losses = 0,
    this.totalProfit = 0.0,
    this.winRate = 0.0,
    this.signalHistory = const [],
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    final historyList = json['signalHistory'] as List? ?? [];
    final history = historyList
        .map((h) => SignalHistory.fromJson(h))
        .toList();

    return Portfolio(
      userId: json['userId'] ?? '',
      totalSignals: json['totalSignals'] ?? 0,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      totalProfit: (json['totalProfit'] ?? 0).toDouble(),
      winRate: (json['winRate'] ?? 0).toDouble(),
      signalHistory: history,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'totalSignals': totalSignals,
      'wins': wins,
      'losses': losses,
      'totalProfit': totalProfit,
      'winRate': winRate,
      'signalHistory': signalHistory.map((s) => s.toJson()).toList(),
    };
  }

  String get formattedWinRate => '${(winRate * 100).toStringAsFixed(1)}%';
  String get formattedProfit => 'R${totalProfit.toStringAsFixed(2)}';
}

class SignalHistory {
  final String signalId;
  final String instrument;
  final String direction;
  final double entry;
  final double exit;
  final double profitLoss;
  final DateTime closedAt;

  SignalHistory({
    required this.signalId,
    required this.instrument,
    required this.direction,
    required this.entry,
    required this.exit,
    required this.profitLoss,
    required this.closedAt,
  });

  factory SignalHistory.fromJson(Map<String, dynamic> json) {
    return SignalHistory(
      signalId: json['signalId'] ?? '',
      instrument: json['instrument'] ?? 'XAU/USD',
      direction: json['direction'] ?? 'BUY',
      entry: (json['entry'] ?? 0).toDouble(),
      exit: (json['exit'] ?? 0).toDouble(),
      profitLoss: (json['profitLoss'] ?? 0).toDouble(),
      closedAt: json['closedAt'] != null
          ? DateTime.parse(json['closedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'signalId': signalId,
      'instrument': instrument,
      'direction': direction,
      'entry': entry,
      'exit': exit,
      'profitLoss': profitLoss,
      'closedAt': closedAt.toIso8601String(),
    };
  }

  String get formattedProfitLoss {
    final prefix = profitLoss >= 0 ? '+' : '';
    return 'R${prefix}${profitLoss.toStringAsFixed(2)}';
  }
}
