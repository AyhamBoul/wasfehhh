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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    if (_user == null) return;
    final records = await AuthService().getRecords(_user.nationalId);
    if (mounted) {
      setState(() {
        _records = records;
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
                          child: const Text('1 active',
                              style: TextStyle(
                                  color: kSuccess,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kBg,
                            borderRadius: BorderRadius.circular(12),
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
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Amoxicillin 500mg',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: kTextPrimary,
                                            fontSize: 13)),
                                    SizedBox(height: 2),
                                    Text(
                                        '3× daily · Post-meal · Dr. Sarah Wilson',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: kTextSecondary)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kSuccess.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Active',
                                    style: TextStyle(
                                        color: kSuccess,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/patient-dashboard',
                  arguments: userArgs);
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
