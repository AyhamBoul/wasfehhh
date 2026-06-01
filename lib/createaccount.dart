import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'auth_service.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController licenseController = TextEditingController();

  String selectedRole = 'Patient';
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    nationalIdController.dispose();
    passwordController.dispose();
    licenseController.dispose();
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

  Future<void> _createAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final needsLicense =
        selectedRole == 'Doctor' || selectedRole == 'Pharmacist';
    if (needsLicense && licenseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('License number is required for this role.'),
          backgroundColor: kDanger,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }
    final error = await AuthService().register(
      nationalId: nationalIdController.text.trim(),
      password: passwordController.text,
      fullName: fullNameController.text.trim(),
      email: emailController.text.trim(),
      role: selectedRole,
      licenseNumber: needsLicense ? licenseController.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: kDanger),
      );
      return;
    }
    Navigator.pushReplacementNamed(
      context,
      _routeForRole(selectedRole),
      arguments: {'firstName': AuthService().currentUser?.firstName ?? ''},
    );
  }

  @override
  Widget build(BuildContext context) {
    final needsLicense =
        selectedRole == 'Doctor' || selectedRole == 'Pharmacist';

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          Positioned(top: -120, right: -80, child: _blurCircle(240, kPrimary)),
          Positioned(
            top: 180,
            left: -90,
            child: _blurCircle(220, const Color(0xFF38BDF8)),
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
                          Icons.health_and_safety_rounded,
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
                                fontSize: 13, color: kTextSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    'Create your\naccount',
                    style: TextStyle(
                      fontSize: 42,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: kTextPrimary,
                      letterSpacing: -1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Choose your role and join the secure healthcare ecosystem.',
                    style: TextStyle(
                        fontSize: 15, height: 1.5, color: kTextSecondary),
                  ),
                  const SizedBox(height: 28),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.86),
                          borderRadius: BorderRadius.circular(28),
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
                              const Text(
                                'Select your role',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: kTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _roleCard('Patient', Icons.person_rounded),
                                  _roleCard('Doctor',
                                      Icons.medical_services_rounded),
                                  _roleCard('Pharmacist',
                                      Icons.local_pharmacy_rounded),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _input(
                                label: 'Full Name',
                                controller: fullNameController,
                                icon: Icons.person_outline_rounded,
                                hint: 'Ahmad Nasser',
                                validator: (v) => (v?.trim().isEmpty ?? true)
                                    ? 'Full name is required'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _input(
                                label: 'Email Address',
                                controller: emailController,
                                icon: Icons.email_outlined,
                                hint: 'example@email.com',
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  final e = v?.trim() ?? '';
                                  if (e.isEmpty) return 'Email is required';
                                  if (!e.contains('@')) {
                                    return 'Invalid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _input(
                                label: 'National ID',
                                controller: nationalIdController,
                                icon: Icons.badge_outlined,
                                hint: 'e.g. PAT-001',
                                validator: (v) => (v?.trim().isEmpty ?? true)
                                    ? 'National ID is required'
                                    : null,
                              ),
                              const SizedBox(height: 16),
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
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (v.length < 6) {
                                    return 'Minimum 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              if (needsLicense) ...[
                                const SizedBox(height: 16),
                                _input(
                                  label: 'License Number',
                                  controller: licenseController,
                                  icon: Icons.verified_outlined,
                                  hint: 'e.g. LIC-DR-2024-001',
                                  validator: (v) =>
                                      (v?.trim().isEmpty ?? true)
                                          ? 'License number is required'
                                          : null,
                                ),
                              ],
                              const SizedBox(height: 26),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _createAccount,
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
                                          'Create Account',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Already have an account?',
                                    style: TextStyle(
                                        color: kTextSecondary, fontSize: 14),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pushReplacementNamed(
                                            context, '/signin'),
                                    child: const Text(
                                      'Sign In',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                              Center(
                                child: TextButton(
                                  onPressed: () =>
                                      Navigator.pushReplacementNamed(
                                          context, '/guest-home'),
                                  child: const Text(
                                    'Continue as Guest',
                                    style: TextStyle(color: kTextSecondary),
                                  ),
                                ),
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

  Widget _roleCard(String title, IconData icon) {
    final isSelected = selectedRole == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRole = title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected ? kGradient : null,
            color: isSelected ? null : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? Colors.transparent : kBorder,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: kPrimary.withValues(alpha: 0.22),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : kTextSecondary, size: 26),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : kTextSecondary,
                ),
              ),
            ],
          ),
        ),
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
