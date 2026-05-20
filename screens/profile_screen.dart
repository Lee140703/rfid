import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  bool isUploading = false;
  final Color appColor = const Color(0xFF1E63B5);

  /// VIEW IMAGE
  void _viewImage(Uint8List? imageBytes) {
    if (imageBytes == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body:
              Center(child: InteractiveViewer(child: Image.memory(imageBytes))),
        ),
      ),
    );
  }

  /// PICK IMAGE
  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source);
    if (file == null) return;

    setState(() => isUploading = true);

    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .set({'profileImage': base64Image}, SetOptions(merge: true));

    setState(() => isUploading = false);
  }

  /// DELETE IMAGE
  Future<void> _deleteImage() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({'profileImage': FieldValue.delete()});
  }

  /// EDIT FIELD
  void _editField(String field, String value) {
    final controller = TextEditingController(text: value);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit ${field[0].toUpperCase()}${field.substring(1)}"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: appColor),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .update({field: controller.text.trim()});
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// BOTTOM SHEET
  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Text("Profile Picture",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: appColor)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sheetBtn(Icons.camera, "Camera",
                    () => _pickImage(ImageSource.camera)),
                _sheetBtn(Icons.photo, "Gallery",
                    () => _pickImage(ImageSource.gallery)),
                _sheetBtn(Icons.delete, "Remove", _deleteImage,
                    color: Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetBtn(IconData icon, String text, VoidCallback onTap,
      {Color? color}) {
    final c = color ?? appColor;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: c.withOpacity(0.1),
            child: Icon(icon, color: c),
          ),
          const SizedBox(height: 6),
          Text(text, style: TextStyle(color: c)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: appColor,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          final name = data['name'] ?? 'User';
          final email = data['email'] ?? user!.email ?? '';
          final role = data['role'] ?? 'User';
          final department = data['department'] ?? 'N/A';
          final image = data['profileImage'] ?? '';

          final isAdmin = role.toString().toLowerCase().contains("admin");

          final accessLevel = isAdmin ? "Full Access" : "Limited Access";

          Uint8List? bytes;
          if (image.isNotEmpty) {
            bytes = base64Decode(image);
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2027), Color(0xFF203A43)],
              ),
            ),
            child: Center(
              child: Container(
                width: 360,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      /// PROFILE IMAGE
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _viewImage(bytes),
                            child: CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage:
                                  bytes != null ? MemoryImage(bytes) : null,
                              child: bytes == null
                                  ? Icon(
                                      isAdmin
                                          ? Icons.admin_panel_settings
                                          : Icons.person,
                                      size: 50,
                                      color: Colors.blue,
                                    )
                                  : null,
                            ),
                          ),
                          if (isUploading) const CircularProgressIndicator(),
                        ],
                      ),

                      const SizedBox(height: 10),

                      GestureDetector(
                        onTap: _showBottomSheet,
                        child: Text("Edit", style: TextStyle(color: appColor)),
                      ),

                      const SizedBox(height: 20),

                      /// INFO TILES ONLY
                      _tile(Icons.person, "Name", name,
                          () => _editField("name", name)),
                      _tile(Icons.email, "Email", email),
                      _tile(Icons.badge, "Role", role),
                      _tile(Icons.lock, "Access Level", accessLevel),
                      _tile(Icons.apartment, "Department", department,
                          () => _editField("department", department)),

                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size.fromHeight(45),
                        ),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/login', (route) => false);
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tile(IconData icon, String title, String value,
      [VoidCallback? onEdit]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blue.shade100,
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            )
        ],
      ),
    );
  }
}
