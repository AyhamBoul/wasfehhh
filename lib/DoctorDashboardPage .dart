import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'auth_service.dart';
import 'doctor_pharmacist_chat.dart';

class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  List<Prescription> _issued = [];

  static const LinearGradient _doctorGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF2DD4BF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent == true) {
      _loadPrescriptions();
    }
  }

  Future<void> _loadPrescriptions() async {
    final id = AuthService().currentUser?.nationalId;
    if (id == null) return;
    final list = await AuthService().getDoctorPrescriptions(id);
    if (mounted) setState(() => _issued = list);
  }

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _resolveFirstName(Map<dynamic, dynamic>? args) {
    final fromArgs = (args?['firstName'] as String? ?? '').trim();
    final raw = fromArgs.isNotEmpty
        ? fromArgs
        : AuthService().currentUser?.fullName ?? 'Doctor';
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.length > 1 &&
        (parts.first.toLowerCase() == 'dr.' ||
            parts.first.toLowerCase() == 'dr')) {
      return parts.skip(1).join(' ');
    }
    return parts.first.isEmpty ? 'Doctor' : parts.first;
  }

  void _signOut() {
    AuthService().signOut();
    Navigator.pushReplacementNamed(context, '/signin');
  }

  void _showNotifications() {
    final pending = _issued.where((rx) => !rx.isDispensed).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: kBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Notifications',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: kTextPrimary)),
            const SizedBox(height: 14),
            if (pending.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('All prescriptions have been dispensed.',
                    style: TextStyle(color: kTextSecondary)),
              )
            else
              ...pending.take(5).map((rx) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                              color: kPrimaryLight,
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.receipt_long_rounded,
                              color: kPrimary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Patient: ${rx.patientId}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: kTextPrimary)),
                              Text(
                                  '${rx.medications.length} med(s) · awaiting dispensing',
                                  style: const TextStyle(
                                      fontSize: 12, color: kTextSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  void _openChat(String firstName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          DoctorPharmacistChat(firstName: firstName, userRole: 'doctor'),
    );
  }

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final Map<dynamic, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<dynamic, dynamic>?;
    final String firstName = _resolveFirstName(args);
    final userArgs = {'firstName': firstName};

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          Positioned(
              top: -120,
              right: -90,
              child: _blurCircle(260, const Color(0xFF0F766E))),
          Positioned(
            top: 260,
            left: -110,
            child: _blurCircle(240, const Color(0xFF2DD4BF)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(firstName),
                  const SizedBox(height: 24),
                  _newPrescriptionCard(userArgs),
                  const SizedBox(height: 26),
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _DoctorCard(
                        icon: Icons.folder_shared_rounded,
                        label: 'Patient History',
                        subtitle: 'View records',
                        color: const Color(0xFF6366F1),
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Patient history coming soon.')),
                        ),
                      ),
                      const SizedBox(width: 14),
                      _DoctorCard(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Pharmacist Chat',
                        subtitle: 'Message now',
                        color: const Color(0xFF0EA5E9),
                        onTap: () => _openChat(firstName),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Prescriptions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: kTextPrimary,
                        ),
                      ),
                      Text(
                        '${_issued.length} total',
                        style: const TextStyle(
                          fontSize: 13,
                          color: kTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_issued.isEmpty)
                    const _EmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'No prescriptions yet',
                      message:
                          'Create your first digital prescription from the button above.',
                    )
                  else
                    ..._issued.reversed.take(5).map((rx) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kCardBg,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: kBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.045),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: _doctorGradient,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.medication_rounded,
                                    color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Patient: ${rx.patientId}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: kTextPrimary),
                                    ),
                                    Text(
                                      '${rx.medications.length} medication(s) · ${_fmtDate(rx.issuedAt)}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: kTextSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: (rx.isDispensed
                                          ? kTextSecondary
                                          : kSuccess)
                                      .withValues(alpha: 0.11),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  rx.isDispensed ? 'Dispensed' : 'Pending',
                                  style: TextStyle(
                                    color: rx.isDispensed
                                        ? kTextSecondary
                                        : kSuccess,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ModernBottomBar(
        onHome: () {},
        onCreate: () => Navigator.pushReplacementNamed(
            context, '/new-prescription',
            arguments: userArgs),
        onMessages: () => _openChat(firstName),
        onSignOut: _signOut,
      ),
    );
  }

  Widget _header(String firstName) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: _doctorGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F766E).withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.medical_services_rounded,
                        color: Colors.white, size: 30),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showNotifications,
                        child: _headerIcon(Icons.notifications_none_rounded),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _signOut,
                        child: _headerIcon(Icons.logout_rounded),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                '$greeting, Dr.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                firstName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Manage prescriptions and patient care from one secure place.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _newPrescriptionCard(Map<String, String> userArgs) {
    return GestureDetector(
      onTap: () => Navigator.pushReplacementNamed(context, '/new-prescription',
          arguments: userArgs),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                gradient: _doctorGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.add_circle_outline_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Prescription',
                    style: TextStyle(
                        fontSize: 16,
                        color: kTextPrimary,
                        fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Issue a secure digital prescription',
                    style: TextStyle(
                        fontSize: 12,
                        color: kTextSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: kTextSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _headerIcon(IconData icon) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DoctorCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 145,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: kCardBg,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const Spacer(),
              Text(label,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: kTextPrimary)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12,
                      color: kTextSecondary,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 46, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: kTextSecondary, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}

class _ModernBottomBar extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onCreate;
  final VoidCallback onMessages;
  final VoidCallback onSignOut;

  const _ModernBottomBar({
    required this.onHome,
    required this.onCreate,
    required this.onMessages,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              active: true,
              onTap: onHome),
          _NavItem(
              icon: Icons.add_circle_rounded,
              label: 'Create',
              onTap: onCreate),
          _NavItem(
              icon: Icons.chat_bubble_rounded,
              label: 'Messages',
              onTap: onMessages),
          _NavItem(
              icon: Icons.logout_rounded, label: 'Logout', onTap: onSignOut),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: active ? kPrimaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? kPrimary : kTextSecondary, size: 23),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? kPrimary : kTextSecondary,
                fontSize: 11,
                fontWeight: active ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
