import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final String nationalId;
  final String fullName;
  final String email;
  final String role;
  final String? licenseNumber;

  AuthUser({
    required this.nationalId,
    required this.fullName,
    required this.email,
    required this.role,
    this.licenseNumber,
  });

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'User' : parts.first;
  }

  Map<String, dynamic> toJson() => {
        'nationalId': nationalId,
        'fullName': fullName,
        'email': email,
        'role': role,
        if (licenseNumber != null) 'licenseNumber': licenseNumber,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        nationalId: json['nationalId'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        licenseNumber: json['licenseNumber'] as String?,
      );
}

class PatientRecords {
  final List<String> allergies;
  final List<String> chronicConditions;

  PatientRecords({
    required this.allergies,
    required this.chronicConditions,
  });

  Map<String, dynamic> toJson() => {
        'allergies': allergies,
        'chronicConditions': chronicConditions,
      };

  factory PatientRecords.fromJson(Map<String, dynamic> json) => PatientRecords(
        allergies: List<String>.from(json['allergies'] as List),
        chronicConditions:
            List<String>.from(json['chronicConditions'] as List),
      );

  factory PatientRecords.empty() =>
      PatientRecords(allergies: [], chronicConditions: []);
}

class PrescriptionMed {
  final String name;
  final String dosage;
  final String frequency;

  PrescriptionMed(
      {required this.name, required this.dosage, required this.frequency});

  Map<String, dynamic> toJson() =>
      {'name': name, 'dosage': dosage, 'frequency': frequency};

  factory PrescriptionMed.fromJson(Map<String, dynamic> j) => PrescriptionMed(
        name: j['name'] as String,
        dosage: j['dosage'] as String,
        frequency: j['frequency'] as String,
      );
}

class Prescription {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final List<PrescriptionMed> medications;
  final String notes;
  final DateTime issuedAt;
  bool isDispensed;
  DateTime? dispensedAt;

  Prescription({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.medications,
    required this.notes,
    required this.issuedAt,
    this.isDispensed = false,
    this.dispensedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'medications': medications.map((m) => m.toJson()).toList(),
        'notes': notes,
        'issuedAt': issuedAt.millisecondsSinceEpoch,
        'isDispensed': isDispensed,
        if (dispensedAt != null)
          'dispensedAt': dispensedAt!.millisecondsSinceEpoch,
      };

  factory Prescription.fromJson(Map<String, dynamic> j) => Prescription(
        id: j['id'] as String,
        patientId: j['patientId'] as String,
        doctorId: j['doctorId'] as String,
        doctorName: j['doctorName'] as String,
        medications: (j['medications'] as List<dynamic>)
            .map((m) => PrescriptionMed.fromJson(m as Map<String, dynamic>))
            .toList(),
        notes: j['notes'] as String,
        issuedAt: DateTime.fromMillisecondsSinceEpoch(j['issuedAt'] as int),
        isDispensed: j['isDispensed'] as bool? ?? false,
        dispensedAt: j['dispensedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(j['dispensedAt'] as int)
            : null,
      );
}

class AuthService {
  static const _usersKey = 'qm_users';
  static const _passwordsKey = 'qm_passwords';

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // In-memory session — set on login/register, cleared on sign-out
  AuthUser? currentUser;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<AuthUser>> _loadUsers() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_usersKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => AuthUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, String>> _loadPasswords() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_passwordsKey);
    if (raw == null) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  Future<void> _saveUsers(List<AuthUser> users) async {
    final prefs = await _prefs;
    await prefs.setString(_usersKey, jsonEncode(users.map((u) => u.toJson()).toList()));
  }

  Future<void> _savePasswords(Map<String, String> passwords) async {
    final prefs = await _prefs;
    await prefs.setString(_passwordsKey, jsonEncode(passwords));
  }

  /// Returns null on success, or an error message string.
  Future<String?> register({
    required String nationalId,
    required String password,
    required String fullName,
    required String email,
    required String role,
    String? licenseNumber,
  }) async {
    final users = await _loadUsers();
    final exists = users.any(
      (u) => u.nationalId.toLowerCase() == nationalId.trim().toLowerCase(),
    );
    if (exists) return 'An account with this National ID already exists.';

    final passwords = await _loadPasswords();
    final newUser = AuthUser(
      nationalId: nationalId.trim(),
      fullName: fullName.trim(),
      email: email.trim(),
      role: role,
      licenseNumber: licenseNumber?.trim(),
    );
    users.add(newUser);
    passwords[nationalId.trim().toLowerCase()] = password;

    await _saveUsers(users);
    await _savePasswords(passwords);
    currentUser = newUser;
    return null;
  }

  Future<PatientRecords> getRecords(String nationalId) async {
    final prefs = await _prefs;
    final key = 'qm_records_${nationalId.trim().toLowerCase()}';
    final raw = prefs.getString(key);
    if (raw == null) return PatientRecords.empty();
    return PatientRecords.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveRecords(String nationalId, PatientRecords records) async {
    final prefs = await _prefs;
    final key = 'qm_records_${nationalId.trim().toLowerCase()}';
    await prefs.setString(key, jsonEncode(records.toJson()));
  }

  /// Seeds demo accounts on first launch. Safe to call every startup.
  Future<void> seedDemoAccounts() async {
    final demos = [
      (
        nationalId: 'DOC-001',
        password: 'Doctor123',
        fullName: 'Dr. Sarah Wilson',
        email: 'sarah.wilson@quickmedi.com',
        role: 'Doctor',
        licenseNumber: 'LIC-DR-2024-001',
      ),
      (
        nationalId: 'PAT-001',
        password: 'Patient123',
        fullName: 'John Doe',
        email: 'john.doe@quickmedi.com',
        role: 'Patient',
        licenseNumber: null,
      ),
      (
        nationalId: 'PHA-001',
        password: 'Pharma123',
        fullName: 'Alice Smith',
        email: 'alice.smith@quickmedi.com',
        role: 'Pharmacist',
        licenseNumber: 'LIC-PH-2024-001',
      ),
    ];

    for (final d in demos) {
      await register(
        nationalId: d.nationalId,
        password: d.password,
        fullName: d.fullName,
        email: d.email,
        role: d.role,
        licenseNumber: d.licenseNumber,
      );
    }
    currentUser = null;
  }

  /// Returns the authenticated user or null if credentials are wrong.
  Future<AuthUser?> login({
    required String nationalId,
    required String password,
  }) async {
    final passwords = await _loadPasswords();
    final stored = passwords[nationalId.trim().toLowerCase()];
    if (stored == null || stored != password) return null;

    final users = await _loadUsers();
    final user = users.firstWhere(
      (u) => u.nationalId.toLowerCase() == nationalId.trim().toLowerCase(),
      orElse: () => throw StateError('Password exists but user missing'),
    );
    currentUser = user;
    return user;
  }

  // ── Prescriptions ──────────────────────────────────────────────────────

  static String _rxKey(String patientId) =>
      'qm_rx_${patientId.trim().toLowerCase()}';

  static String _drxKey(String doctorId) =>
      'qm_drx_${doctorId.trim().toLowerCase()}';

  Future<List<Prescription>> getPrescriptions(String patientId) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_rxKey(patientId));
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => Prescription.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Prescription>> getDoctorPrescriptions(String doctorId) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_drxKey(doctorId));
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => Prescription.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePrescription(Prescription p) async {
    final pList = await getPrescriptions(p.patientId);
    pList.add(p);
    final prefs = await _prefs;
    await prefs.setString(
        _rxKey(p.patientId), jsonEncode(pList.map((x) => x.toJson()).toList()));
    final dList = await getDoctorPrescriptions(p.doctorId);
    dList.add(p);
    await prefs.setString(
        _drxKey(p.doctorId), jsonEncode(dList.map((x) => x.toJson()).toList()));
  }

