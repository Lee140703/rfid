import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  bool isUploading = false;

  final Color appColor = const Color(0xFF1E63B5);

  void _viewProfileImage(Uint8List? imageBytes) {
    if (imageBytes == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: Center(
            child: InteractiveViewer(child: Image.memory(imageBytes)),
          ),
        ),
      ),
    );
  }

  /// BEAUTIFUL BOTTOM SHEET
  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// drag handle
              Container(
                width: 45,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              Text(
                "Profile Picture",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: appColor,
                ),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _bottomButton(
                    icon: Icons.camera_alt,
                    label: "Camera",
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadImage(ImageSource.camera);
                    },
                  ),
                  _bottomButton(
                    icon: Icons.photo,
                    label: "Gallery",
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadImage(ImageSource.gallery);
                    },
                  ),
                  _bottomButton(
                    icon: Icons.delete,
                    label: "Remove",
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _deleteProfileImage();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  /// BEAUTIFUL BUTTON
  Widget _bottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final buttonColor = color ?? appColor;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: buttonColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: buttonColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: buttonColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() => isUploading = true);

      Uint8List imageBytes = await pickedFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .set({'profileImage': base64Image}, SetOptions(merge: true));

      setState(() => isUploading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile image updated")),
      );
    } catch (e) {
      setState(() => isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }

  Future<void> _deleteProfileImage() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .update({'profileImage': FieldValue.delete()});
  }

  void _editField(String field, String currentValue) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit $field"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: field),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: appColor),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser!.uid)
                  .update({field.toLowerCase(): controller.text.trim()});
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E63B5),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          final name = userData['name'] ?? "User";
          final email = userData['email'] ?? currentUser!.email ?? "";
          final role = userData['role'] ?? "User";
          final department = userData['department'] ?? "Not Assigned";
          final profileImage = userData['profileImage'] ?? "";

          final accessLevel =
              role == "Admin" ? "Full Access" : "Limited Access";

          Uint8List? imageBytes;
          if (profileImage.isNotEmpty) {
            imageBytes = base64Decode(profileImage);
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2027), Color(0xFF203A43)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
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
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _viewProfileImage(imageBytes),
                            child: CircleAvatar(
                              radius: 55,
                              backgroundColor: const Color(0xFFE3F2FD),
                              backgroundImage: imageBytes != null
                                  ? MemoryImage(imageBytes)
                                  : null,
                              child: imageBytes == null
                                  ? const Icon(Icons.person,
                                      size: 55, color: Color(0xFF1565C0))
                                  : null,
                            ),
                          ),
                          if (isUploading) const CircularProgressIndicator(),
                        ],
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: const Text(
                          "Edit",
                          style: TextStyle(
                            color: Color(0xFF1E63B5),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _infoTile(Icons.person, "Name", name,
                          onEdit: () => _editField("Name", name)),
                      _infoTile(Icons.email, "Email", email),
                      _infoTile(Icons.badge, "Role", role),
                      _infoTile(Icons.lock, "Access Level", accessLevel),
                      _infoTile(Icons.apartment, "Department", department,
                          onEdit: () => _editField("Department", department)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size.fromHeight(45),
                        ),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
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

  Widget _infoTile(IconData icon, String title, String value,
      {VoidCallback? onEdit}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: onEdit,
            )
        ],
      ),
    );
  }
}
