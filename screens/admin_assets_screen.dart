import 'package:flutter/material.dart';

import 'add_asset_screen.dart';
import 'issue_asset_screen.dart';
import 'add_user_screen.dart';
import 'new_asset_request_screen.dart';
import 'delete_asset_screen.dart';

class AdminAssetsScreen extends StatelessWidget {
  const AdminAssetsScreen({super.key});

  static const Color primaryBlue = Color(0xFF1E63B5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Manage Asset",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),

      // ================= BODY =================
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          children: [
            const SizedBox(height: 25),

            // 🔹 Welcome Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E63B5), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 40),
                  SizedBox(width: 15),
                  Text(
                    "Manage Asset",
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

            // 🔹 GRID (User Style)
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: 0.95,
                children: [
                  _dashboardCard(
                    context,
                    title: 'Add Asset',
                    subtitle: 'Register new item',
                    icon: Icons.add_box_rounded,
                    color: Colors.redAccent,
                    page: const AddAssetScreen(),
                  ),
                  _dashboardCard(
                    context,
                    title: 'Issue Asset',
                    subtitle: 'Assign to user',
                    icon: Icons.check_circle_rounded,
                    color: Colors.green,
                    page: const IssueAssetScreen(),
                  ),
                  _dashboardCard(
                    context,
                    title: 'Add User',
                    subtitle: 'Create system user',
                    icon: Icons.person_add_alt_1_rounded,
                    color: Colors.blue,
                    page: const AddUserScreen(),
                  ),
                  _dashboardCard(
                    context,
                    title: 'Asset Requests',
                    subtitle: 'Pending approvals',
                    icon: Icons.notifications,
                    color: const Color(0xFFD18B2A),
                    page: const NewAssetRequestScreen(),
                  ),
                  _dashboardCard(
                    context,
                    title: 'Delete Asset',
                    subtitle: 'Remove item',
                    icon: Icons.delete_rounded,
                    color: Colors.deepOrange,
                    page: const DeleteAssetScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DASHBOARD CARD =================
  Widget _dashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔹 Icon Circle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),

            const SizedBox(height: 10),

            // 🔹 Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 4),

            // 🔹 Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
