import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard_screen.dart';
import 'user_dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _loading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  final Color primaryBlue = const Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _loadRememberedUser();
  }

  /// ================= LOAD REMEMBERED USER =================
  Future<void> _loadRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();

    final savedEmail = prefs.getString('remember_email');
    final remember = prefs.getBool('remember_me') ?? false;

    print("Loaded Remember Me: $remember");
    print("Saved Email: $savedEmail");

    if (remember && savedEmail != null) {
      emailController.text = savedEmail;
      setState(() => _rememberMe = true);
    }
  }

  /// ================= HANDLE REMEMBER ME =================
  Future<void> _handleRememberMe() async {
    final prefs = await SharedPreferences.getInstance();

    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('remember_email', emailController.text.trim());

      print("Remember Me SAVED");
    } else {
      await prefs.setBool('remember_me', false);
      await prefs.remove('remember_email');

      print("Remember Me REMOVED");
    }
  }

  /// ================= LOGIN =================
  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      print("Starting login...");

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      print("Login successful");

      await _afterLogin();
    } on FirebaseAuthException catch (e) {
      print("Login Error: ${e.code} - ${e.message}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Login failed")),
      );
    } catch (e) {
      print("Login Exception: $e");
    }

    setState(() => _loading = false);
  }

  /// ================= AFTER LOGIN =================
  Future<void> _afterLogin() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("User is null after login");
      return;
    }

    await _handleRememberMe();

    try {
      await FirebaseMessaging.instance.requestPermission();

      String? token = await FirebaseMessaging.instance.getToken();

      print("FCM TOKEN: $token");

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'fcmToken': token ?? "",
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = doc.data()?['role']?.toString().toLowerCase();

      print("USER ROLE: $role");

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
        );
      }
    } catch (e) {
      print("After Login Error: $e");
    }
  }

  /// ================= FORGOT PASSWORD =================
  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();

    print("FORGOT PASSWORD EMAIL: $email");

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter your email first")),
      );
      return;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid email")),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      print("SUCCESS: Reset email sent");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reset link sent! Check Spam/Inbox"),
        ),
      );
    } on FirebaseAuthException catch (e) {
      print("ERROR CODE: ${e.code}");
      print("ERROR MESSAGE: ${e.message}");

      String message = "Something went wrong";

      if (e.code == 'user-not-found') {
        message = "No user found with this email";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email format";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      print("Forgot Password Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/bg.jpeg",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width:
                        MediaQuery.of(context).size.width, // ✅ responsive width
                    constraints:
                        const BoxConstraints(maxWidth: 370), // ✅ keeps design
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 35),
                          _buildInputLabel("Email"),
                          _buildTextField(
                            controller: emailController,
                            hint: "Enter your email",
                            icon: Icons.email_outlined,
                            isEmail: true,
                          ),
                          const SizedBox(height: 20),
                          _buildInputLabel("Password"),
                          _buildTextField(
                            controller: passwordController,
                            hint: "Enter your password",
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min, // ✅ important
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    activeColor: primaryBlue,
                                    onChanged: (val) async {
                                      setState(
                                          () => _rememberMe = val ?? false);
                                      await _handleRememberMe();
                                    },
                                  ),
                                  const Text(
                                    "Remember me",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11, // ✅ reduced size
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: _forgotPassword,
                                style: TextButton.styleFrom(
                                  padding:
                                      EdgeInsets.zero, // ✅ reduces extra space
                                  minimumSize: const Size(
                                      0, 0), // ✅ removes default size
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  "Forgot password?",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10, // ✅ reduced size
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _loading ? null : login,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primaryBlue, Colors.blueAccent],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: _loading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : const Text(
                                          "LOGIN",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: "Don't have an account? ",
                                  style: const TextStyle(color: Colors.white),
                                  children: [
                                    TextSpan(
                                      text: "Signup",
                                      style: TextStyle(
                                        color: primaryBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isEmail = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "This field is required";
        }

        if (isEmail && !value.contains('@')) {
          return "Enter valid email";
        }

        if (isPassword && value.length < 6) {
          return "Minimum 6 characters required";
        }

        return null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
