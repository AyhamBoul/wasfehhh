import 'package:flutter/material.dart';
import 'auth_service.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  String selectedRole = 'Patient';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nationalIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    nationalIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String _routeForRole(String role) {
    switch (role) {
      case 'Doctor':
        return '/doctor-dashboard';
      case 'Pharmacist':
        return '/pharmacist-portal';
      case 'Patient':
      default:
        return '/patient-dashboard';
    }
  }

  String _extractFirstName(String fullName) {
    final List<String> pieces = fullName.trim().split(RegExp(r'\s+'));
    return pieces.isEmpty || pieces.first.isEmpty ? 'User' : pieces.first;
  }

  bool _isLoading = false;

  Future<void> _createAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final error = await AuthService().register(
      nationalId: nationalIdController.text.trim(),
      password: passwordController.text,
      fullName: fullNameController.text.trim(),
      email: emailController.text.trim(),
      role: selectedRole,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final String firstName = _extractFirstName(fullNameController.text.trim());
    Navigator.pushReplacementNamed(
      context,
      _routeForRole(selectedRole),
      arguments: {'firstName': firstName},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Account"),
        backgroundColor: Color(0xFFFFFFFF), // White color for the app bar
        foregroundColor: Color(0xFF000000), // Black color for the text
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Join Wasfeh health ecosystem",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
              TextFormField(
                controller: fullNameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full Name is required';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "Full Name",
                  labelStyle: TextStyle(color: Color(0xFF2C3E50)), // Dark text color for labels
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFBDC3C7)), // Border color
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2980B9)), // Focused border color (blue)
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                validator: (value) {
                  final String email = value?.trim() ?? '';
                  if (email.isEmpty) {
                    return 'Email Address is required';
                  }
                  if (!email.contains('@')) {
                    return "Email must contain '@'";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "Email Address",
                  labelStyle: TextStyle(color: Color(0xFF2C3E50)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFBDC3C7)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2980B9)),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: nationalIdController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'National ID is required';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "National ID",
                  labelStyle: TextStyle(color: Color(0xFF2C3E50)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFBDC3C7)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2980B9)),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(color: Color(0xFF2C3E50)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFBDC3C7)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2980B9)),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text("Select Your Role"),
              SizedBox(height: 10),
              Row(
                children: [
                  RoleButton(
                    label: 'Patient',
                    isSelected: selectedRole == 'Patient',
                    onPressed: () {
                      setState(() {
                        selectedRole = 'Patient';
                      });
                    },
                  ),
                  SizedBox(width: 10),
                  RoleButton(
                    label: 'Doctor',
                    isSelected: selectedRole == 'Doctor',
                    onPressed: () {
                      setState(() {
                        selectedRole = 'Doctor';
                      });
                    },
                  ),
                  SizedBox(width: 10),
                  RoleButton(
                    label: 'Pharmacist',
                    isSelected: selectedRole == 'Pharmacist',
                    onPressed: () {
                      setState(() {
                        selectedRole = 'Pharmacist';
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2980B9),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    textStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Create Account",
                          style: TextStyle(color: Colors.white)),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? "),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signin');
                    },
                    child: Text("Sign In", style: TextStyle(color: Color(0xFF2980B9))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const RoleButton({super.key, 
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF2980B9) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Color(0xFF2980B9)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Color(0xFF2980B9),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}  