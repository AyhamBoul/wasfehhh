import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'firebase_options.dart';
import 'createaccount.dart';
import 'profile_page.dart';
import 'signin.dart';
import 'splash_page.dart';
import 'doctor_messages_page.dart';
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
import 'guest_home_page.dart';
import 'admin_dashboard_page.dart';
import 'prescription_view_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) await NotificationService().init();
  await AuthService().seedDemoAccounts();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wasfeh',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const SplashPage(),
      routes: {
        '/splash': (context) => const SplashPage(),
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
        '/guest-home': (context) => const GuestHomePage(),
        '/admin-dashboard': (context) => const AdminDashboardPage(),
        '/rx': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<dynamic, dynamic>?;
          return PrescriptionViewPage(
              qrData: args?['d'] as String? ?? '');
        },
        '/profile': (context) => const ProfilePage(),
        '/doctor-messages': (context) => DoctorMessagesPage(
              firstName: (ModalRoute.of(context)?.settings.arguments
                          as Map<dynamic, dynamic>?)?['firstName']
                      as String? ??
                  AuthService().currentUser?.firstName ??
                  'Doctor',
            ),
      },
    );
  }
}
