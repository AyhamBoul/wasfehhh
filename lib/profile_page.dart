import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'auth_service.dart';
import 'doctor_pharmacist_chat.dart';
import 'prescription_scanner_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Color _roleColor(String role) {
    switch (role) {
      case 'Doctor':
        return const Color(0xFF0F766E);
      case 'Pharmacist':
        return const Color(0xFF7C3AED);
      default:
        return kPrimary;
    }
  }

  LinearGradient _roleGradient(String role) {
    switch (role) {
      case 'Doctor':
        return const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF2DD4BF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'Pharmacist':
        return const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return kGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/signin');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    final Map<dynamic, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<dynamic, dynamic>?;
    final String firstName = args?['firstName'] as String? ?? user.firstName;
    final Map<String, String> userArgs = {'firstName': firstName};

    final gradient = _roleGradient(user.role);
    final roleColor = _roleColor(user.role);
    final initials = user.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                decoration: BoxDecoration(gradient: gradient),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 2.5),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        user.role,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Account info ──
                    _SectionTitle(label: 'Account Information'),
                    const SizedBox(height: 10),
                    _InfoCard(children: [
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: 'Full Name',
                        value: user.fullName,
                        color: roleColor,
                      ),
                      const _Divider(),
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'National ID',
                        value: user.nationalId,
                        color: roleColor,
                      ),
                      const _Divider(),
                      _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user.email,
                        color: roleColor,
                      ),
                      const _Divider(),
                      _InfoRow(
                        icon: Icons.work_outline,
                        label: 'Role',
                        value: user.role,
                        color: roleColor,
                      ),
                      if (user.licenseNumber != null) ...[
                        const _Divider(),
                        _InfoRow(
                          icon: Icons.verified_outlined,
                          label: user.role == 'Doctor'
                              ? 'Medical License'
                              : 'Pharmacy License',
                          value: user.licenseNumber!,
                          color: roleColor,
                        ),
                      ],
                    ]),

                    const SizedBox(height: 20),

                    // ── Quick links ──
                    _SectionTitle(label: 'Quick Access'),
                    const SizedBox(height: 10),
                    _InfoCard(children: [
                      if (user.role == 'Patient') ...[
                        _LinkRow(
                          icon: Icons.article_outlined,
                          label: 'My Medical Records',
                          color: roleColor,
                          onTap: () => Navigator.pushNamed(
                              context, '/patient-records',
                              arguments: userArgs),
                        ),
                        const _Divider(),
                        _LinkRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Medication Schedule',
                          color: roleColor,
                          onTap: () => Navigator.pushNamed(
                              context, '/medication-schedule',
                              arguments: userArgs),
                        ),
                        const _Divider(),
                      ],
                      _LinkRow(
                        icon: Icons.local_pharmacy_outlined,
                        label: 'Nearby Pharmacies',
                        color: roleColor,
                        onTap: () => Navigator.pushNamed(
                            context, '/pharmacy',
                            arguments: userArgs),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // ── Sign out ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          AuthService().signOut();
                          Navigator.pushReplacementNamed(context, '/signin');
                        },
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Sign Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDanger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Wasfeh · Quick Medi v1.0',
                        style: const TextStyle(
                            fontSize: 11, color: kTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildNav(context, user, userArgs),
    );
  }

  Widget _buildNav(BuildContext context, AuthUser user,
      Map<String, String> userArgs) {
    void openChat() => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => DoctorPharmacistChat(
            firstName: user.firstName,
            userRole: user.role.toLowerCase(),
          ),
        );

    void openScanner() => Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
              builder: (_) => const PrescriptionScannerPage()),
        );

    switch (user.role) {
      case 'Doctor':
        return BottomNavigationBar(
          currentIndex: 3,
          onTap: (i) {
            switch (i) {
              case 0:
                Navigator.pushReplacementNamed(context, '/doctor-dashboard',
                    arguments: userArgs);
              case 1:
                Navigator.pushReplacementNamed(context, '/new-prescription',
                    arguments: userArgs);
              case 2:
                openChat();
            }
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                activeIcon: Icon(Icons.add_circle),
                label: 'Create'),
            BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Messages'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_outlined),
                activeIcon: Icon(Icons.account_circle),
                label: 'Profile'),
          ],
        );
      case 'Pharmacist':
        return BottomNavigationBar(
          currentIndex: 3,
          onTap: (i) {
            switch (i) {
              case 0:
                Navigator.pushReplacementNamed(
                    context, '/pharmacist-portal',
                    arguments: userArgs);
              case 1:
                openScanner();
              case 2:
                openChat();
            }
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
            BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Messages'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_outlined),
                activeIcon: Icon(Icons.account_circle),
                label: 'Profile'),
          ],
        );
      default:
        return BottomNavigationBar(
          currentIndex: 3,
          onTap: (i) {
            switch (i) {
              case 0:
                Navigator.pushReplacementNamed(
                    context, '/patient-dashboard',
                    arguments: userArgs);
              case 1:
                Navigator.pushReplacementNamed(
                    context, '/medication-schedule',
                    arguments: userArgs);
              case 2:
                Navigator.pushReplacementNamed(context, '/pharmacy',
                    arguments: userArgs);
            }
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'Calendar'),
            BottomNavigationBarItem(
                icon: Icon(Icons.local_pharmacy_outlined),
                activeIcon: Icon(Icons.local_pharmacy),
                label: 'Pharmacy'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_outlined),
                activeIcon: Icon(Icons.account_circle),
                label: 'Profile'),
          ],
        );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: kTextSecondary,
            letterSpacing: 0.5),
      );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Column(children: children),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: kTextSecondary)),
                  const SizedBox(height: 1),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LinkRow(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary)),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: kTextSecondary),
            ],
          ),
        ),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 1),
      );
}
