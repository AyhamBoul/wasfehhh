import 'package:flutter/material.dart';
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
      builder: (ctx) => AlertDialog(
        title: Text('Add $title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitAdd(ctx, controller, list),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitAdd(ctx, controller, list),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _submitAdd(
      BuildContext ctx, TextEditingController controller, List<String> list) {
    final value = controller.text.trim();
    if (value.isEmpty) return;
    Navigator.pop(ctx);
    setState(() => list.add(value));
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
    final String firstName = _user?.firstName ??
        (args?['firstName'] as String? ?? 'User');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Records'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('No session found. Please sign in again.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient info card
                      Card(
                        color: Colors.blue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.person,
                                    size: 34, color: Colors.blue),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _user.fullName,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID: ${_user.nationalId}',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 13),
                                    ),
                                    Text(
                                      _user.email,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _user.role,
                                  style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Allergies
                      _SectionHeader(
                        title: 'Allergies',
                        icon: Icons.warning_amber_rounded,
                        iconColor: Colors.orange,
                        onAdd: () => _addItem(
                            _records.allergies, 'e.g. Penicillin', 'Allergy'),
                      ),
                      const SizedBox(height: 8),
                      _records.allergies.isEmpty
                          ? const _EmptyHint(
                              'No allergies recorded. Tap + to add.')
                          : Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _records.allergies
                                  .asMap()
                                  .entries
                                  .map((e) => Chip(
                                        label: Text(e.value),
                                        backgroundColor:
                                            Colors.orange.shade50,
                                        side: BorderSide(
                                            color: Colors.orange.shade200),
                                        deleteIcon: const Icon(Icons.close,
                                            size: 16),
                                        onDeleted: () => _removeItem(
                                            _records.allergies, e.key),
                                      ))
                                  .toList(),
                            ),
                      const SizedBox(height: 24),

                      // Chronic Conditions
                      _SectionHeader(
                        title: 'Chronic Conditions',
                        icon: Icons.monitor_heart,
                        iconColor: Colors.red,
                        onAdd: () => _addItem(
                            _records.chronicConditions,
                            'e.g. Diabetes Type 2',
                            'Condition'),
                      ),
                      const SizedBox(height: 8),
                      _records.chronicConditions.isEmpty
                          ? const _EmptyHint(
                              'No conditions recorded. Tap + to add.')
                          : Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _records.chronicConditions
                                  .asMap()
                                  .entries
                                  .map((e) => Chip(
                                        label: Text(e.value),
                                        backgroundColor: Colors.red.shade50,
                                        side: BorderSide(
                                            color: Colors.red.shade200),
                                        deleteIcon: const Icon(Icons.close,
                                            size: 16),
                                        onDeleted: () => _removeItem(
                                            _records.chronicConditions, e.key),
                                      ))
                                  .toList(),
                            ),
                      const SizedBox(height: 24),

                      // Active Prescriptions (mock)
                      Row(
                        children: [
                          const Icon(Icons.receipt_long, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Active Prescriptions',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            '1 active',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.medication,
                                color: Colors.white, size: 20),
                          ),
                          title: const Text('Amoxicillin 500mg',
                              style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text(
                              '3x daily • Post-meal\nIssued by Dr. Sarah Wilson'),
                          isThreeLine: true,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.green.shade300),
                            ),
                            child: const Text('Active',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          final userArgs = {'firstName': firstName};
          switch (index) {
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_pharmacy), label: 'Pharmacy'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onAdd;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.blue),
          onPressed: onAdd,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String message;
  const _EmptyHint(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
    );
  }
}
