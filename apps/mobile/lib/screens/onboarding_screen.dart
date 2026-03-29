// ISOTOPE — Onboarding Screen
// Sign up / Login with FSCA disclaimer acceptance

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _disclaimerAccepted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              
              // Logo
              _buildLogo(),
              
              const SizedBox(height: 48),
              
              // Welcome text
              Text(
                _isLogin ? 'Welcome Back' : 'Create Account',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                _isLogin 
                    ? 'Sign in to continue trading' 
                    : 'Start your 7-day free trial',
                style: const TextStyle(color: Colors.grey),
              ),
              
              const SizedBox(height: 32),
              
              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!_isLogin) ...[
                      _buildNameField(),
                      const SizedBox(height: 16),
                    ],
                    _buildEmailField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 24),
                    
                    // Disclaimer checkbox (sign up only)
                    if (!_isLogin) ...[
                      _buildDisclaimerCheckbox(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : Text(_isLogin ? 'SIGN IN' : 'START FREE TRIAL'),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Toggle login/signup
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin ? "Don't have an account?" : 'Already have an account?',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: Text(
                            _isLogin ? 'Sign Up' : 'Sign In',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // FSCA Disclaimer
              _buildFSCADisclaimer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.amber, Colors.amberAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.auto_graph,
              size: 48,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          // Admin badge (shown when admin logs in)
          if (_emailController.text.contains('keitumetse0407') || 
              _emailController.text.contains('elon'))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple, width: 1),
              ),
              child: const Text(
                'ADMIN ACCESS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                  letterSpacing: 1,
                ),
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
          return 'Please enter your name';
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
        labelText: 'Email',
        prefixIcon: Icon(Icons.email, color: Colors.grey),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      style: const TextStyle(color: Colors.white),
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(Icons.lock, color: Colors.grey),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (!_isLogin && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildDisclaimerCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _disclaimerAccepted,
          onChanged: (value) {
            setState(() {
              _disclaimerAccepted = value ?? false;
            });
          },
          activeColor: Colors.amber,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _disclaimerAccepted = !_disclaimerAccepted;
              });
            },
            child: const Text(
              'I accept the disclaimer and terms of service',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFSCADisclaimer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'FSCA DISCLAIMER',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'ISOTOPE provides educational information only. This is NOT financial advice. We are NOT FSCA licensed. Past performance ≠ future results. Trade at your own risk. Gold trading involves substantial risk of loss.',
            style: TextStyle(fontSize: 11, color: const Color(0xFFE69500)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isLogin && !_disclaimerAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must accept the disclaimer to continue'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    Result result;

    if (_isLogin) {
      result = await authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      result = await authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
      );

      // Accept disclaimer on sign up
      if (result.isSuccess) {
        // TODO: Call API to log disclaimer acceptance
      }
    }

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      // Navigate to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(user: result.data)),
      );
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'An error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
