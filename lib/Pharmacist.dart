import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'doctor_pharmacist_chat.dart';
import 'prescription_scanner_page.dart';

class PharmacistPortalPage extends StatelessWidget {
  const PharmacistPortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<dynamic, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<dynamic, dynamic>?;
    final String firstName =
        (args?['firstName'] as String? ?? '').trim().isNotEmpty
            ? args!['firstName'] as String
            : 'Pharmacist';

    Future<void> openScanner() async {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(builder: (_) => const PrescriptionScannerPage()),
      );
      if (result != null && result['dispensed'] == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Dispensed for patient ${result['patientId']}'),
            backgroundColor: kSuccess,
          ),
        );
      }
    }

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
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                            Text('Hello,',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14)),
                            Text(firstName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5)),
                          ],
                        ),
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
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Scan CTA
                    GestureDetector(
                      onTap: openScanner,
                      child: Container(
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
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.qr_code_scanner,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Scan Prescription',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  Text('Verify & dispense medications instantly',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                color: Colors.white70, size: 14),
                          ],
                        ),
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
                    // Manual lookup
                    const Text('Manual ID Lookup',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary)),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter patient National ID...',
                        prefixIcon: const Icon(Icons.search,
                            color: kTextSecondary, size: 20),
                        suffixIcon: Container(
                          margin: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Quick Actions',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kTextPrimary)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _PharmCard(
                          icon: Icons.qr_code_scanner,
                          label: 'Open Scanner',
                          subtitle: 'Scan QR code',
                          color: const Color(0xFF7C3AED),
                          onTap: openScanner,
                        ),
                        const SizedBox(width: 12),
                        _PharmCard(
                          icon: Icons.chat_bubble_outline,
                          label: 'Doctor Chat',
                          subtitle: 'Message now',
                          color: const Color(0xFF0EA5E9),
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => DoctorPharmacistChat(
                                firstName: firstName,
                                userRole: 'pharmacist'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pending Refills',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: kTextPrimary)),
                        Text('0 pending',
                            style: TextStyle(
                                fontSize: 13, color: kTextSecondary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _EmptyState(
                      icon: Icons.inbox_outlined,
                      message: 'No pending refill requests right now.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) async {
          switch (i) {
            case 1:
              await openScanner();
            case 2:
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => DoctorPharmacistChat(
                    firstName: firstName, userRole: 'pharmacist'),
              );
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
              icon: Icon(Icons.qr_code_scanner),
              label: 'Scan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Messages'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              activeIcon: Icon(Icons.account_circle),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _PharmCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PharmCard(
      {required this.icon,
      required this.label,
      required this.subtitle,
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
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: kTextSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 10),
          Text(message,
              style: const TextStyle(color: kTextSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
