import 'package:flutter/material.dart';
import 'createaccount.dart';
import 'signin.dart';
import 'PatientDashboardPage.dart';
import 'DoctorDashboardPage .dart';
import 'Pharmacist.dart';
import 'NewPrescriptionPage.dart';
import 'MedicationSchedulePage .dart';
import 'map.dart';
import 'notification_service.dart';
import 'prescription_scanner_page.dart';
import 'auth_service.dart';
import 'patient_records_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await AuthService().seedDemoAccounts();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wasfeh',
      theme: ThemeData(
        primarySwatch: Colors.blue, // اللون الرئيسي للتطبيق
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CreateAccountPage(),
      routes: {
        '/create-account': (context) => const CreateAccountPage(),
        '/signin': (context) => const SignInPage(),
        '/patient-dashboard': (context) => const PatientDashboardPage(),
        '/doctor-dashboard': (context) => const DoctorDashboardPage(),
        '/pharmacist-portal': (context) => const PharmacistPortalPage(),
        '/new-prescription': (context) => const NewPrescriptionPage(),
        '/medication-schedule': (context) => const MedicationSchedulePage(),
        '/pharmacy': (context) => const PharmacyPage(),
        '/prescription-scanner': (context) => const PrescriptionScannerPage(),
        '/patient-records': (context) => const PatientRecordsPage(),
      },
    );
  }
}
