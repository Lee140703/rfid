import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_dashboard_screen.dart';

class AssetRequestScreen extends StatefulWidget {
  const AssetRequestScreen({super.key});

  @override
  State<AssetRequestScreen> createState() => _AssetRequestScreenState();
}

class _AssetRequestScreenState extends State<AssetRequestScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController assetNameController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  String? selectedAssetType;
  String? selectedDepartment;

  bool _isSubmitting = false;

  final List<String> assetTypes = [
    'Laptop',
    'Printer',
    'Scanner',
    'Projector',
  ];

  final List<String> departments = ['MCA', 'M.Sc', 'MBA', 'Data Science'];

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  static const Color primaryBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    assetNameController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  void showSnackBar(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> submitRequest() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    if (selectedAssetType == null || selectedDepartment == null) {
      showSnackBar('Please select all dropdown fields');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showSnackBar('User not logged in');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('asset_requests').add({
        'assetName': assetNameController.text.trim(),
        'assetType': selectedAssetType,
        'department': selectedDepartment,
        'purpose': reasonController.text.trim(),
        'requestedBy': user.uid,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });

      _formKey.currentState!.reset();
      assetNameController.clear();
      reasonController.clear();

      setState(() {
        selectedAssetType = null;
        selectedDepartment = null;
      });

      showSnackBar(
        'Request submitted successfully!',
        color: Colors.green,
      );
    } catch (e) {
      showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  // ✅ UPDATED TEXT FIELD WITH ICON
  Widget roundedTextField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    int maxLines = 1,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          prefixIcon: icon != null
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, color: Colors.grey.shade700),
                )
              : null,
        ),
      ),
    );
  }

  Widget roundedDropdown(
    String hint,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String? validateAssetName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Asset name is required';
    }
    if (value.length < 3) {
      return 'Minimum 3 characters required';
    }
    return null;
  }

  String? validatePurpose(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Purpose is required';
    }
    if (value.length < 5) {
      return 'Minimum 5 characters required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryBlue,
        centerTitle: true,
        title: const Text(
          'Asset Request',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Container(
                    width: 380,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 25,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Column(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 70, color: Colors.red),
                              SizedBox(height: 10),
                              Text(
                                'Asset Request',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        fieldLabel('Asset Name'),
                        roundedTextField(
                          controller: assetNameController,
                          hint: 'Enter asset name',
                          validator: validateAssetName,
                          icon: Icons.qr_code, // ✅ added
                        ),
                        const SizedBox(height: 16),
                        fieldLabel('Asset Type'),
                        roundedDropdown(
                          'Select asset type',
                          assetTypes,
                          selectedAssetType,
                          (val) => setState(() => selectedAssetType = val),
                        ),
                        const SizedBox(height: 16),
                        fieldLabel('Purpose'),
                        roundedTextField(
                          controller: reasonController,
                          hint: 'Enter purpose',
                          validator: validatePurpose,
                          maxLines: 3,
                          icon: Icons.edit, // ✅ added
                        ),
                        const SizedBox(height: 16),
                        fieldLabel('Department'),
                        roundedDropdown(
                          'Select department',
                          departments,
                          selectedDepartment,
                          (val) => setState(() => selectedDepartment = val),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _isSubmitting ? null : submitRequest,
                            child: _isSubmitting
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'SUBMIT REQUEST',
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
          ),
        ),
      ),
    );
  }
}
