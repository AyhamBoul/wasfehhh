import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'auth_service.dart';

class AdminUserEditPage extends StatefulWidget {
  /// Pass an existing user to edit, or null to create a new one.
  final AuthUser? user;
  const AdminUserEditPage({required this.user, super.key});

  @override
  State<AdminUserEditPage> createState() => _AdminUserEditPageState();
}

class _AdminUserEditPageState extends State<AdminUserEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nationalId;
  late final TextEditingController _fullName;
  late final TextEditingController _email;
  late final TextEditingController _license;
  late final TextEditingController _password;
  late String _role;
  bool _obscure = true;
  bool _saving = false;

  bool get _isEdit => widget.user != null;

  static const _roles = ['Patient', 'Doctor', 'Pharmacist'];

  @override
  void initState() {
    super.initState();
    _nationalId =
        TextEditingController(text: widget.user?.nationalId ?? '');
    _fullName =
        TextEditingController(text: widget.user?.fullName ?? '');
    _email = TextEditingController(text: widget.user?.email ?? '');
    _license =
        TextEditingController(text: widget.user?.licenseNumber ?? '');
    _password = TextEditingController();
    _role = (_roles.contains(widget.user?.role) ? widget.user!.role : 'Patient');
  }

  @override
  void dispose() {
    _nationalId.dispose();
    _fullName.dispose();
    _email.dispose();
    _license.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    String? error;

    if (_isEdit) {
      error = await AuthService().updateUser(
        nationalId: widget.user!.nationalId,
        fullName: _fullName.text.trim(),
        email: _email.text.trim(),
        role: _role,
        licenseNumber: _license.text.trim().isEmpty
            ? null
            : _license.text.trim(),
        newPassword:
            _password.text.isEmpty ? null : _password.text,
      );
    } else {
      if (_password.text.isEmpty) {
        error = 'Password is required for new users.';
      } else {
        error = await AuthService().register(
          nationalId: _nationalId.text.trim(),
          password: _password.text,
          fullName: _fullName.text.trim(),
          email: _email.text.trim(),
          role: _role,
          licenseNumber: _license.text.trim().isEmpty
              ? null
              : _license.text.trim(),
          skipPending: true,
        );
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: kDanger),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEdit
            ? '${_fullName.text.trim()} updated.'
            : '${_fullName.text.trim()} created.'),
        backgroundColor: kSuccess,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final needsLicense = _role == 'Doctor' || _role == 'Pharmacist';

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit User' : 'New User',
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: kTextPrimary)),
        backgroundColor: kCardBg,
        foregroundColor: kTextPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role selector
              const _Label('Role'),
              const SizedBox(height: 8),
              Row(
                children: _roles.map((r) {
                  final selected = _role == r;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _role = r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: selected ? kGradient : null,
                          color: selected
                              ? null
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: selected
                                  ? Colors.transparent
                                  : kBorder),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: kPrimary
                                        .withValues(alpha: 0.2),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Icon(_roleIcon(r),
                                color: selected
                                    ? Colors.white
                                    : kTextSecondary,
                                size: 22),
                            const SizedBox(height: 6),
                            Text(r,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? Colors.white
                                        : kTextSecondary)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              if (!_isEdit) ...[
                const _Label('National ID'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nationalId,
                  decoration: const InputDecoration(
                    hintText: 'e.g. PAT-002',
                    prefixIcon: Icon(Icons.badge_outlined,
                        color: kTextSecondary, size: 20),
                  ),
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Required'
                      : null,
                ),
                const SizedBox(height: 16),
              ],

              const _Label('Full Name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _fullName,
                decoration: const InputDecoration(
                  hintText: 'Ahmad Nasser',
                  prefixIcon: Icon(Icons.person_outline_rounded,
                      color: kTextSecondary, size: 20),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              const _Label('Email Address'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'example@email.com',
                  prefixIcon: Icon(Icons.email_outlined,
                      color: kTextSecondary, size: 20),
                ),
                validator: (v) {
                  final e = v?.trim() ?? '';
                  if (e.isEmpty) return 'Required';
                  if (!e.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (needsLicense) ...[
                const _Label('License Number'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _license,
                  decoration: const InputDecoration(
                    hintText: 'e.g. LIC-DR-2024-002',
                    prefixIcon: Icon(Icons.verified_outlined,
                        color: kTextSecondary, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _Label(_isEdit
                  ? 'New Password (leave blank to keep)'
                  : 'Password'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: kTextSecondary, size: 20),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: kTextSecondary,
                      size: 20,
                    ),
                  ),
                ),
                validator: (v) {
                  if (!_isEdit && (v == null || v.isEmpty)) {
                    return 'Required for new users';
                  }
                  if (v != null &&
                      v.isNotEmpty &&
                      v.length < 6) {
                    return 'Minimum 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _isEdit ? 'Save Changes' : 'Create User',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: kTextPrimary),
      );
}

IconData _roleIcon(String role) {
  switch (role) {
    case 'Doctor':
      return Icons.medical_services_rounded;
    case 'Pharmacist':
      return Icons.local_pharmacy_rounded;
    default:
      return Icons.person_rounded;
  }
}
