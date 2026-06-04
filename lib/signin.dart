import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'auth_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
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
      case 'SuperAdmin':
        return '/admin-dashboard';
      default:
        return '/patient-dashboard';
    }
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final user = await AuthService().login(
      nationalId: nationalIdController.text.trim(),
      password: passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid National ID or password.'),
          backgroundColor: kDanger,
        ),
      );
      return;
    }
    Navigator.pushReplacementNamed(
      context,
      _routeForRole(user.role),
      arguments: {'firstName': user.firstName},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          Positioned(top: -120, right: -80, child: _blurCircle(240, kPrimary)),
          Positioned(
            bottom: 120,
            left: -90,
            child: _blurCircle(230, const Color(0xFF38BDF8)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          gradient: kGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimary.withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wasfeh',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: kTextPrimary,
                            ),
                          ),
                          Text(
                            'Smart healthcare platform',
                            style: TextStyle(
                              fontSize: 13,
                              color: kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 44),
                  const Text(
                    'Welcome\nback',
                    style: TextStyle(
                      fontSize: 46,
                      height: 1.03,
                      fontWeight: FontWeight.w900,
                      color: kTextPrimary,
                      letterSpacing: -1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sign in to continue managing prescriptions, records and healthcare services.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 34),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 32,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _input(
                                label: 'National ID',
                                controller: nationalIdController,
                                icon: Icons.badge_outlined,
                                hint: 'e.g. PAT-001',
                                validator: (v) => (v?.trim().isEmpty ?? true)
                                    ? 'National ID is required'
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              _input(
                                label: 'Password',
                                controller: passwordController,
                                icon: Icons.lock_outline_rounded,
                                hint: '••••••••',
                                obscureText: _obscure,
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: kTextSecondary,
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Password is required'
                                        : null,
                              ),
                              const SizedBox(height: 26),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _signIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      Navigator.pushReplacementNamed(
                                          context, '/guest-home'),
                                  icon: const Icon(Icons.explore_outlined),
                                  label: const Text(
                                    'Continue as Guest',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              const _Divider(label: 'or'),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account?",
                                    style: TextStyle(
                                        color: kTextSecondary, fontSize: 14),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pushReplacementNamed(
                                            context, '/create-account'),
                                    child: const Text(
                                      'Register',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: kTextPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: kTextSecondary),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final String label;
  const _Divider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: const TextStyle(
                  color: kTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
