import 'package:chamka_yerng/screens/forgot_password_screen.dart';
import 'package:chamka_yerng/screens/register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'home_page.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginPage({super.key});

  void login(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyHomePage(title: AppLocalizations.of(context)!.buttonToday)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize
                .min, // Ensures the Column takes minimum space vertically
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/Logo.png', height: 75),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.loginAccount,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff8CA37B),
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.email,
                  filled: true,
                  fillColor: Colors.lightGreen[100], // Light green background
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12.0), // Rounded corners
                    borderSide:
                        BorderSide.none, // No underline when not focused
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12.0), // Rounded corners
                    borderSide: BorderSide(
                      color: Colors.green, // Green border when focused
                      width: 2.0,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: Colors.green[700], // Label color
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                  color: Colors.green[800], // Text color
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.password,
                  filled: true,
                  fillColor: Colors.lightGreen[100],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: Colors.green,
                      width: 2.0,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: Colors.green[700], // Label color
                  ),
                ),
                style: TextStyle(
                  color: Colors.green[800], // Text color
                ),
              ),

              // Forgot Password Button aligned to the left
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ForgotPasswordPage()),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.forgotPassword,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8CA37B),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Ensures the Column takes minimum space vertically
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => login(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF88C988), // Green background
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12.0), // Rounded corners
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.login,
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // White text color for contrast
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10), // Add spacing between the buttons
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterPage()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF88C988), // Green background
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12.0), // Rounded corners
                        ),
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.register,
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // White text color for contrast
                        ),
                      ),
                    ),
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
