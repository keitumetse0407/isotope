// ISOTOPE — Add Admin User Screen
// Allow founder to add new admin users

import 'package:flutter/material.dart';
import '../models/admin_user.dart';

class AddAdminUserScreen extends StatefulWidget {
  final AdminUser currentAdmin;

  const AddAdminUserScreen({Key? key, required this.currentAdmin}) : super(key: key);

  @override
  State<AddAdminUserScreen> createState() => _AddAdminUserScreenState();
}

class _AddAdminUserScreenState extends State<AddAdminUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedRole = 'admin';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _availableRoles = [
    {
      'value': 'admin',
      'label': 'Admin',
      'description': 'View dashboard, manage users',
      'permissions': ['view_all', 'manage_users', 'view_revenue'],
    },
    {
      'value': 'support',
      'label': 'Support',
      'description': 'View users, respond to tickets',
      'permissions': ['view_all'],
    },
    {
      'value': 'analyst',
      'label': 'Analyst',
      'description': 'View signals and analytics only',
      'permissions': ['view_all', 'view_revenue'],
    },
    {
      'value': 'elon',
      'label': 'VIP (Elon)',
      'description': 'View-only access to everything',
      'permissions': ['view_all', 'view_revenue'],
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only founder can add admins
    if (!widget.currentAdmin.isFounder) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E21),
        appBar: AppBar(title: const Text('Add Admin')),
        body: const Center(
          child: Text(
            'Only founder can add admins',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        title: const Text('Add Admin User'),
        backgroundColor: const Color(0xFF13172F),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              _buildInfoCard(),

              const SizedBox(height: 24),

              // Name field
              _buildNameField(),

              const SizedBox(height: 16),

              // Email field
              _buildEmailField(),

              const SizedBox(height: 16),

              // Role selector
              _buildRoleSelector(),

              const SizedBox(height: 24),

              // Permissions preview
              _buildPermissionsPreview(),

              const SizedBox(height: 32),

              // Submit button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.admin_panel_settings, color: Colors.purple, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Admin User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'New admin gets lifetime free access',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Full Name',
        prefixIcon: Icon(Icons.person, color: Colors.grey),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a name';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email Address',
        prefixIcon: Icon(Icons.email, color: Colors.grey),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an email';
        }
        if (!value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Role',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ..._availableRoles.map((role) => _buildRoleOption(role)),
      ],
    );
  }

  Widget _buildRoleOption(Map<String, dynamic> role) {
    final isSelected = _selectedRole == role['value'];
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role['value'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.withOpacity(0.2) : const Color(0xFF13172F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: role['value'],
              groupValue: _selectedRole,
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
              activeColor: Colors.purple,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role['label'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role['description'] as String,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsPreview() {
    final selectedRoleData = _availableRoles.firstWhere(
      (r) => r['value'] == _selectedRole,
    );
    final permissions = selectedRoleData['permissions'] as List<dynamic>;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13172F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PERMISSIONS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...permissions.map((perm) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  _formatPermission(perm as String),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _formatPermission(String perm) {
    switch (perm) {
      case 'view_all':
        return 'View all signals and data';
      case 'manage_users':
        return 'Manage users (ban, upgrade, downgrade)';
      case 'view_revenue':
        return 'View revenue and analytics';
      case 'admin':
        return 'Full admin access';
      default:
        return perm;
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'ADD ADMIN USER',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // Get selected role permissions
    final selectedRoleData = _availableRoles.firstWhere(
      (r) => r['value'] == _selectedRole,
    );

    // Create new admin user
    final newAdmin = AdminUser(
      id: 'admin_${DateTime.now().millisecondsSinceEpoch}',
      email: _emailController.text,
      name: _nameController.text,
      role: _selectedRole,
      lifetimeFree: true,
      createdAt: DateTime.now(),
      permissions: List<String>.from(selectedRoleData['permissions'] as List<dynamic>),
    );

    // In production: Send to backend API
    // await ApiService.addAdminUser(newAdmin);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      // Show success
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF13172F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.purple),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.purple,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ADMIN ADDED',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${newAdmin.name} can now login with:\n${newAdmin.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lifetime free access granted',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('DONE'),
            ),
          ],
        ),
      );

      // Clear form
      _nameController.clear();
      _emailController.clear();
    }
  }
}
