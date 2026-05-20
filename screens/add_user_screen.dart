import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();

  String fullName = '';
  String email = '';
  String password = '';
  String role = 'User';
  String department = '';

  bool isLoading = false;

  final List<String> departments = ['IT', 'HR', 'Finance', 'Operations'];

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF4F6F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    );
  }

  /// =============================
  /// 🔥 BACKEND FUNCTION
  /// =============================
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    try {
      /// 1️⃣ Create user in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      /// 2️⃣ Save user profile in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': fullName,
        'email': email,
        'role': role, // ALWAYS User
        'department': department,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      /// 3️⃣ Success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User Registered Successfully')),
      );

      /// 4️⃣ Reset form
      _formKey.currentState!.reset();
      setState(() => department = '');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E2A36),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F6FD6),
        title: const Text('Add User'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Add User Account',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text('Full Name'),
                  const SizedBox(height: 6),
                  TextFormField(
                    decoration: _inputStyle('Enter full name'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter full name' : null,
                    onSaved: (v) => fullName = v!,
                  ),
                  const SizedBox(height: 16),
                  const Text('Email'),
                  const SizedBox(height: 6),
                  TextFormField(
                    decoration: _inputStyle('Enter email'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter email' : null,
                    onSaved: (v) => email = v!,
                  ),
                  const SizedBox(height: 16),
                  const Text('Password'),
                  const SizedBox(height: 6),
                  TextFormField(
                    obscureText: true,
                    decoration: _inputStyle('Enter password'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter password' : null,
                    onSaved: (v) => password = v!,
                  ),
                  const SizedBox(height: 16),
                  const Text('Role'),
                  const SizedBox(height: 6),
                  TextFormField(
                    initialValue: 'User',
                    enabled: false,
                    decoration: _inputStyle('User'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Department'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    decoration: _inputStyle('Select department'),
                    value: department.isEmpty ? null : department,
                    items: departments
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => department = v!),
                    validator: (v) =>
                        v == null ? 'Please select department' : null,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F6FD6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: isLoading ? null : _registerUser,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'SUBMIT',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
    );
  }
}
