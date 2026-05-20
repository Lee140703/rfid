import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'rfid_scan_screen.dart';
import 'search_asset_screen.dart';
import 'report_asset_screen.dart';
import 'asset_request_screen.dart';
import 'user_profile_screen.dart';
import 'login_screen.dart';
import 'notification_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  static const Color primaryBlue = Color(0xFF1565C0);

  int _selectedIndex = 0;

  final User? currentUser = FirebaseAuth.instance.currentUser;

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UserProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9),

      /// 🔹 APP BAR
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: primaryBlue,
        title: const Text(
          'Asset',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      /// 🔹 DRAWER
      drawer: Drawer(
        child: Container(
          color: primaryBlue,
          child: Column(
            children: [
              Container(
                height: 240,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),

                /// 🔥 PROFILE FROM FIRESTORE
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String name = "User";
                    Uint8List? imageBytes;

                    if (snapshot.hasData && snapshot.data!.data() != null) {
                      final data =
                          snapshot.data!.data() as Map<String, dynamic>;

                      name = data['name'] ?? "User";

                      if (data['profileImage'] != null &&
                          data['profileImage'].toString().isNotEmpty) {
                        imageBytes = base64Decode(data['profileImage']);
                      }
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          backgroundImage: imageBytes != null
                              ? MemoryImage(imageBytes)
                              : null,
                          child: imageBytes == null
                              ? const Icon(Icons.person,
                                  size: 42, color: primaryBlue)
                              : null,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Smart Asset Management',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(color: Colors.white54),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text('Profile',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UserProfileScreen()),
                  );
                },
              ),
              const Spacer(),
              const Divider(color: Colors.white54),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title:
                    const Text('Logout', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),

      /// 🔹 BODY
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [
            const SizedBox(height: 25),

            /// 🔹 Welcome Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Icon(Icons.dashboard_customize,
                      color: Colors.white, size: 40),
                  SizedBox(width: 15),
                  Text(
                    "Welcome Back 👋",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// 🔹 GRID
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: 0.95,
                children: [
                  DashboardCard(
                    title: 'Scan Asset',
                    subtitle: 'RFID / QR Scan',
                    icon: Icons.qr_code,
                    circleColor: const Color(0xFFB23A48),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RFIDScanScreen())),
                  ),
                  DashboardCard(
                    title: 'Search Asset',
                    subtitle: 'Find asset details',
                    icon: Icons.search,
                    circleColor: const Color(0xFF1BA672),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SearchAssetScreen())),
                  ),
                  DashboardCard(
                    title: 'Report Asset',
                    subtitle: 'Damage / Lost',
                    icon: Icons.warning_amber_rounded,
                    circleColor: const Color(0xFFF2992E),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ReportAssetScreen())),
                  ),
                  DashboardCard(
                    title: 'Asset Requests',
                    subtitle: 'New Assets',
                    icon: Icons.inventory_2_outlined,
                    circleColor: const Color(0xFFD4A017),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AssetRequestScreen())),
                  ),
                  DashboardCard(
                    title: 'Notifications',
                    subtitle: 'View alerts',
                    icon: Icons.notifications,
                    circleColor: primaryBlue,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationScreen())),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      /// 🔹 BOTTOM NAV
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: primaryBlue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

/// 🔹 CLEAN DASHBOARD CARD (NO BADGE)
class DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color circleColor;
  final VoidCallback onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.circleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleColor,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
