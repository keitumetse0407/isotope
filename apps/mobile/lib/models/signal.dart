// ISOTOPE — Signal Model
// Gold Trading Signal Data Structure

class Signal {
  final String id;
  final String instrument;
  final String direction; // BUY or SELL
  final double entry;
  final double stopLoss;
  final double takeProfit1;
  final double takeProfit2;
  final double confidence;
  final String rationale;
  final DateTime timestamp;
  final String status; // PENDING, ACTIVE, CLOSED_WIN, CLOSED_LOSS
  final double? outcome; // Profit/loss in R if closed

  Signal({
    required this.id,
    required this.instrument,
    required this.direction,
    required this.entry,
    required this.stopLoss,
    required this.takeProfit1,
    required this.takeProfit2,
    required this.confidence,
    required this.rationale,
    required this.timestamp,
    this.status = 'PENDING',
    this.outcome,
  });

  factory Signal.fromJson(Map<String, dynamic> json) {
    return Signal(
      id: json['id'] ?? '',
      instrument: json['instrument'] ?? 'XAU/USD',
      direction: json['direction'] ?? 'BUY',
      entry: (json['entry'] ?? 0).toDouble(),
      stopLoss: (json['stopLoss'] ?? 0).toDouble(),
      takeProfit1: (json['takeProfit1'] ?? 0).toDouble(),
      takeProfit2: (json['takeProfit2'] ?? 0).toDouble(),
      confidence: (json['confidence'] ?? 0).toDouble(),
      rationale: json['rationale'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : DateTime.now(),
      status: json['status'] ?? 'PENDING',
      outcome: json['outcome']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instrument': instrument,
      'direction': direction,
      'entry': entry,
      'stopLoss': stopLoss,
      'takeProfit1': takeProfit1,
      'takeProfit2': takeProfit2,
      'confidence': confidence,
      'rationale': rationale,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
      'outcome': outcome,
    };
  }

  double get riskReward {
    final risk = (entry - stopLoss).abs();
    final reward = (takeProfit1 - entry).abs();
    return risk > 0 ? reward / risk : 0;
  }

  String get formattedEntry => 'R${entry.toStringAsFixed(2)}';
  String get formattedSL => 'R${stopLoss.toStringAsFixed(2)}';
  String get formattedTP1 => 'R${takeProfit1.toStringAsFixed(2)}';
  String get formattedTP2 => 'R${takeProfit2.toStringAsFixed(2)}';
  String get formattedConfidence => '${(confidence * 100).toInt()}%';
}
