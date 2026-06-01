import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'auth_service.dart';

class PatientRecordsPage extends StatefulWidget {
  const PatientRecordsPage({super.key});

  @override
  State<PatientRecordsPage> createState() => _PatientRecordsPageState();
}

class _PatientRecordsPageState extends State<PatientRecordsPage> {
  final AuthUser? _user = AuthService().currentUser;
  PatientRecords _records = PatientRecords.empty();
  List<Prescription> _prescriptions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    if (_user == null) return;
    final results = await Future.wait([
      AuthService().getRecords(_user.nationalId),
      AuthService().getPrescriptions(_user.nationalId),
    ]);
    if (mounted) {
      setState(() {
        _records = results[0] as PatientRecords;
        _prescriptions = results[1] as List<Prescription>;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_user == null) return;
    await AuthService().saveRecords(_user.nationalId, _records);
  }

  void _addItem(List<String> list, String hint, String title) {
    final controller = TextEditingController();
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
              Text('Add $title',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary)),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(hintText: hint),
                onSubmitted: (_) => _submitAdd(ctx, controller, list),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _submitAdd(ctx, controller, list),
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitAdd(
      BuildContext ctx, TextEditingController c, List<String> list) {
    final v = c.text.trim();
    if (v.isEmpty) return;
    Navigator.pop(ctx);
    setState(() => list.add(v));
    _save();
  }

  void _removeItem(List<String> list, int index) {
    setState(() => list.removeAt(index));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final Map<dynamic, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<dynamic, dynamic>?;
    final String firstName =
        _user?.firstName ?? (args?['firstName'] as String? ?? 'User');
    final Map<String, String> userArgs = {'firstName': firstName};

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: const Text('My Records')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _user == null
              ? const Center(
                  child: Text('No session found. Please sign in again.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Profile card ──
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: kGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_user.fullName,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text('ID: ${_user.nationalId}',
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.75),
                                          fontSize: 12)),
                                  Text(_user.email,
                                      style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.75),
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.4)),
                              ),
                              child: Text(_user.role,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Allergies ──
                      _RecordSection(
                        title: 'Allergies',
                        icon: Icons.warning_amber_rounded,
                        iconColor: kWarning,
                        onAdd: () => _addItem(
                            _records.allergies, 'e.g. Penicillin', 'Allergy'),
                        child: _records.allergies.isEmpty
                            ? _emptyHint('No allergies recorded.')
                            : Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: _records.allergies
                                    .asMap()
                                    .entries
                                    .map((e) => _RecordChip(
                                          label: e.value,
                                          color: kWarning,
                                          onDelete: () => _removeItem(
                                              _records.allergies, e.key),
                                        ))
                                    .toList(),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // ── Chronic Conditions ──
                      _RecordSection(
                        title: 'Chronic Conditions',
                        icon: Icons.monitor_heart_outlined,
                        iconColor: kDanger,
                        onAdd: () => _addItem(
                            _records.chronicConditions,
                            'e.g. Diabetes Type 2',
                            'Condition'),
                        child: _records.chronicConditions.isEmpty
                            ? _emptyHint('No conditions recorded.')
                            : Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: _records.chronicConditions
                                    .asMap()
                                    .entries
                                    .map((e) => _RecordChip(
                                          label: e.value,
                                          color: kDanger,
                                          onDelete: () => _removeItem(
                                              _records.chronicConditions,
                                              e.key),
                                        ))
                                    .toList(),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // ── Active Prescriptions ──
                      _RecordSection(
                        title: 'Active Prescriptions',
                        icon: Icons.receipt_long_outlined,
                        iconColor: kPrimary,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: kSuccess.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                              '${_prescriptions.where((p) => !p.isDispensed).length} active',
                              style: const TextStyle(
                                  color: kSuccess,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                        child: _prescriptions.isEmpty
                            ? _emptyHint('No prescriptions on record.')
                            : Column(
                                children: _prescriptions
                                    .map((rx) => Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: kBg,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: kPrimaryLight,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: const Icon(
                                                      Icons.medication,
                                                      color: kPrimary,
                                                      size: 18),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        rx.medications
                                                                .isNotEmpty
                                                            ? '${rx.medications.first.name} ${rx.medications.first.dosage}'
                                                            : 'Prescription',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: kTextPrimary,
                                                            fontSize: 13),
                                                      ),
                                                      Text(
                                                        'Dr. ${rx.doctorName}',
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            color:
                                                                kTextSecondary),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: (rx.isDispensed
                                                            ? kTextSecondary
                                                            : kSuccess)
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    rx.isDispensed
                                                        ? 'Dispensed'
                                                        : 'Active',
                                                    style: TextStyle(
                                                        color: rx.isDispensed
                                                            ? kTextSecondary
                                                            : kSuccess,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: _PatientNavBar(
        onHome: () => Navigator.pushReplacementNamed(
            context, '/patient-dashboard', arguments: userArgs),
        onCalendar: () => Navigator.pushReplacementNamed(
            context, '/medication-schedule', arguments: userArgs),
        onPharmacy: () => Navigator.pushReplacementNamed(
            context, '/pharmacy', arguments: userArgs),
        onLogout: () {
          AuthService().signOut();
          Navigator.pushReplacementNamed(context, '/signin');
        },
      ),
    );
  }
}

Widget _emptyHint(String msg) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(msg,
          style: const TextStyle(color: kTextSecondary, fontSize: 13)),
    );

class _RecordSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onAdd;
  final Widget? trailing;
  final Widget child;

  const _RecordSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.onAdd,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary)),
              const Spacer(),
              if (trailing != null) trailing!,
              if (onAdd != null)
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: kPrimaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add,
                        color: kPrimary, size: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RecordChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onDelete;

  const _RecordChip(
      {required this.label, required this.color, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close, size: 13, color: color),
          ),
        ],
      ),
    );
  }
}

class _PatientNavBar extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onCalendar;
  final VoidCallback onPharmacy;
  final VoidCallback onLogout;

  const _PatientNavBar({
    required this.onHome,
    required this.onCalendar,
    required this.onPharmacy,
    required this.onLogout,
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
          _NavItem(icon: Icons.home_rounded, label: 'Home', onTap: onHome),
          _NavItem(
              icon: Icons.calendar_month_rounded,
              label: 'Calendar',
              onTap: onCalendar),
          _NavItem(
              icon: Icons.local_pharmacy_rounded,
              label: 'Pharmacy',
              onTap: onPharmacy),
          _NavItem(
              icon: Icons.logout_rounded, label: 'Logout', onTap: onLogout),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: kTextSecondary, size: 23),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
