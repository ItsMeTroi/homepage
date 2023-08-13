import 'package:captsone_ui/Screens/authentication/loginScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:captsone_ui/utils/showSnackBar.dart';

class EmailPasswordSignup extends StatefulWidget {
  static String routeName = '/signup-email-password';
  const EmailPasswordSignup({Key? key}) : super(key: key);

  @override
  _EmailPasswordSignupState createState() => _EmailPasswordSignupState();
}

class _EmailPasswordSignupState extends State<EmailPasswordSignup> {
  final firstnameController = TextEditingController();
  final lastnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final usernameController = TextEditingController();

  void signUpUser() async {
    try {
      String? result = await signUpWithEmail(
        email: emailController.text,
        password: passwordController.text,
        username: usernameController.text,
        firstname: firstnameController.text,
        lastname: lastnameController.text,
      );

      if (result == null) {
        // Registration successful
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => EmailPasswordLogin()),
        );
      } else {
        // Registration failed
        showSnackBar(context, 'Registration failed: $result');
      }
    } catch (e) {
      print('Error occurred while signing up: $e');
      showSnackBar(
          context, 'An error occurred while signing up. Please try again.');
    }
  }

  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String firstname,
    required String lastname,
  }) async {
    final response = await http.post(
      Uri.parse("http://192.168.1.5:8000/register/"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'email': email,
        'password': password,
        'confirm_password': password,
        'firstname': firstname,
        'lastname': lastname,
      }),
    );

    if (response.statusCode == 200) {
      return null;
    } else {
      return jsonDecode(response.body)['error_message'];
    }
  }

  TextField buildTextField({
    required String hintText,
    required TextEditingController controller,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true, // added for a fill color
        fillColor: Colors.grey[200], // light grey fill color
        border: const OutlineInputBorder(), // added border
      ),
      obscureText: obscureText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final confirmController = TextEditingController();

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: screenWidth * 0.05),

                      Image.asset(
                        'assets/blackLogo.png',
                        width: screenWidth * 0.5,
                        height: screenWidth * 0.5,
                      ),
                      const SizedBox(height: 25),

                      // Firstname TextField
                      buildTextField(
                        hintText: 'First name',
                        controller: firstnameController,
                      ),

                      const SizedBox(height: 20),

                      // Lastname TextField
                      buildTextField(
                        hintText: 'Last name',
                        controller: lastnameController,
                      ),

                      const SizedBox(height: 20),

                      // Username TextField
                      buildTextField(
                        hintText: 'Username',
                        controller: usernameController,
                      ),

                      const SizedBox(height: 20),

                      // Email TextField
                      buildTextField(
                        hintText: 'Email',
                        controller: emailController,
                      ),

                      const SizedBox(height: 20),

                      // Password TextField
                      buildTextField(
                        hintText: 'Password',
                        controller: passwordController,
                        obscureText: true,
                      ),

                      const SizedBox(height: 20),

                      // Confirm Password TextField
                      buildTextField(
                        hintText: 'Confirm Password',
                        controller: confirmController,
                        obscureText: true,
                      ),

                      const SizedBox(height: 40),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary:
                              Colors.black, // changing button color to black
                        ),
                        onPressed: () {
                          if (passwordController.text ==
                              confirmController.text) {
                            signUpUser();
                          } else {
                            showSnackBar(context, "Passwords do not match.");
                          }
                        },
                        child: Text('Sign Up'),
                      ),

                      const SizedBox(height: 50),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: Colors.black,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EmailPasswordLogin(),
                                ),
                              );
                            },
                            child: Text('Sign In'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
