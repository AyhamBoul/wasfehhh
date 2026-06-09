import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'auth_service.dart';

class PrescriptionViewPage extends StatefulWidget {
  final String qrData;
  const PrescriptionViewPage({required this.qrData, super.key});

  @override
  State<PrescriptionViewPage> createState() => _PrescriptionViewPageState();
}

class _PrescriptionViewPageState extends State<PrescriptionViewPage> {
  bool _dispensing = false;
  bool _dispensed = false;

  late final Map<String, String> _parsed;
  late final List<Map<String, String>> _meds;
  bool _valid = false;

  @override
  void initState() {
    super.initState();
    _parsed = {};
    _meds = [];
    _parse();
  }

  void _parse() {
    var raw = widget.qrData;
    // Strip URL wrapper if full URL was passed
    for (final prefix in [
      'https://wasfeh-f9b26.web.app/#/rx?d=',
      'https://wasfeh.app/rx?d=',
    ]) {
      if (raw.startsWith(prefix)) {
        raw = raw.substring(prefix.length);
        break;
      }
    }
    if (!raw.startsWith('QM|')) return;
    final parts = raw.split('|');
    if (parts.length < 4) return;
    _parsed['patientId'] = parts[1];
    _parsed['medsRaw'] = parts[2];
    _parsed['notes'] = parts[3];
    _parsed['timestamp'] = parts.length > 4 ? parts[4] : '';
    _parsed['prescriptionId'] = parts.length > 5 ? parts[5] : '';

    for (final m in parts[2].split(';')) {
      final mp = m.split(':');
      _meds.add({
        'name': mp.isNotEmpty ? mp[0] : '',
        'dosage': mp.length > 1 ? mp[1] : '',
        'frequency': mp.length > 2 ? mp[2] : '',
      });
    }
    _valid = true;
  }

  Future<void> _markDispensed() async {
    final rxId = _parsed['prescriptionId'] ?? '';
    final patientId = _parsed['patientId'] ?? '';
    if (rxId.isEmpty) return;
    setState(() => _dispensing = true);
    final ok = await AuthService().markDispensed(rxId, patientId);
    setState(() {
      _dispensing = false;
      _dispensed = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final isPharmacist = user?.role == 'Pharmacist';

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Prescription'),
        leading: user != null
            ? BackButton(onPressed: () => Navigator.pop(context))
            : null,
        actions: [
          if (user == null)
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/signin'),
              child: const Text('Sign In',
                  style: TextStyle(color: kPrimary, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: !_valid
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: kDanger),
                  SizedBox(height: 12),
                  Text('Invalid prescription QR code',
                      style: TextStyle(color: kTextSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status banner
                  if (_dispensed)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: kSuccess.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kSuccess.withValues(alpha: 0.3)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.check_circle, color: kSuccess),
                        SizedBox(width: 10),
                        Text('Marked as dispensed',
                            style: TextStyle(
                                color: kSuccess, fontWeight: FontWeight.w700)),
                      ]),
                    ),

                  // Header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: kGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.verified, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Verified Prescription',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 12),
                        Text('Patient: ${_parsed['patientId']}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                        if ((_parsed['timestamp'] ?? '').isNotEmpty)
                          Text('Issued: ${_parsed['timestamp']}',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Medications
                  const Text('Medications',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary)),
                  const SizedBox(height: 10),
                  ..._meds.map((m) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: kCardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kBorder),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kPrimaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.medication_outlined,
                                color: kPrimary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m['name']!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14)),
                                  Text('${m['dosage']} · ${m['frequency']}',
                                      style: const TextStyle(
                                          color: kTextSecondary, fontSize: 13)),
                                ]),
                          ),
                        ]),
                      )),

                  // Notes
                  if ((_parsed['notes'] ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Notes',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: kTextPrimary)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kCardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                      ),
                      child: Text(_parsed['notes']!,
                          style: const TextStyle(color: kTextSecondary)),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Pharmacist action
                  if (isPharmacist && !_dispensed)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _dispensing ? null : _markDispensed,
                        icon: _dispensing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.local_pharmacy_rounded),
                        label: Text(
                            _dispensing ? 'Updating…' : 'Mark as Dispensed'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccess),
                      ),
                    ),

                  if (!isPharmacist && user == null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kPrimaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Sign in as a pharmacist to mark this prescription as dispensed.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kPrimary, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
