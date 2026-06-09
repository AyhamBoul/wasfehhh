import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
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

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // If opened via a QR prescription link
    final fragment = Uri.base.fragment; // e.g. "/rx?d=QM|..."
    if (fragment.startsWith('/rx')) {
      final qStr = fragment.contains('?') ? fragment.split('?').last : '';
      final d = Uri.splitQueryString(qStr)['d'] ?? '';
      if (d.isNotEmpty) {
        final user = AuthService().currentUser;
        if (user != null) {
          // Already signed in — go straight to prescription view
          Navigator.pushReplacementNamed(context, '/rx', arguments: {'d': d});
        } else {
          // Not signed in — go to sign in, pass QR data to redirect after
          Navigator.pushReplacementNamed(context, '/signin',
              arguments: {'pendingRx': d});
        }
        return;
      }
    }

    final user = AuthService().currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/signin');
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
          Positioned(top: -100, right: -90, child: _blurCircle(260, kPrimary)),
          Positioned(
            bottom: -120,
            left: -90,
            child: _blurCircle(260, const Color(0xFF38BDF8)),
          ),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  margin: const EdgeInsets.all(26),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 38,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 34,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 86,
                        width: 86,
                        decoration: BoxDecoration(
                          gradient: kGradient,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimary.withValues(alpha: 0.28),
                              blurRadius: 26,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.health_and_safety_rounded,
                          color: Colors.white,
                          size: 46,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Wasfeh',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: kTextPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Smart healthcare platform',
                        style: TextStyle(
                          fontSize: 14,
                          color: kTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: kPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
