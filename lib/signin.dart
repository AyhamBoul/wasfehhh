import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'auth_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

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
          content: Text('Incorrect National ID or password.'),
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
  void dispose() {
    nationalIdController.dispose();
    passwordController.dispose();
    super.dispose();
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
                padding: const EdgeInsets.fromLTRB(28, 48, 28, 40),
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
                      child: const Icon(Icons.medical_services_rounded,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to your Wasfeh account',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Form ──
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _label('National ID'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nationalIdController,
                        keyboardType: TextInputType.text,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'National ID is required'
                            : null,
                        decoration: const InputDecoration(
                          hintText: 'e.g. PAT-001',
                          prefixIcon: Icon(Icons.badge_outlined,
                              color: kTextSecondary, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label('Password'),
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
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: kPrimary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Forgot password?',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Sign In'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushReplacementNamed(
                              context, '/guest-home'),
                          icon: const Icon(Icons.explore_outlined, size: 18),
                          label: const Text('Continue as Guest'),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _Divider(label: 'or'),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?",
                              style: TextStyle(
                                  color: kTextSecondary, fontSize: 14)),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                                context, '/create-account'),
                            style: TextButton.styleFrom(
                                foregroundColor: kPrimary,
                                padding: const EdgeInsets.only(left: 4)),
                            child: const Text('Register',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ),
                        ],
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

Widget _label(String text) => Text(
      text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: kTextPrimary,
          letterSpacing: 0.2),
    );

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
              style: const TextStyle(color: kTextSecondary, fontSize: 13)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
