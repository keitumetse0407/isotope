// ISOTOPE — Profile Screen
// User settings, subscription management, referrals

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends StatelessWidget {
  final User user;
  final VoidCallback onLogout;

  const ProfileScreen({
    Key? key,
    required this.user,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF13172F),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            _buildProfileHeader(),

            const SizedBox(height: 24),

            // Subscription card
            _buildSubscriptionCard(),

            const SizedBox(height: 24),

            // Referral section
            _buildReferralSection(),

            const SizedBox(height: 24),

            // Settings
            _buildSettingsSection(),

            const SizedBox(height: 32),

            // Logout button
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      color: const Color(0xFF13172F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.amber,
              child: Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  _buildTierBadge(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierBadge() {
    Color tierColor;
    String tierName = user.tier.toUpperCase();

    switch (user.tier) {
      case 'elite':
        tierColor = Colors.purple;
        break;
      case 'pro':
        tierColor = Colors.amber;
        break;
      case 'trial':
        tierColor = Colors.green;
        break;
      default:
        tierColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: tierColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tierColor),
      ),
      child: Text(
        tierName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: tierColor,
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final hasSubscription = user.hasActiveSubscription;
    final daysLeft = user.daysUntilTrialEnd;

    return Card(
      color: const Color(0xFF13172F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SUBSCRIPTION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                Icon(
                  hasSubscription ? Icons.check_circle : Icons.error,
                  color: hasSubscription ? Colors.green : Colors.red,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              hasSubscription ? 'Active' : 'No Active Subscription',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: hasSubscription ? Colors.green : Colors.red,
              ),
            ),
            if (user.isTrial && daysLeft > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Trial expires in $daysLeft days',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReferralSection() {
    return Card(
      color: const Color(0xFF13172F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'REFER & EARN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Give 1 month, Get 1 month',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share your code and both get a free month',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Text(
                      user.referralCode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: user.referralCode));
                    Share.share(
                      'Join ISOTOPE with my code: ${user.referralCode}\n\nAI-powered gold trading signals.\nDownload: [app link]',
                    );
                  },
                  icon: const Icon(Icons.share, color: Colors.amber),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.amber.withOpacity(0.1),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
            if (user.referralsCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                '${user.referralsCount} referrals',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      color: const Color(0xFF13172F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.amber),
            title: const Text('Notifications', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              // Navigate to notification settings
            },
          ),
          const Divider(color: Colors.white10),
          ListTile(
            leading: const Icon(Icons.security, color: Colors.amber),
            title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              // Open privacy policy
            },
          ),
          const Divider(color: Colors.white10),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.amber),
            title: const Text('Terms of Service', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              // Open terms
            },
          ),
          const Divider(color: Colors.white10),
          ListTile(
            leading: const Icon(Icons.support, color: Colors.amber),
            title: const Text('Support', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              // Open support
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF13172F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Logout', style: TextStyle(color: Colors.white)),
              content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.grey)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'LOGOUT',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
