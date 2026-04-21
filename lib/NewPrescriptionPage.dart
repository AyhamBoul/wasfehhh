import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class _MedEntry {
  final TextEditingController name = TextEditingController();
  final TextEditingController dosage = TextEditingController();
  final TextEditingController frequency = TextEditingController();

  void dispose() {
    name.dispose();
    dosage.dispose();
    frequency.dispose();
  }

  bool get isValid =>
      name.text.trim().isNotEmpty &&
      dosage.text.trim().isNotEmpty &&
      frequency.text.trim().isNotEmpty;
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

  @override
  void dispose() {
    _patientIdController.dispose();
    _notesController.dispose();
    for (final m in _medications) {
      m.dispose();
    }
    super.dispose();
  }

  void _addMedication() {
    setState(() => _medications.add(_MedEntry()));
  }

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

  String _buildQrData() {
    final patientId = _patientIdController.text.trim();
    final medsEncoded = _medications
        .map((m) =>
            '${m.name.text.trim()}:${m.dosage.text.trim()}:${m.frequency.text.trim()}')
        .join(';');
    final notes = _notesController.text.trim();
    final now = DateTime.now();
    final timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return 'QM|$patientId|$medsEncoded|$notes|$timestamp';
  }

  void _issuePrescription() {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final qrData = _buildQrData();
    _showQrDialog(qrData);
  }

  void _showQrDialog(String qrData) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Prescription Issued'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share this QR code with the patient or pharmacist.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                'Patient: ${_patientIdController.text.trim()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${_medications.length} medication(s) prescribed',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearForm();
            },
            child: const Text('New Prescription'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacementNamed(context, '/doctor-dashboard');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child:
                const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
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
      _medications
        ..clear()
        ..add(_MedEntry());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Prescription'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Issue a secure digital prescription',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Patient ID
              TextField(
                controller: _patientIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Patient National ID',
                  hintText: 'e.g. 1092837456',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 24),

              // Medications header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Medications',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _addMedication,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Med'),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Medication entries
              ..._medications.asMap().entries.map((entry) {
                final i = entry.key;
                final med = entry.value;
                return _MedicationEntryCard(
                  index: i,
                  entry: med,
                  canRemove: _medications.length > 1,
                  onRemove: () => _removeMedication(i),
                  onChanged: () => setState(() {}),
                );
              }),

              const SizedBox(height: 16),

              // Additional notes
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (optional)',
                  hintText: 'Special instructions or precautions...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Issue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _issuePrescription,
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Issue Prescription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/doctor-dashboard');
            case 2:
              Navigator.pushReplacementNamed(context, '/doctor-dashboard');
            case 3:
              Navigator.pushReplacementNamed(context, '/signin');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Create'),
          BottomNavigationBarItem(
              icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medication ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (canRemove)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: entry.name,
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: entry.dosage,
                    onChanged: (_) => onChanged(),
                    decoration: const InputDecoration(
                      labelText: 'Dosage (e.g. 500mg)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: entry.frequency,
                    onChanged: (_) => onChanged(),
                    decoration: const InputDecoration(
                      labelText: 'Frequency',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
