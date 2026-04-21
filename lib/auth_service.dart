import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final String nationalId;
  final String fullName;
  final String email;
  final String role;

  AuthUser({
    required this.nationalId,
    required this.fullName,
    required this.email,
    required this.role,
  });

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'User' : parts.first;
  }

  Map<String, String> toJson() => {
        'nationalId': nationalId,
        'fullName': fullName,
        'email': email,
        'role': role,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        nationalId: json['nationalId'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
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
      ),
      (
        nationalId: 'PAT-001',
        password: 'Patient123',
        fullName: 'John Doe',
        email: 'john.doe@quickmedi.com',
        role: 'Patient',
      ),
      (
        nationalId: 'PHA-001',
        password: 'Pharma123',
        fullName: 'Alice Smith',
        email: 'alice.smith@quickmedi.com',
        role: 'Pharmacist',
      ),
    ];

    for (final d in demos) {
      await register(
        nationalId: d.nationalId,
        password: d.password,
        fullName: d.fullName,
        email: d.email,
        role: d.role,
      );
      // register() silently does nothing if the ID already exists
    }
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

  void signOut() => currentUser = null;
}
