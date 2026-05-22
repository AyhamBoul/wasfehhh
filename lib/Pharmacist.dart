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
    // Queue undispensed prescriptions for this pharmacist.
    if (pharmId != null && prescriptions.any((p) => !p.isDispensed)) {
      await AuthService().addToPharmPending(pharmId, prescriptions);
      await _loadPending();
    }
    if (!mounted) return;
    final activePrescriptions = prescriptions.where((p) => !p.isDispensed).toList();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_outline,
                        color: kPrimary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Patient Found',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary)),
                ],
              ),
              const SizedBox(height: 16),
              _LookupRow(label: 'Name', value: user.fullName),
              _LookupRow(label: 'National ID', value: user.nationalId),
              _LookupRow(label: 'Email', value: user.email),
              _LookupRow(
                label: 'Rx',
                value: activePrescriptions.isEmpty
                    ? 'No active prescriptions'
                    : '${activePrescriptions.length} active — added to queue',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                      onTap: _openScanner,
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
                          onTap: _openScanner,
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
                        Text('${_pending.length} pending',
                            style: const TextStyle(
                                fontSize: 13, color: kTextSecondary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_pending.isEmpty)
                      _EmptyState(
                        icon: Icons.inbox_outlined,
                        message: 'No pending refill requests right now.',
                      )
                    else
                      ..._pending.map((rx) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: kCardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: kBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: kPrimaryLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.medication,
                                        color: kPrimary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Patient: ${rx.patientId}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: kTextPrimary),
                                        ),
                                        Text(
                                          rx.medications.isNotEmpty
                                              ? '${rx.medications.first.name} · ${rx.medications.length} med(s)'
                                              : 'Prescription',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: kTextSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          kWarning.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Pending',
                                      style: TextStyle(
                                          color: kWarning,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
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
              await _openScanner();
            case 2:
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => DoctorPharmacistChat(
                    firstName: firstName, userRole: 'pharmacist'),
              );
            case 3:
              Navigator.pushReplacementNamed(context, '/profile',
                  arguments: {'firstName': firstName});
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

class _LookupRow extends StatelessWidget {
  final String label;
  final String value;
  const _LookupRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kTextSecondary)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: kTextPrimary)),
            ),
          ],
        ),
      );
}
