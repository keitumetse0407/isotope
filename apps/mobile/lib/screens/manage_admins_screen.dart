// ISOTOPE — Manage Admin Users Screen
// View all admins, remove admins, add new admins

import 'package:flutter/material.dart';
import '../models/admin_user.dart';
import 'add_admin_user_screen.dart';

class ManageAdminsScreen extends StatefulWidget {
  final AdminUser currentAdmin;

  const ManageAdminsScreen({Key? key, required this.currentAdmin}) : super(key: key);

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  @override
  Widget build(BuildContext context) {
    // Only founder can manage admins
    if (!widget.currentAdmin.isFounder) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        appBar: AppBar(
          title: const Text('Manage Admins'),
          backgroundColor: const Color(0xFF13172F),
        ),
        body: const Center(
          child: Text(
            'Only founder can manage admins',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text('Manage Admins'),
        backgroundColor: const Color(0xFF13172F),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddAdminUserScreen(currentAdmin: widget.currentAdmin),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Info card
          _buildInfoCard(),

          // Admin list
          Expanded(
            child: _buildAdminList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.purple, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Management',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Add or remove admin users',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminList() {
    // Get all admin accounts
    final admins = AdminAccounts.defaults.map((data) => AdminUser.fromJson(data)).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: admins.length,
      itemBuilder: (context, index) {
        final admin = admins[index];
        return _buildAdminCard(admin);
      },
    );
  }

  Widget _buildAdminCard(AdminUser admin) {
    final isFounder = admin.isFounder;
    final isElon = admin.isElon;

    return Card(
      color: const Color(0xFF13172F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: isFounder ? Colors.purple : Colors.amber,
              child: Text(
                admin.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        admin.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isFounder)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'FOUNDER',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (isElon)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'VIP',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    admin.email,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: admin.permissions.map((perm) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getPermissionLabel(perm),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.green,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                // Can't remove founder or Elon
                if (!isFounder && !isElon)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showRemoveDialog(admin),
                  ),
                if (isFounder || isElon)
                  const Icon(Icons.lock, color: Colors.grey, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getPermissionLabel(String perm) {
    switch (perm) {
      case 'view_all':
        return 'View All';
      case 'manage_users':
        return 'Manage Users';
      case 'view_revenue':
        return 'Revenue';
      case 'admin':
        return 'Full Admin';
      default:
        return perm;
    }
  }

  void _showRemoveDialog(AdminUser admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF13172F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Remove Admin'),
        content: Text('Remove ${admin.name} from admin access?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // In production: Call API to remove admin
              // await ApiService.removeAdminUser(admin.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${admin.name} removed from admin access'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
