import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'auth_service.dart';
import 'doctor_pharmacist_chat.dart';

class DoctorMessagesPage extends StatefulWidget {
  final String firstName;
  const DoctorMessagesPage({required this.firstName, super.key});

  @override
  State<DoctorMessagesPage> createState() => _DoctorMessagesPageState();
}

class _DoctorMessagesPageState extends State<DoctorMessagesPage> {
  List<String> _patientIds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final doctorId = AuthService().currentUser?.nationalId;
    if (doctorId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final issued = await AuthService().getDoctorPrescriptions(doctorId);
    final ids = issued.map((rx) => rx.patientId).toSet().toList();
    if (mounted) {
      setState(() {
        _patientIds = ids;
        _loading = false;
      });
    }
  }

  void _openPharmacistChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DoctorPharmacistChat(
        firstName: widget.firstName,
        userRole: 'doctor',
      ),
    );
  }

  void _openPatientCompose(String patientId) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kPrimaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: kPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Send Message',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: kTextPrimary)),
                        Text('To patient: $patientId',
                            style: const TextStyle(
                                fontSize: 12, color: kTextSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 4,
                minLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Type your message to the patient...',
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    final doctor = AuthService().currentUser;
                    if (doctor == null) return;
                    Navigator.pop(ctx);
                    await AuthService().sendPatientMessage(
                      patientId,
                      doctor.nationalId,
                      doctor.fullName,
                      text,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Message sent to $patientId'),
                        backgroundColor: kSuccess,
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Send',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
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
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Messages',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: kTextPrimary)),
        backgroundColor: kCardBg,
        foregroundColor: kTextPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Channels',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: kTextSecondary,
                        letterSpacing: 0.4)),
                const SizedBox(height: 10),
                _MessageEntry(
                  icon: Icons.local_pharmacy_rounded,
                  color: const Color(0xFF7C3AED),
                  title: 'Pharmacist Channel',
                  subtitle:
                      'Ask about stock, dosages, and medication queries',
                  onTap: _openPharmacistChat,
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Patients',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kTextSecondary,
                            letterSpacing: 0.4)),
                    Text('${_patientIds.length} patient(s)',
                        style: const TextStyle(
                            fontSize: 12, color: kTextSecondary)),
                  ],
                ),
                const SizedBox(height: 10),
                if (_patientIds.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: kBorder),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 42, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 10),
                        Text('No patients yet.',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: kTextPrimary)),
                        SizedBox(height: 4),
                        Text(
                          'Issue a prescription to message a patient.',
                          style:
                              TextStyle(color: kTextSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  ..._patientIds.map((id) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MessageEntry(
                          icon: Icons.person_rounded,
                          color: kPrimary,
                          title: 'Patient $id',
                          subtitle: 'Tap to send a message',
                          onTap: () => _openPatientCompose(id),
                        ),
                      )),
              ],
            ),
    );
  }
}

class _MessageEntry extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MessageEntry({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: kTextSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: kTextSecondary),
          ],
        ),
      ),
    );
  }
}
