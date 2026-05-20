import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/activity_service.dart';

class IssueAssetScreen extends StatefulWidget {
  const IssueAssetScreen({super.key});

  @override
  State<IssueAssetScreen> createState() => _IssueAssetScreenState();
}

class _IssueAssetScreenState extends State<IssueAssetScreen>
    with SingleTickerProviderStateMixin {
  String selectedFilter = 'All';
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 🎨 STATUS COLOR
  Color statusColor(String status) {
    return status == 'Resolved' ? Colors.green : Colors.red;
  }

  /// ⏱ TIME AGO
  String timeAgo(Timestamp time) {
    final diff = DateTime.now().difference(time.toDate());
    if (diff.inDays > 0) return '${diff.inDays} day(s) ago';
    if (diff.inHours > 0) return '${diff.inHours} hour(s) ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} min ago';
    return 'Just now';
  }

  /// 🔢 COUNT BY STATUS
  int countByStatus(List<QueryDocumentSnapshot> docs, String status) {
    if (status == 'All') return docs.length;
    return docs.where((d) => d['status'] == status).length;
  }

  /// 🔔 SEND NOTIFICATION TO USER
  Future<void> sendNotification({
    required String userUid,
    required String assetId,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userUid': userUid,
      'title': 'Asset Issue Resolved',
      'message': 'Your reported asset $assetId has been resolved.',
      'assetId': assetId,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// ✅ RESOLVE ISSUE + UPDATE ASSET + NOTIFY USER + ACTIVITY LOG
  Future<void> resolveIssue({
    required String reportDocId,
    required String assetId,
    required String userUid,
  }) async {
    try {
      // 1️⃣ Update reported asset status
      await FirebaseFirestore.instance
          .collection('reported_assets')
          .doc(reportDocId)
          .update({
        'status': 'Resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      // 2️⃣ Update main asset availability
      await FirebaseFirestore.instance.collection('assets').doc(assetId).update(
        {'status': 'Available'},
      );

      // 3️⃣ Send notification to user
      await sendNotification(userUid: userUid, assetId: assetId);

      // 4️⃣ ✅ LOG ACTIVITY (ADDED)
      await ActivityService.log(
        title: 'Asset issued to $userUid',
        icon: 'assign',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✔ Issue resolved & user notified'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Issue Assets',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2F6FD6), // ✅ Blue color
        foregroundColor: Colors.white, // ✅ icons + back button color
        elevation: 0,
        surfaceTintColor: Colors.transparent, // ✅ FIX for Material 3 override
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reported_assets')
              .orderBy('reportedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            final filtered = selectedFilter == 'All'
                ? docs
                : docs.where((d) => d['status'] == selectedFilter).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      buildCountCard(
                        'All',
                        countByStatus(docs, 'All'),
                        Colors.blue,
                      ),
                      buildCountCard(
                        'Under Repair',
                        countByStatus(docs, 'Under Repair'),
                        Colors.red,
                      ),
                      buildCountCard(
                        'Resolved',
                        countByStatus(docs, 'Resolved'),
                        Colors.green,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    value: selectedFilter,
                    decoration: const InputDecoration(
                      filled: true,
                      labelText: 'Filter by Status',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All')),
                      DropdownMenuItem(
                        value: 'Under Repair',
                        child: Text('Under Repair'),
                      ),
                      DropdownMenuItem(
                        value: 'Resolved',
                        child: Text('Resolved'),
                      ),
                    ],
                    onChanged: (v) => setState(() => selectedFilter = v!),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return ScaleTransition(
                        scale: Tween<double>(begin: 0.85, end: 1).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: Curves.easeOut,
                          ),
                        ),
                        child: Card(
                          elevation: 10,
                          margin: const EdgeInsets.only(bottom: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.inventory_2,
                                      color: statusColor(data['status']),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        data['assetId'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        data['status'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: statusColor(
                                        data['status'],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(data['issue'] ?? ''),
                                const SizedBox(height: 6),
                                Text(
                                  '👤 ${data['reportedBy']} • ⏱ ${timeAgo(data['reportedAt'])}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                if (data['status'] != 'Resolved')
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                      ),
                                      onPressed: () => resolveIssue(
                                        reportDocId: doc.id,
                                        assetId: data['assetId'],
                                        userUid: data['reportedByUid'],
                                      ),
                                      child: const Text('Resolve Issue'),
                                    ),
                                  )
                                else
                                  const Text(
                                    '✔ Completed',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget buildCountCard(String title, int count, Color color) {
    return Expanded(
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
