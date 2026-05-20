import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_assets_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final primaryBlue = const Color(0xFF1565C0);

  /// ================================
  /// 🔹 FIRESTORE STREAMS
  /// ================================
  Stream<int> _totalAssets() => FirebaseFirestore.instance
      .collection('assets')
      .snapshots()
      .map((s) => s.docs.length);

  Stream<int> _availableAssets() => FirebaseFirestore.instance
      .collection('assets')
      .where('status', isEqualTo: 'Available')
      .snapshots()
      .map((s) => s.docs.length);

  Stream<int> _totalUsers() => FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map((s) => s.docs.length);

  Stream<int> _reportedIssues() => FirebaseFirestore.instance
      .collection('reported_assets')
      .where('status', isEqualTo: 'Under Repair')
      .snapshots()
      .map((s) => s.docs.length);

  Stream<QuerySnapshot> _recentActivities() => FirebaseFirestore.instance
      .collection('activities')
      .orderBy('createdAt', descending: true)
      .limit(5)
      .snapshots();

  /// ================================
  /// 🔹 NAVIGATION
  /// ================================
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminAssetsScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      /// 🔹 APP BAR
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
        backgroundColor: primaryBlue,
      ),

      /// 🔹 DRAWER (ADMIN PANEL)
      drawer: Drawer(
        child: Container(
          color: primaryBlue,
          child: Column(
            children: [
              const SizedBox(height: 50),
              Expanded(
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
                        /// 🔹 PROFILE IMAGE
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          backgroundImage: imageBytes != null
                              ? MemoryImage(imageBytes)
                              : null,
                          child: imageBytes == null
                              ? Icon(Icons.person, size: 42, color: primaryBlue)
                              : null,
                        ),

                        const SizedBox(height: 14),

                        /// 🔹 NAME
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        /// 🔹 SUBTITLE
                        const Text(
                          'Smart Asset Management',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),

                        const SizedBox(height: 25),
                        const Divider(color: Colors.white54),

                        /// 🔥 MANAGE ASSETS
                        ListTile(
                          leading:
                              const Icon(Icons.inventory, color: Colors.white),
                          title: const Text(
                            'Manage Assets',
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => AdminAssetsScreen()),
                            );
                          },
                        ),

                        /// 🔹 PROFILE
                        ListTile(
                          leading:
                              const Icon(Icons.person, color: Colors.white),
                          title: const Text(
                            'Profile',
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ProfileScreen()),
                            );
                          },
                        ),

                        const Spacer(),
                        const Divider(color: Colors.white54),

                        /// 🔹 LOGOUT
                        ListTile(
                          leading:
                              const Icon(Icons.logout, color: Colors.white),
                          title: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                              (_) => false,
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      /// 🔹 BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 WELCOME CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
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

            const SizedBox(height: 25),

            const Text(
              "Overview",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            /// 🔹 STAT CARDS
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              children: [
                _statStream("Total Assets", _totalAssets(), Icons.inventory,
                    [Color(0xFF42A5F5), Color(0xFF1976D2)]),
                _statStream("Total Users", _totalUsers(), Icons.people,
                    [Colors.orange, Colors.deepOrange]),
                _statStream("Available", _availableAssets(), Icons.check_circle,
                    [Colors.green, Colors.teal]),
                _statStream("Reported Issues", _reportedIssues(), Icons.warning,
                    [Colors.red, Colors.redAccent]),
              ],
            ),

            const SizedBox(height: 30),

            /// 🔹 RECENT ACTIVITIES
            const Text(
              "Recent Activities",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: _recentActivities(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          _iconFromType(data['icon']),
                          color: _colorFromType(data['icon']),
                        ),
                        title: Text(data['title']),
                        subtitle: Text(_timeAgo(data['createdAt'])),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),

      /// 🔹 BOTTOM NAV BAR
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BottomNavigationBar(
            backgroundColor: primaryBlue,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            showUnselectedLabels: false,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard), label: "Home"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.inventory), label: "Assets"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: "Profile"),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 HELPERS
  Widget _statStream(
      String title, Stream<int> stream, IconData icon, List<Color> gradient) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (_, snap) =>
          _statCard(title, snap.data?.toString() ?? "0", icon, gradient),
    );
  }

  Widget _statCard(
      String title, String value, IconData icon, List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 36),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  IconData _iconFromType(String type) {
    switch (type) {
      case 'assign':
        return Icons.assignment_ind;
      case 'issue':
        return Icons.warning;
      case 'resolve':
        return Icons.check_circle;
      default:
        return Icons.inventory;
    }
  }

  Color _colorFromType(String type) {
    switch (type) {
      case 'assign':
        return Colors.blue;
      case 'issue':
        return Colors.red;
      case 'resolve':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _timeAgo(Timestamp time) {
    final diff = DateTime.now().difference(time.toDate());
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    return "${diff.inDays} days ago";
  }
}