  Future<bool> markDispensed(String prescriptionId, String patientId) async {
    final list = await getPrescriptions(patientId);
    final idx = list.indexWhere((p) => p.id == prescriptionId);
    if (idx == -1) return false;
    if (list[idx].isDispensed) return false;
    list[idx].isDispensed = true;
    list[idx].dispensedAt = DateTime.now();
    final prefs = await _prefs;
    await prefs.setString(
        _rxKey(patientId), jsonEncode(list.map((p) => p.toJson()).toList()));
    // Mirror the dispensed state into the doctor's copy.
    final doctorId = list[idx].doctorId;
    final dList = await getDoctorPrescriptions(doctorId);
    final dIdx = dList.indexWhere((p) => p.id == prescriptionId);
    if (dIdx != -1) {
      dList[dIdx].isDispensed = true;
      dList[dIdx].dispensedAt = list[idx].dispensedAt;
      await prefs.setString(
          _drxKey(doctorId), jsonEncode(dList.map((p) => p.toJson()).toList()));
    }
    if (currentUser?.role == 'Pharmacist') {
      await removeFromPharmPending(currentUser!.nationalId, prescriptionId);
    }
    return true;
  }

  // ── Pharmacist pending queue ───────────────────────────────────────────

  static String _pharmKey(String pharmacistId) =>
      'qm_pharm_${pharmacistId.trim().toLowerCase()}';

  Future<List<Prescription>> getPharmPending(String pharmacistId) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_pharmKey(pharmacistId));
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => Prescription.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addToPharmPending(
      String pharmacistId, List<Prescription> prescriptions) async {
    final existing = await getPharmPending(pharmacistId);
    final existingIds = existing.map((p) => p.id).toSet();
    for (final p in prescriptions.where((x) => !x.isDispensed)) {
      if (!existingIds.contains(p.id)) existing.add(p);
    }
    final prefs = await _prefs;
    await prefs.setString(_pharmKey(pharmacistId),
        jsonEncode(existing.map((p) => p.toJson()).toList()));
  }

  Future<void> removeFromPharmPending(
      String pharmacistId, String prescriptionId) async {
    final list = await getPharmPending(pharmacistId);
    list.removeWhere((p) => p.id == prescriptionId);
    final prefs = await _prefs;
    await prefs.setString(_pharmKey(pharmacistId),
        jsonEncode(list.map((p) => p.toJson()).toList()));
  }

  Future<AuthUser?> findUser(String nationalId) async {
    final users = await _loadUsers();
    try {
      return users.firstWhere(
        (u) => u.nationalId.toLowerCase() == nationalId.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  void signOut() => currentUser = null;
}
