import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_dashboard_screen.dart';
import '../services/activity_service.dart';

class ReportAssetScreen extends StatefulWidget {
  const ReportAssetScreen({super.key});

  @override
  State<ReportAssetScreen> createState() => _ReportAssetScreenState();
}

class _ReportAssetScreenState extends State<ReportAssetScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController assetIdController = TextEditingController();
  final TextEditingController issueController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool isSubmitting = false;
  bool showSuccess = false;

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

    // 🔠 Auto uppercase
    assetIdController.addListener(() {
      final text = assetIdController.text;
      final upper = text.toUpperCase();
      if (text != upper) {
        assetIdController.value = assetIdController.value.copyWith(
          text: upper,
          selection: TextSelection.collapsed(offset: upper.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    assetIdController.dispose();
    issueController.dispose();
    super.dispose();
  }

  // 🔁 Snackbar
  void showSnack(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showSnack('User not logged in. Please login again.');
      return;
    }

    setState(() {
      isSubmitting = true;
      showSuccess = false;
    });

    try {
      final assetId = assetIdController.text.trim();

      final assetRef =
          FirebaseFirestore.instance.collection('assets').doc(assetId);
      final assetSnapshot = await assetRef.get();

      if (!assetSnapshot.exists) {
        showSnack('This Asset ID does not exist in the system.');
        return;
      }

      final activeReport = await FirebaseFirestore.instance
          .collection('reported_assets')
          .where('assetId', isEqualTo: assetId)
          .where('status', isEqualTo: 'Under Repair')
          .limit(1)
          .get();

      if (activeReport.docs.isNotEmpty) {
        showSnack('This asset is already under repair.');
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final String userName = userDoc.data()?['name'] ?? 'Unknown User';

      await FirebaseFirestore.instance.collection('reported_assets').add({
        'assetId': assetId,
        'issue': issueController.text.trim(),
        'status': 'Under Repair',
        'reportedBy': userName,
        'reportedByUid': user.uid,
        'reportedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('assets')
          .doc(assetId)
          .update({
        'status': 'Under Repair',
        'repairEndDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
      });

      await ActivityService.log(
        title: 'Issue reported for $assetId',
        icon: 'issue',
      );

      assetIdController.clear();
      issueController.clear();

      setState(() {
        showSuccess = true;
      });

      showSnack('Reported successfully!', color: Colors.green);

      // ⏱️ Auto clear success after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            showSuccess = false;
          });
        }
      });
    } catch (e) {
      showSnack('Failed to submit report: $e');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryBlue,
        centerTitle: true,
        title:
            const Text('Report Asset', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserDashboardScreen()),
            );
          },
        ),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: const [
                              Icon(Icons.warning_amber_rounded,
                                  size: 70, color: Colors.red),
                              SizedBox(height: 12),
                              Text('Report Asset Issue',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Text('Asset ID',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: assetIdController,
                          decoration: InputDecoration(
                            hintText: 'Enter Asset ID',
                            prefixIcon: const Icon(Icons.qr_code),
                            filled: true,
                            fillColor: const Color(0xFFF1F3F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Asset ID is required';
                            }
                            if (value.trim().length < 3) {
                              return 'Invalid Asset ID';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        const Text('Issue Description',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: issueController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Describe the issue',
                            prefixIcon: const Icon(Icons.edit),
                            filled: true,
                            fillColor: const Color(0xFFF1F3F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Issue description is required';
                            }
                            if (value.trim().length < 10) {
                              return 'Please provide more details';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isSubmitting ? null : submitReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: isSubmitting
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('SUBMIT REPORT',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
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
