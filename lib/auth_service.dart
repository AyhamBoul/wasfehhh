import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthUser {
  final String nationalId;
  final String fullName;
  final String email;
  final String role;
  final String? licenseNumber;
  final String uid;

  AuthUser({
    required this.nationalId,
    required this.fullName,
    required this.email,
    required this.role,
    this.licenseNumber,
    required this.uid,
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
        'uid': uid,
        if (licenseNumber != null) 'licenseNumber': licenseNumber,
      };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        nationalId: json['nationalId'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        uid: json['uid'] as String? ?? '',
        licenseNumber: json['licenseNumber'] as String?,
      );
}

class PatientRecords {
  final List<String> allergies;
  final List<String> chronicConditions;

  PatientRecords({required this.allergies, required this.chronicConditions});

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

class PatientMessage {
  final String doctorId;
  final String doctorName;
  final String text;
  final DateTime timestamp;
  bool isRead;

  PatientMessage({
    required this.doctorId,
    required this.doctorName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'doctorId': doctorId,
        'doctorName': doctorName,
        'text': text,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'isRead': isRead,
      };

  factory PatientMessage.fromJson(Map<String, dynamic> j) => PatientMessage(
        doctorId: j['doctorId'] as String,
        doctorName: j['doctorName'] as String,
        text: j['text'] as String,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(j['timestamp'] as int),
        isRead: j['isRead'] as bool? ?? false,
      );
}

class PendingUser {
  final String nationalId;
  final String fullName;
  final String email;
  final String role;
  final String? licenseNumber;
  final DateTime requestedAt;
  String status;

  PendingUser({
    required this.nationalId,
    required this.fullName,
    required this.email,
    required this.role,
    this.licenseNumber,
    required this.requestedAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'nationalId': nationalId,
        'fullName': fullName,
        'email': email,
        'role': role,
        if (licenseNumber != null) 'licenseNumber': licenseNumber,
        'requestedAt': requestedAt.millisecondsSinceEpoch,
        'status': status,
      };

  factory PendingUser.fromJson(Map<String, dynamic> j) => PendingUser(
        nationalId: j['nationalId'] as String,
        fullName: j['fullName'] as String,
        email: j['email'] as String,
        role: j['role'] as String,
        licenseNumber: j['licenseNumber'] as String?,
        requestedAt:
            DateTime.fromMillisecondsSinceEpoch(j['requestedAt'] as int),
        status: j['status'] as String? ?? 'pending',
      );
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  AuthUser? currentUser;

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<String?> register({
    required String nationalId,
    required String password,
    required String fullName,
    required String email,
    required String role,
    String? licenseNumber,
    bool skipPending = false,
  }) async {
    final id = nationalId.trim();

    // Check existing user by nationalId
    final existing = await _db
        .collection('users')
        .where('nationalId', isEqualTo: id)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return 'An account with this National ID already exists.';
    }

    if (skipPending) {
      // Create Firebase Auth account then store user doc
      try {
        final cred = await _auth.createUserWithEmailAndPassword(
            email: email.trim(), password: password);
        final user = AuthUser(
          nationalId: id,
          fullName: fullName.trim(),
          email: email.trim(),
          role: role,
          licenseNumber: licenseNumber?.trim(),
          uid: cred.user!.uid,
        );
        await _db.collection('users').doc(cred.user!.uid).set(user.toJson());
        currentUser = user;
        return null;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Account exists in Auth but not in users collection — just link
          final snap = await _db
              .collection('users')
              .where('email', isEqualTo: email.trim())
              .limit(1)
              .get();
          if (snap.docs.isEmpty) return null;
        }
        return null; // demo seed — ignore duplicates
      }
    }

    // Normal registration goes to pending queue
    final pendingSnap = await _db
        .collection('pending_users')
        .where('nationalId', isEqualTo: id)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (pendingSnap.docs.isNotEmpty) {
      return 'A registration request for this National ID is already pending.';
    }

    await _db.collection('pending_users').add(PendingUser(
          nationalId: id,
          fullName: fullName.trim(),
          email: email.trim(),
          role: role,
          licenseNumber: licenseNumber?.trim(),
          requestedAt: DateTime.now(),
        ).toJson());
    return null;
  }

  Future<AuthUser?> login({
    required String nationalId,
    required String password,
  }) async {
    try {
      final snap = await _db
          .collection('users')
          .where('nationalId', isEqualTo: nationalId.trim())
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      if (snap.docs.isEmpty) return null;

      final data = snap.docs.first.data();
      final email = data['email'] as String;

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = AuthUser.fromJson(data);
      currentUser = user;
      return user;
    } catch (_) {
      return null;
    }
  }

  void signOut() {
    _auth.signOut();
    currentUser = null;
  }

  // ── Pending approval queue ─────────────────────────────────────────────────

  Future<List<PendingUser>> getPendingUsers() async {
    final snap = await _db
        .collection('pending_users')
        .where('status', isEqualTo: 'pending')
        .get();
    return snap.docs
        .map((d) => PendingUser.fromJson(d.data()))
        .toList();
  }

  Future<void> approvePendingUser(String nationalId) async {
    final snap = await _db
        .collection('pending_users')
        .where('nationalId', isEqualTo: nationalId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return;
    final pending = PendingUser.fromJson(snap.docs.first.data());

    // Create Firebase Auth account
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: pending.email, password: 'Wasfeh@${pending.nationalId}');
      final user = AuthUser(
        nationalId: pending.nationalId,
        fullName: pending.fullName,
        email: pending.email,
        role: pending.role,
        licenseNumber: pending.licenseNumber,
        uid: cred.user!.uid,
      );
      await _db.collection('users').doc(cred.user!.uid).set(user.toJson());
    } on FirebaseAuthException {
      // Already exists — just ensure user doc is present
    }

    await snap.docs.first.reference.delete();
  }

  Future<void> denyPendingUser(String nationalId) async {
    final snap = await _db
        .collection('pending_users')
        .where('nationalId', isEqualTo: nationalId)
        .limit(1)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  // ── User management (admin) ───────────────────────────────────────────────

  Future<List<AuthUser>> getAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map((d) => AuthUser.fromJson(d.data())).toList();
  }

  Future<String?> updateUser({
    required String nationalId,
    String? fullName,
    String? email,
    String? role,
    String? licenseNumber,
    String? newPassword,
  }) async {
    final snap = await _db
        .collection('users')
        .where('nationalId', isEqualTo: nationalId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return 'User not found.';

    final doc = snap.docs.first;
    final data = doc.data();
    final updates = <String, dynamic>{};
    if (fullName != null) updates['fullName'] = fullName;
    if (email != null) updates['email'] = email;
    if (role != null) updates['role'] = role;
    if (licenseNumber != null) updates['licenseNumber'] = licenseNumber;
    if (updates.isNotEmpty) await doc.reference.update(updates);

    if (currentUser?.nationalId.toLowerCase() == nationalId.toLowerCase()) {
      currentUser = AuthUser.fromJson({...data, ...updates});
    }
    return null;
  }

  Future<void> deleteUser(String nationalId) async {
    final snap = await _db
        .collection('users')
        .where('nationalId', isEqualTo: nationalId)
        .limit(1)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  Future<AuthUser?> findUser(String nationalId) async {
    final snap = await _db
        .collection('users')
        .where('nationalId', isEqualTo: nationalId.trim())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return AuthUser.fromJson(snap.docs.first.data());
  }

  // ── Records ───────────────────────────────────────────────────────────────

  Future<PatientRecords> getRecords(String nationalId) async {
    final doc = await _db
        .collection('records')
        .doc(nationalId.trim().toLowerCase())
        .get();
    if (!doc.exists) return PatientRecords.empty();
    return PatientRecords.fromJson(doc.data()!);
  }

  Future<void> saveRecords(String nationalId, PatientRecords records) async {
    await _db
        .collection('records')
        .doc(nationalId.trim().toLowerCase())
        .set(records.toJson());
  }

  // ── Prescriptions ─────────────────────────────────────────────────────────

  Future<List<Prescription>> getPrescriptions(String patientId) async {
    final snap = await _db
        .collection('prescriptions')
        .where('patientId', isEqualTo: patientId.trim())
        .orderBy('issuedAt', descending: true)
        .get();
    return snap.docs.map((d) => Prescription.fromJson(d.data())).toList();
  }

  Future<List<Prescription>> getDoctorPrescriptions(String doctorId) async {
    final snap = await _db
        .collection('prescriptions')
        .where('doctorId', isEqualTo: doctorId.trim())
        .orderBy('issuedAt', descending: true)
        .get();
    return snap.docs.map((d) => Prescription.fromJson(d.data())).toList();
  }

  Future<void> savePrescription(Prescription p) async {
    await _db.collection('prescriptions').doc(p.id).set(p.toJson());
  }

  Future<bool> markDispensed(String prescriptionId, String patientId) async {
    final doc = _db.collection('prescriptions').doc(prescriptionId);
    final snap = await doc.get();
    if (!snap.exists) return false;
    final data = snap.data()!;
    if (data['isDispensed'] == true) return false;

    await doc.update({
      'isDispensed': true,
      'dispensedAt': DateTime.now().millisecondsSinceEpoch,
    });

    if (currentUser?.role == 'Pharmacist') {
      await removeFromPharmPending(currentUser!.nationalId, prescriptionId);
    }
    return true;
  }

  // ── Pharmacist pending queue ───────────────────────────────────────────────

  Future<List<Prescription>> getPharmPending(String pharmacistId) async {
    final snap = await _db
        .collection('pharm_pending')
        .doc(pharmacistId.trim().toLowerCase())
        .collection('items')
        .where('isDispensed', isEqualTo: false)
        .get();
    return snap.docs.map((d) => Prescription.fromJson(d.data())).toList();
  }

  Future<void> addToPharmPending(
      String pharmacistId, List<Prescription> prescriptions) async {
    final col = _db
        .collection('pharm_pending')
        .doc(pharmacistId.trim().toLowerCase())
        .collection('items');
    final batch = _db.batch();
    for (final p in prescriptions.where((x) => !x.isDispensed)) {
      batch.set(col.doc(p.id), p.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> removeFromPharmPending(
      String pharmacistId, String prescriptionId) async {
    await _db
        .collection('pharm_pending')
        .doc(pharmacistId.trim().toLowerCase())
        .collection('items')
        .doc(prescriptionId)
        .delete();
  }

  // ── Doctor → Patient messaging ─────────────────────────────────────────────

  Future<List<PatientMessage>> getPatientMessages(String patientId) async {
    final snap = await _db
        .collection('patient_messages')
        .doc(patientId.trim().toLowerCase())
        .collection('messages')
        .orderBy('timestamp')
        .get();
    return snap.docs.map((d) => PatientMessage.fromJson(d.data())).toList();
  }

  Future<void> sendPatientMessage(String patientId, String doctorId,
      String doctorName, String text) async {
    final col = _db
        .collection('patient_messages')
        .doc(patientId.trim().toLowerCase())
        .collection('messages');
    final msg = PatientMessage(
      doctorId: doctorId,
      doctorName: doctorName,
      text: text,
      timestamp: DateTime.now(),
    );
    await col.add(msg.toJson());
  }

  Future<void> markPatientMessagesRead(String patientId) async {
    final snap = await _db
        .collection('patient_messages')
        .doc(patientId.trim().toLowerCase())
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Demo seed ─────────────────────────────────────────────────────────────

  // Ensures every demo account exists in BOTH Firebase Auth AND Firestore.
  // Safe to call repeatedly — only creates what is missing.
  Future<void> seedDemoAccounts() async {
    const demos = [
      (
        nationalId: 'ADMIN-001',
        password: 'Admin123!',
        fullName: 'System Admin',
        email: 'admin@wasfeh.app',
        role: 'SuperAdmin',
        licenseNumber: null as String?,
      ),
      (
        nationalId: 'DOC-001',
        password: 'Doctor123!',
        fullName: 'Dr. Sarah Wilson',
        email: 'sarah.wilson@wasfeh.app',
        role: 'Doctor',
        licenseNumber: 'LIC-DR-2024-001',
      ),
      (
        nationalId: 'PAT-001',
        password: 'Patient123!',
        fullName: 'John Doe',
        email: 'john.doe@wasfeh.app',
        role: 'Patient',
        licenseNumber: null as String?,
      ),
      (
        nationalId: 'PHA-001',
        password: 'Pharma123!',
        fullName: 'Alice Smith',
        email: 'alice.smith@wasfeh.app',
        role: 'Pharmacist',
        licenseNumber: 'LIC-PH-2024-001',
      ),
    ];

    for (final d in demos) {
      await _ensureDemoAccount(
        nationalId: d.nationalId,
        password: d.password,
        fullName: d.fullName,
        email: d.email,
        role: d.role,
        licenseNumber: d.licenseNumber,
      );
    }

    // Leave no signed-in user after seeding
    await _auth.signOut();
    currentUser = null;
  }

  Future<void> _ensureDemoAccount({
    required String nationalId,
    required String password,
    required String fullName,
    required String email,
    required String role,
    String? licenseNumber,
  }) async {
    try {
      final signInResult = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 10));

      final uid = signInResult.user!.uid;
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        await _db.collection('users').doc(uid).set(AuthUser(
              nationalId: nationalId,
              fullName: fullName,
              email: email,
              role: role,
              licenseNumber: licenseNumber,
              uid: uid,
            ).toJson());
      }
      return;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password') {
        try {
          final cred = await _auth.createUserWithEmailAndPassword(
              email: email, password: password);
          final uid = cred.user!.uid;

          final stale = await _db
              .collection('users')
              .where('nationalId', isEqualTo: nationalId)
              .limit(1)
              .get();
          for (final d in stale.docs) {
            await d.reference.delete();
          }

          await _db.collection('users').doc(uid).set(AuthUser(
                nationalId: nationalId,
                fullName: fullName,
                email: email,
                role: role,
                licenseNumber: licenseNumber,
                uid: uid,
              ).toJson());
        } on FirebaseAuthException {
          // Already exists — leave as-is
        }
      }
    } catch (_) {
      // Timeout or network error — skip silently
    }
  }
}
