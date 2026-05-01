import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'auth_service.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  String selectedRole = 'Patient';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    nationalIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String _routeForRole(String role) {
    switch (role) {
      case 'Doctor':
        return '/doctor-dashboard';
      case 'Pharmacist':
        return '/pharmacist-portal';
      default:
        return '/patient-dashboard';
    }
  }

  String _extractFirstName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'User' : parts.first;
  }

  Future<void> _createAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final error = await AuthService().register(
      nationalId: nationalIdController.text.trim(),
      password: passwordController.text,
      fullName: fullNameController.text.trim(),
      email: emailController.text.trim(),
      role: selectedRole,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error), backgroundColor: kDanger));
      return;
    }
    Navigator.pushReplacementNamed(
      context,
      _routeForRole(selectedRole),
      arguments: {'firstName': _extractFirstName(fullNameController.text.trim())},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Gradient header ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
                decoration: const BoxDecoration(
                  gradient: kGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.health_and_safety_rounded,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Create account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Join the Wasfeh health ecosystem',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Role selector
                      const Text('I am a',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kTextPrimary)),
                      const SizedBox(height: 10),
                      Row(
                        children: ['Patient', 'Doctor', 'Pharmacist'].map((r) {
                          final selected = selectedRole == r;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => selectedRole = r),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected ? kPrimary : kCardBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected ? kPrimary : kBorder,
                                    width: selected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      r == 'Patient'
                                          ? Icons.person_outline
                                          : r == 'Doctor'
                                              ? Icons.medical_services_outlined
                                              : Icons.local_pharmacy_outlined,
                                      color: selected ? Colors.white : kTextSecondary,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(r,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: selected ? Colors.white : kTextSecondary,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      _fieldLabel('Full Name'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: fullNameController,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Full name is required'
                            : null,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Ahmad Nasser',
                          prefixIcon: Icon(Icons.person_outline,
                              color: kTextSecondary, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _fieldLabel('Email Address'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final e = v?.trim() ?? '';
                          if (e.isEmpty) return 'Email is required';
                          if (!e.contains('@')) return "Enter a valid email";
                          return null;
                        },
                        decoration: const InputDecoration(
                          hintText: 'you@example.com',
                          prefixIcon: Icon(Icons.email_outlined,
                              color: kTextSecondary, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _fieldLabel('National ID'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nationalIdController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'National ID is required'
                            : null,
                        decoration: const InputDecoration(
                          hintText: 'e.g. PAT-001',
                          prefixIcon: Icon(Icons.badge_outlined,
                              color: kTextSecondary, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _fieldLabel('Password'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: passwordController,
                        obscureText: _obscure,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Password is required'
                            : null,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: kTextSecondary, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: kTextSecondary,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createAccount,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Create Account'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account?',
                              style: TextStyle(
                                  color: kTextSecondary, fontSize: 14)),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                                context, '/signin'),
                            style: TextButton.styleFrom(
                                foregroundColor: kPrimary,
                                padding: const EdgeInsets.only(left: 4)),
                            child: const Text('Sign In',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ),
                        ],
                      ),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(
                              context, '/guest-home'),
                          style: TextButton.styleFrom(
                              foregroundColor: kTextSecondary),
                          child: const Text('Continue as Guest',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _fieldLabel(String text) => Text(
      text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: kTextPrimary,
          letterSpacing: 0.2),
    );
