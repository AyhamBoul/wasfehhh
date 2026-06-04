import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'auth_service.dart';
import 'doctor_pharmacist_chat.dart';
import 'prescription_scanner_page.dart';

class PharmacistPortalPage extends StatefulWidget {
  const PharmacistPortalPage({super.key});

  @override
  State<PharmacistPortalPage> createState() => _PharmacistPortalPageState();
}

class _PharmacistPortalPageState extends State<PharmacistPortalPage> {
  final TextEditingController _lookupController = TextEditingController();
  List<Prescription> _pending = [];

  static const LinearGradient _pharmGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  @override
  void dispose() {
    _lookupController.dispose();
    super.dispose();
  }

  Future<void> _loadPending() async {
    final id = AuthService().currentUser?.nationalId;
    if (id == null) return;
    final list = await AuthService().getPharmPending(id);
    if (mounted) setState(() => _pending = list);
  }

  void _signOut() {
    AuthService().signOut();
    Navigator.pushReplacementNamed(context, '/signin');
  }

  void _showNotifications() {
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
            if (_pending.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No pending refills in your queue.',
                    style: TextStyle(color: kTextSecondary)),
              )
            else
              ...  _pending.take(5).map((rx) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                              color: kPrimaryLight,
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.medication_rounded,
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
                                  rx.medications.isNotEmpty
                                      ? '${rx.medications.first.name} · pending dispensing'
                                      : 'Pending dispensing',
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

  Future<void> _openScanner() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const PrescriptionScannerPage()),
    );
    if (result != null && result['dispensed'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dispensed for patient ${result['patientId']}'),
          backgroundColor: kSuccess,
        ),
      );
      await _loadPending();
    }
  }

  Future<void> _lookupPatient() async {
    final id = _lookupController.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a National ID to search.')),
      );
      return;
    }
    final pharmId = AuthService().currentUser?.nationalId;
    final results = await Future.wait([
      AuthService().findUser(id),
      AuthService().getPrescriptions(id),
    ]);
    if (!mounted) return;
    final user = results[0] as AuthUser?;
    final prescriptions = results[1] as List<Prescription>;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No patient found for "$id".'),
          backgroundColor: kDanger,
        ),
      );
      return;
    }
    if (pharmId != null && prescriptions.any((p) => !p.isDispensed)) {
      await AuthService().addToPharmPending(pharmId, prescriptions);
      await _loadPending();
    }
    if (!mounted) return;
    final active = prescriptions.where((p) => !p.isDispensed).toList();
    _showPatientPrescriptionsDialog(user, active);
  }

  void _showPatientPrescriptionsDialog(AuthUser user, List<Prescription> active) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_outline,
                          color: kPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: kTextPrimary)),
                          Text(user.nationalId,
                              style: const TextStyle(
                                  fontSize: 12, color: kTextSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (active.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No active prescriptions.',
                        style: TextStyle(color: kTextSecondary)),
                  )
                else ...[
                  Text('${active.length} active prescription(s)',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kTextSecondary)),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: active.length,
                      itemBuilder: (_, i) {
                        final rx = active[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kCardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rx.medications.map((m) => m.name).join(', '),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: kTextPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text('Dr. ${rx.doctorName}',
                                  style: const TextStyle(
                                      fontSize: 12, color: kTextSecondary)),
                              if (rx.notes.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(rx.notes,
                                    style: const TextStyle(
                                        fontSize: 12, color: kTextSecondary)),
                              ],
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    final saved = await AuthService()
                                        .markDispensed(rx.id, rx.patientId);
                                    if (!mounted) return;
                                    if (saved) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            'Dispensed for ${user.fullName}'),
                                        backgroundColor: kSuccess,
                                      ));
                                      await _loadPending();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kSuccess,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Mark as Dispensed',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
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
          DoctorPharmacistChat(firstName: firstName, userRole: 'pharmacist'),
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
    final String firstName =
        (args?['firstName'] as String? ?? '').trim().isNotEmpty
            ? args!['firstName'] as String
            : AuthService().currentUser?.firstName ?? 'Pharmacist';

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          Positioned(
              top: -120,
              right: -90,
              child: _blurCircle(260, const Color(0xFF7C3AED))),
          Positioned(
            top: 260,
            left: -110,
            child: _blurCircle(240, const Color(0xFFA78BFA)),
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
                  // Manual lookup
                  Container(
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
                        const Text('Manual ID Lookup',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: kTextPrimary)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _lookupController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _lookupPatient(),
                          decoration: InputDecoration(
                            hintText: 'Enter patient National ID...',
                            prefixIcon: const Icon(Icons.search,
                                color: kTextSecondary, size: 20),
                            suffixIcon: GestureDetector(
                              onTap: _lookupPatient,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: kPrimary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.arrow_forward,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                      _PharmCard(
                        icon: Icons.qr_code_scanner_rounded,
                        label: 'Open Scanner',
                        subtitle: 'Scan QR code',
                        color: const Color(0xFF7C3AED),
                        onTap: _openScanner,
                      ),
                      const SizedBox(width: 14),
                      _PharmCard(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Doctor Chat',
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
                        'Pending Refills',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: kTextPrimary,
                        ),
                      ),
                      Text(
                        '${_pending.length} pending',
                        style: const TextStyle(
                            fontSize: 13,
                            color: kTextSecondary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_pending.isEmpty)
                    _EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'No pending refills',
                      message:
                          'Look up a patient by ID to add their prescriptions to the queue.',
                    )
                  else
                    ..._pending.map((rx) => Container(
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
                                  gradient: _pharmGradient,
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
                                      rx.medications.isNotEmpty
                                          ? '${rx.medications.first.name} · ${rx.medications.length} med(s)'
                                          : 'Prescription',
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
                                  color: kWarning.withValues(alpha: 0.11),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Pending',
                                  style: TextStyle(
                                      color: kWarning,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800),
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
        onScan: _openScanner,
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
            gradient: _pharmGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
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
                    child: const Icon(Icons.local_pharmacy_rounded,
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
                'Scan, verify and dispense prescriptions securely.',
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

class _PharmCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PharmCard({
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
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: const Color(0xFFCBD5E1)),
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
  final VoidCallback onScan;
  final VoidCallback onMessages;
  final VoidCallback onSignOut;

  const _ModernBottomBar({
    required this.onHome,
    required this.onScan,
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
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan',
              onTap: onScan),
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
