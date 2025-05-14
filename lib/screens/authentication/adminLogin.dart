import 'package:ephysicsapp/globals/colors.dart';
import 'package:ephysicsapp/screens/users/studentLogin.dart';
import 'package:ephysicsapp/services/authentication.dart';
import 'package:ephysicsapp/widgets/generalWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_segmented_control/material_segmented_control.dart';

class AdminLogin extends StatefulWidget {
  AdminLogin({Key? key}) : super(key: key);

  @override
  _AdminLoginState createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  int _currentSelection = 0; // Default to 0 for StudentLogRegister

  Map<int, Widget> _children = {
    0: Text('Student'),
    1: Text('Admin'),
  };

  // Widget to display the current form
  Widget _currentWidget = StudentLogin();

  // Function to switch between Student and Admin forms
  void _switchPage(int index) {
    setState(() {
      _currentSelection = index;
      if (index == 0) {
        _currentWidget = StudentLogin(); // Show student login/register page
      } else if (index == 1) {
        _currentWidget = AdminLoginForm(); // Show admin login form
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color1,
      appBar: themeAppBar("Login"),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height / 40,
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                child: MaterialSegmentedControl(
                  children: _children,
                  selectionIndex: _currentSelection,
                  borderColor: Colors.black,
                  selectedColor: color5,
                  unselectedColor: Colors.white,
                  selectedTextStyle: TextStyle(
                      color: color1, fontWeight: FontWeight.bold, fontSize: 16),
                  unselectedTextStyle: TextStyle(
                      color: color5, fontWeight: FontWeight.bold, fontSize: 16),
                  borderWidth: 2,
                  borderRadius: 32.0,
                  onSegmentTapped: (index) {
                    _switchPage(
                        index as int); // Call the function to switch form
                  },
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height / 40,
              ),
              _currentWidget, // Display the current form based on selection
            ],
          ),
        ),
      ),
    );
  }
}

class AdminLoginForm extends StatefulWidget {
  const AdminLoginForm({Key? key}) : super(key: key);

  @override
  State<AdminLoginForm> createState() => _AdminLoginFormState();
}

class _AdminLoginFormState extends State<AdminLoginForm> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKeyValue = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool isLoading = false;
  bool isGoogleLoading = false;

  Future<void> checkValidation() async {
    if (_formKeyValue.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });
      await login(emailController.text, passwordController.text, context);
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Form(
        key: _formKeyValue,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: MediaQuery.of(context).size.height / 30),
            Text(
              'Admin Login',
              style: GoogleFonts.merriweather(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: color5),
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: emailController,
              validator: (value) => value!.isEmpty ? "Enter Email" : null,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Enter Email",
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(width: 2.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: passwordController,
              validator: (value) => value!.isEmpty ? "Enter Password" : null,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: "Enter Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(width: 2.0),
                ),
              ),
            ),
            const SizedBox(height: 30),
            isLoading
                ? SpinKitRotatingCircle()
                : Container(
                    height: MediaQuery.of(context).size.height / 16,
                    width: MediaQuery.of(context).size.width - 20.0,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15), // Same border radius
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                        backgroundColor: color5,
                      ),
                      onPressed: () {
                        checkValidation();
                      },
                      child: Text(
                        'Login',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: color1,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
            SizedBox(height: MediaQuery.of(context).size.height / 50),
            isGoogleLoading
                ? SpinKitRotatingCircle()
                : Container(
                    height: MediaQuery.of(context).size.height / 16,
                    width: MediaQuery.of(context).size.width - 20.0,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white30,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        elevation: 2,
                      ),
                      onPressed: () async {
                        setState(() {
                          isGoogleLoading = true; // Start loading
                        });
                        await adminLoginWithGoogle(context);
                        setState(() {
                          isGoogleLoading = false; // Stop loading
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/google_icon.png',
                            width: 30,
                            height: 30,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Sign in with Google',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
