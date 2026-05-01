import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'auth_service.dart';

class PatientDashboardPage extends StatelessWidget {
  const PatientDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<dynamic, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<dynamic, dynamic>?;
    final String firstName =
        (args?['firstName'] as String? ?? '').trim().isNotEmpty
            ? args!['firstName'] as String
            : AuthService().currentUser?.firstName ?? 'there';
    final Map<String, String> userArgs = {'firstName': firstName};

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                decoration: const BoxDecoration(
                  gradient: kGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting,',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 14),
                            ),
                            Text(
                              firstName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.notifications_outlined,
                                  color: Colors.white, size: 22),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: kWarning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Next dose card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.medication_outlined,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Next Dose',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                                const Text('Amoxicillin 500mg — 2:00 PM',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: kPrimary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Mark taken'),
                          ),
                        ],
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
                    const Text('Quick Actions',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary)),
                    const SizedBox(height: 14),

                    // 2×2 grid
                    Row(
                      children: [
                        _ActionCard(
                          icon: Icons.article_outlined,
                          label: 'My Records',
                          color: const Color(0xFF6366F1),
                          onTap: () => Navigator.pushNamed(
                              context, '/patient-records',
                              arguments: userArgs),
                        ),
                        const SizedBox(width: 12),
                        _ActionCard(
                          icon: Icons.calendar_month_outlined,
                          label: 'Medication Calendar',
                          color: kSuccess,
                          onTap: () => Navigator.pushNamed(
                              context, '/medication-schedule',
                              arguments: userArgs),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _ActionCard(
                          icon: Icons.local_pharmacy_outlined,
                          label: 'Pharmacy Map',
                          color: kWarning,
                          onTap: () => Navigator.pushNamed(
                              context, '/pharmacy',
                              arguments: userArgs),
                        ),
                        const SizedBox(width: 12),
                        _ActionCard(
                          icon: Icons.connect_without_contact_outlined,
                          label: 'Doctor Connect',
                          color: const Color(0xFFEC4899),
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Doctor Connect coming soon.')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recent section
                    const Text('Active Prescription',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary)),
                    const SizedBox(height: 12),
                    _PrescriptionCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          switch (i) {
            case 1:
              Navigator.pushReplacementNamed(context, '/medication-schedule',
                  arguments: userArgs);
            case 2:
              Navigator.pushReplacementNamed(context, '/pharmacy',
                  arguments: userArgs);
            case 3:
              Navigator.pushReplacementNamed(context, '/signin');
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
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kPrimaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medication, color: kPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amoxicillin 500mg',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary,
                        fontSize: 14)),
                SizedBox(height: 2),
                Text('3× daily · Post-meal · Dr. Sarah Wilson',
                    style: TextStyle(
                        fontSize: 12, color: kTextSecondary)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Active',
                style: TextStyle(
                    color: kSuccess,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
