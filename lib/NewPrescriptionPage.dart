import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'app_theme.dart';
import 'auth_service.dart';
import 'medication_service.dart';

const _units = ['mg', 'ml', 'mcg', 'g', 'IU', 'tablet(s)', 'capsule(s)', 'unit(s)'];

class _MedEntry {
  final TextEditingController name = TextEditingController();
  final TextEditingController amount = TextEditingController();
  String unit = 'mg';
  final TextEditingController frequency = TextEditingController();

  void dispose() {
    name.dispose();
    amount.dispose();
    frequency.dispose();
  }

  bool get isValid =>
      name.text.trim().isNotEmpty &&
      amount.text.trim().isNotEmpty &&
      frequency.text.trim().isNotEmpty;

  String get dosageString => '${amount.text.trim()} $unit';
}

class NewPrescriptionPage extends StatefulWidget {
  const NewPrescriptionPage({super.key});

  @override
  State<NewPrescriptionPage> createState() => _NewPrescriptionPageState();
}

class _NewPrescriptionPageState extends State<NewPrescriptionPage> {
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final List<_MedEntry> _medications = [_MedEntry()];
  bool _checkingInteractions = false;

  Future<bool> _warnInteractions() async {
    final names = _medications.map((m) => m.name.text.trim()).toList();
    if (names.length < 2) return true;
    setState(() => _checkingInteractions = true);
    final hits = await MedicationService.instance.checkAll(names);
    setState(() => _checkingInteractions = false);
    if (hits.isEmpty || !mounted) return true;

    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: kWarning, size: 26),
              const SizedBox(width: 10),
              Text('${hits.length} Interaction${hits.length > 1 ? 's' : ''} Found',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ]),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: hits.map((h) {
                  final color = h.severity == 'major'
                      ? kDanger
                      : h.severity == 'moderate'
                          ? kWarning
                          : kSuccess;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(h.severity.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('${h.drug1} + ${h.drug2}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Text(h.description,
                            style: const TextStyle(
                                fontSize: 12, color: kTextSecondary)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Review Meds',
                    style: TextStyle(color: kTextSecondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: kDanger),
                child: const Text('Issue Anyway'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    _notesController.dispose();
    for (final m in _medications) {
      m.dispose();
    }
    super.dispose();
  }

  void _addMedication() => setState(() => _medications.add(_MedEntry()));

  void _removeMedication(int index) {
    if (_medications.length == 1) return;
    setState(() {
      _medications[index].dispose();
      _medications.removeAt(index);
    });
  }

  String? _validate() {
    if (_patientIdController.text.trim().isEmpty) {
      return 'Patient National ID is required.';
    }
    for (int i = 0; i < _medications.length; i++) {
      if (!_medications[i].isValid) {
        return 'Medication ${i + 1}: fill in name, dosage, and frequency.';
      }
    }
    return null;
  }

  String _buildQrData(String prescriptionId) {
    final patientId = _patientIdController.text.trim();
    final medsEncoded = _medications
        .map((m) =>
            '${m.name.text.trim()}:${m.dosageString}:${m.frequency.text.trim()}')
        .join(';');
    final notes = _notesController.text.trim();
    final now = DateTime.now();
    final ts =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final qmData = 'QM|$patientId|$medsEncoded|$notes|$ts|$prescriptionId';
    return 'https://wasfeh.app/rx?d=$qmData';
  }

  Future<void> _issuePrescription(Map<String, String> userArgs) async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error), backgroundColor: kDanger));
      return;
    }
    final proceed = await _warnInteractions();
    if (!proceed) return;
    final prescriptionId = 'RX-${DateTime.now().millisecondsSinceEpoch}';
    final doctor = AuthService().currentUser;
    if (doctor != null) {
      final patientId = _patientIdController.text.trim();
      await AuthService().savePrescription(Prescription(
        id: prescriptionId,
        patientId: patientId,
        doctorId: doctor.nationalId,
        doctorName: doctor.fullName,
        medications: _medications
            .map((m) => PrescriptionMed(
                  name: m.name.text.trim(),
                  dosage: m.dosageString,
                  frequency: m.frequency.text.trim(),
                ))
            .toList(),
        notes: _notesController.text.trim(),
        issuedAt: DateTime.now(),
      ));
      final medNames = _medications.map((m) => m.name.text.trim()).join(', ');
      await AuthService().sendPatientMessage(
        patientId,
        doctor.nationalId,
        doctor.fullName,
        'New prescription issued: $medNames. Open your prescriptions to view and show your QR code at the pharmacy.',
      );
    }
    if (mounted) _showQrDialog(_buildQrData(prescriptionId), userArgs);
  }

  void _showQrDialog(String qrData, Map<String, String> userArgs) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: kSuccess.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline,
                    color: kSuccess, size: 28),
              ),
              const SizedBox(height: 12),
              const Text('Prescription Issued',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary)),
              const SizedBox(height: 4),
              const Text('Share this QR with the patient or pharmacist.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: kTextSecondary)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.transparent,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: kPrimaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Patient: ${_patientIdController.text.trim()}  ·  ${_medications.length} medication(s)',
                  style: const TextStyle(
                      fontSize: 12,
                      color: kPrimary,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _clearForm();
                      },
                      child: const Text('New'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushReplacementNamed(
                            context, '/doctor-dashboard',
                            arguments: userArgs);
                      },
                      child: const Text('Done'),
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

  void _clearForm() {
    _patientIdController.clear();
    _notesController.clear();
    setState(() {
      for (final m in _medications) {
        m.dispose();
      }
      _medications..clear()..add(_MedEntry());
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<dynamic, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<dynamic, dynamic>?;
    final String firstName = (args?['firstName'] as String? ?? '').trim().isNotEmpty
        ? args!['firstName'] as String
        : AuthService().currentUser?.firstName ?? 'Doctor';
    final Map<String, String> userArgs = {'firstName': firstName};

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('New Prescription'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pushReplacementNamed(
              context, '/doctor-dashboard',
              arguments: userArgs),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient ID
              _SectionLabel(label: 'Patient National ID'),
              const SizedBox(height: 6),
              TextField(
                controller: _patientIdController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  hintText: 'e.g. PAT-001',
                  prefixIcon: Icon(Icons.badge_outlined,
                      color: kTextSecondary, size: 20),
                ),
              ),
              const SizedBox(height: 24),

              // Medications header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _SectionLabel(label: 'Medications'),
                  GestureDetector(
                    onTap: _addMedication,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kPrimaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: kPrimary, size: 16),
                          SizedBox(width: 4),
                          Text('Add Med',
                              style: TextStyle(
                                  color: kPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              ..._medications.asMap().entries.map((e) => _MedicationEntryCard(
                    index: e.key,
                    entry: e.value,
                    canRemove: _medications.length > 1,
                    onRemove: () => _removeMedication(e.key),
                    onChanged: () => setState(() {}),
                  )),

              const SizedBox(height: 8),
              _SectionLabel(label: 'Additional Notes'),
              const SizedBox(height: 6),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Special instructions or precautions...',
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _checkingInteractions
                      ? null
                      : () => _issuePrescription(userArgs),
                  icon: _checkingInteractions
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.qr_code, size: 18),
                  label: Text(_checkingInteractions
                      ? 'Checking interactions…'
                      : 'Issue Prescription'),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _DoctorNavBar(
        activeIndex: 1,
        onHome: () => Navigator.pushReplacementNamed(
            context, '/doctor-dashboard', arguments: userArgs),
        onCreate: () {},
        onMessages: () => Navigator.pushNamed(
            context, '/doctor-messages', arguments: userArgs),
        onLogout: () {
          AuthService().signOut();
          Navigator.pushReplacementNamed(context, '/signin');
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
            letterSpacing: 0.2),
      );
}

class _DoctorNavBar extends StatelessWidget {
  final int activeIndex;
  final VoidCallback onHome;
  final VoidCallback onCreate;
  final VoidCallback onMessages;
  final VoidCallback onLogout;

  const _DoctorNavBar({
    required this.activeIndex,
    required this.onHome,
    required this.onCreate,
    required this.onMessages,
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
          _DNavItem(icon: Icons.home_rounded, label: 'Home',
              active: activeIndex == 0, onTap: onHome),
          _DNavItem(icon: Icons.add_circle_rounded, label: 'Create',
              active: activeIndex == 1, onTap: onCreate),
          _DNavItem(icon: Icons.chat_bubble_rounded, label: 'Messages',
              active: activeIndex == 2, onTap: onMessages),
          _DNavItem(icon: Icons.logout_rounded, label: 'Logout',
              onTap: onLogout),
        ],
      ),
    );
  }
}

class _DNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _DNavItem({
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
            Text(label,
                style: TextStyle(
                    color: active ? kPrimary : kTextSecondary,
                    fontSize: 11,
                    fontWeight:
                        active ? FontWeight.w900 : FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _MedicationEntryCard extends StatelessWidget {
  final int index;
  final _MedEntry entry;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _MedicationEntryCard({
    required this.index,
    required this.entry,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: kPrimaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text('${index + 1}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: kPrimary)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Medication',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: kTextPrimary)),
                ],
              ),
              if (canRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: kDanger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close,
                        color: kDanger, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Autocomplete<String>(
            optionsBuilder: (textEditingValue) async {
              final q = textEditingValue.text.trim();
              if (q.length < 2) return const [];
              return MedicationService.instance.search(q);
            },
            onSelected: (selection) {
              entry.name.text = selection;
              onChanged();
            },
            fieldViewBuilder: (context, controller, focusNode, _) {
              controller.addListener(() {
                entry.name.text = controller.text;
              });
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (_) => onChanged(),
                decoration: const InputDecoration(
                  hintText: 'Medication name',
                  prefixIcon: Icon(Icons.medication_outlined,
                      color: kTextSecondary, size: 18),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) => Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (_, i) {
                      final drug = options.elementAt(i);
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.medication_outlined,
                            size: 16, color: kPrimary),
                        title: Text(drug,
                            style: const TextStyle(fontSize: 13)),
                        onTap: () => onSelected(drug),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Dosage: amount + unit dropdown
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: entry.amount,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    hintText: 'Amount (e.g. 500)',
                    prefixText: 'Dose: ',
                    prefixStyle: TextStyle(
                        color: kTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: entry.unit,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    labelStyle: TextStyle(fontSize: 12),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: _units
                      .map((u) => DropdownMenuItem(
                          value: u,
                          child: Text(u,
                              style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      entry.unit = v;
                      onChanged();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: entry.frequency,
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(
                    hintText: 'Frequency (e.g. 3× daily)',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
