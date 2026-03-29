// ISOTOPE — User Model
// User Account and Subscription Data

class User {
  final String id;
  final String email;
  final String name;
  final String tier; // free, trial, pro, elite
  final DateTime? trialStart;
  final DateTime? trialEnd;
  final DateTime? subscriptionEnd;
  final String referralCode;
  final int referralsCount;
  final bool disclaimerAccepted;
  final DateTime? disclaimerTimestamp;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.tier = 'free',
    this.trialStart,
    this.trialEnd,
    this.subscriptionEnd,
    required this.referralCode,
    this.referralsCount = 0,
    this.disclaimerAccepted = false,
    this.disclaimerTimestamp,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      tier: json['tier'] ?? 'free',
      trialStart: json['trialStart'] != null
          ? DateTime.parse(json['trialStart'])
          : null,
      trialEnd: json['trialEnd'] != null
          ? DateTime.parse(json['trialEnd'])
          : null,
      subscriptionEnd: json['subscriptionEnd'] != null
          ? DateTime.parse(json['subscriptionEnd'])
          : null,
      referralCode: json['referralCode'] ?? '',
      referralsCount: json['referralsCount'] ?? 0,
      disclaimerAccepted: json['disclaimerAccepted'] ?? false,
      disclaimerTimestamp: json['disclaimerTimestamp'] != null
          ? DateTime.parse(json['disclaimerTimestamp'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'tier': tier,
      'trialStart': trialStart?.toIso8601String(),
      'trialEnd': trialEnd?.toIso8601String(),
      'subscriptionEnd': subscriptionEnd?.toIso8601String(),
      'referralCode': referralCode,
      'referralsCount': referralsCount,
      'disclaimerAccepted': disclaimerAccepted,
      'disclaimerTimestamp': disclaimerTimestamp?.toIso8601String(),
    };
  }

  bool get isTrial => tier == 'trial';
  bool get isPro => tier == 'pro';
  bool get isElite => tier == 'elite';
  bool get isFree => tier == 'free';

  bool get hasActiveSubscription =>
      isPro || isElite || (isTrial && (trialEnd?.isAfter(DateTime.now()) ?? false));

  int get daysUntilTrialEnd {
    if (trialEnd == null) return 0;
    return trialEnd!.difference(DateTime.now()).inDays;
  }
}
