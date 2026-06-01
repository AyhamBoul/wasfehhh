import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'auth_service.dart';

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  List<Prescription> _prescriptions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final id = AuthService().currentUser?.nationalId;
    if (id == null) return;
    final list = await AuthService().getPrescriptions(id);
    if (mounted) {
      setState(() {
        _prescriptions = list;
        _loading = false;
      });
    }
  }

  void _signOut() {
    AuthService().signOut();
    Navigator.pushReplacementNamed(context, '/signin');
  }

  void _showNotifications() {
    final active = _prescriptions.where((p) => !p.isDispensed).toList();
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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Notifications',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: kTextPrimary)),
            const SizedBox(height: 14),
            if (active.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No active prescriptions.',
                    style: TextStyle(color: kTextSecondary)),
              )
            else
              ...active.expand((rx) => rx.medications.map((med) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kPrimaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.medication_rounded,
                              color: kPrimary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${med.name} ${med.dosage}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: kTextPrimary)),
                              Text(med.frequency,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: kTextSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))),
          ],
        ),
      ),
    );
  }

  // Returns the earliest time slot (hour, minute) for a frequency string.
  (int, int) _firstSlot(String frequency) {
    final lower = frequency.toLowerCase();
    if (lower.contains('night') ||
        lower.contains('sleep') ||
        lower.contains('bedtime') ||
        lower.contains('hs')) {
      return (21, 0);
    }
    return (8, 0);
  }

  Future<void> _markNextDoseTaken(
      Prescription rx, PrescriptionMed med, Map<String, String> userArgs) async {
    final userId = AuthService().currentUser?.nationalId ?? 'guest';
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final storageKey = 'qm_taken_${userId}_$dateKey';
    final slot = _firstSlot(med.frequency);
    final takenKey = '${rx.id}:${med.name}:${slot.$1}:${slot.$2}';

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    Set<String> taken = {};
    if (raw != null) {
      try {
        taken = (jsonDecode(raw) as List<dynamic>).whereType<String>().toSet();
      } catch (_) {}
    }
    taken.add(takenKey);
    await prefs.setString(storageKey, jsonEncode(taken.toList()));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${med.name} marked as taken.'),
        backgroundColor: kSuccess,
      ),
    );
    Navigator.pushReplacementNamed(context, '/medication-schedule',
        arguments: userArgs);
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
    final String firstName =
        (args?['firstName'] as String? ?? '').trim().isNotEmpty
            ? args!['firstName'] as String
            : AuthService().currentUser?.firstName ?? 'there';
    final userArgs = {'firstName': firstName};

    final active = _prescriptions.where((p) => !p.isDispensed).toList();
    final firstMed =
        active.isNotEmpty && active.first.medications.isNotEmpty
            ? active.first.medications.first
            : null;

    return Scaffold(
      backgroundColor: kBg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : Stack(
              children: [
                Positioned(
                    top: -120, right: -90, child: _blurCircle(260, kPrimary)),
                Positioned(
                  top: 260,
                  left: -110,
                  child: _blurCircle(240, const Color(0xFF38BDF8)),
                ),
                SafeArea(
                  child: RefreshIndicator(
                    onRefresh: _loadDashboard,
                    color: kPrimary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header(firstName),
                          const SizedBox(height: 24),
                          _nextDoseCard(
                              active.isNotEmpty ? active.first : null,
                              firstMed,
                              userArgs),
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
                              _ActionCard(
                                icon: Icons.folder_copy_rounded,
                                label: 'My Records',
                                subtitle: 'Health files',
                                color: const Color(0xFF6366F1),
                                onTap: () => Navigator.pushNamed(
                                    context, '/patient-records',
                                    arguments: userArgs),
                              ),
                              const SizedBox(width: 14),
                              _ActionCard(
                                icon: Icons.calendar_month_rounded,
                                label: 'Calendar',
                                subtitle: 'Medication plan',
                                color: kSuccess,
                                onTap: () => Navigator.pushNamed(
                                    context, '/medication-schedule',
                                    arguments: userArgs),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _ActionCard(
                                icon: Icons.local_pharmacy_rounded,
                                label: 'Pharmacy',
                                subtitle: 'Nearby places',
                                color: kWarning,
                                onTap: () => Navigator.pushNamed(
                                    context, '/pharmacy',
                                    arguments: userArgs),
                              ),
                              const SizedBox(width: 14),
                              _ActionCard(
                                icon: Icons.qr_code_scanner_rounded,
                                label: 'Scanner',
                                subtitle: 'Prescription scan',
                                color: const Color(0xFFEC4899),
                                onTap: () => Navigator.pushNamed(
                                    context, '/prescription-scanner',
                                    arguments: userArgs),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Active Prescriptions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: kTextPrimary,
                                ),
                              ),
                              Text('${active.length} active',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: kTextSecondary,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (active.isEmpty)
                            _emptyPrescriptionCard()
                          else
                            ...active.take(3).map(_prescriptionCard),
                          const SizedBox(height: 90),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _loading
          ? null
          : _ModernBottomBar(
              onHome: () {},
              onCalendar: () => Navigator.pushReplacementNamed(
                  context, '/medication-schedule',
                  arguments: userArgs),
              onPharmacy: () => Navigator.pushReplacementNamed(
                  context, '/pharmacy', arguments: userArgs),
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
            gradient: kGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withValues(alpha: 0.25),
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
                    child: const Icon(Icons.health_and_safety_rounded,
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
                '$greeting,',
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
                'Here is your health overview.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82), fontSize: 14),
              ),
            ],
          ),
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

  Widget _nextDoseCard(Prescription? firstRx, PrescriptionMed? firstMed,
      Map<String, String> userArgs) {
    return _InfoCard(
      icon: Icons.medication_liquid_rounded,
      title: 'Next Dose',
      subtitle: firstMed != null
          ? '${firstMed.name} ${firstMed.dosage}'
          : 'No active prescriptions',
      buttonText: firstMed != null ? 'Mark taken' : 'Calendar',
      onPressed: firstMed != null && firstRx != null
          ? () => _markNextDoseTaken(firstRx, firstMed, userArgs)
          : () => Navigator.pushNamed(context, '/medication-schedule',
              arguments: userArgs),
    );
  }

  Widget _prescriptionCard(Prescription rx) {
    final firstMed =
        rx.medications.isNotEmpty ? rx.medications.first : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              gradient: kGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.medication_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: firstMed == null
                ? const Text('Prescription has no medications',
                    style: TextStyle(color: kTextSecondary))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstMed.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: kTextPrimary,
                            fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${firstMed.dosage} · ${firstMed.frequency}',
                        style: const TextStyle(
                            fontSize: 12, color: kTextSecondary),
                      ),
                      Text(
                        'Dr. ${rx.doctorName} · ${rx.medications.length} med(s)',
                        style: const TextStyle(
                            fontSize: 12, color: kTextSecondary),
                      ),
                    ],
                  ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (rx.isDispensed ? kTextSecondary : kSuccess)
                  .withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              rx.isDispensed ? 'Dispensed' : 'Active',
              style: TextStyle(
                color: rx.isDispensed ? kTextSecondary : kSuccess,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPrescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 18),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_rounded,
              size: 44, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          Text(
            'No active prescriptions',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: kTextPrimary),
          ),
          SizedBox(height: 6),
          Text(
            'Prescriptions created by your doctor will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextSecondary, fontSize: 13),
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
        color: color.withValues(alpha: 0.14),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: kPrimaryLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: kPrimary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        color: kTextSecondary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 14,
                        color: kTextPrimary,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(buttonText, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
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

class _ModernBottomBar extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onCalendar;
  final VoidCallback onPharmacy;
  final VoidCallback onSignOut;

  const _ModernBottomBar({
    required this.onHome,
    required this.onCalendar,
    required this.onPharmacy,
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
              icon: Icons.calendar_month_rounded,
              label: 'Calendar',
              onTap: onCalendar),
          _NavItem(
              icon: Icons.local_pharmacy_rounded,
              label: 'Pharmacy',
              onTap: onPharmacy),
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
