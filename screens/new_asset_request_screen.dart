import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewAssetRequestScreen extends StatefulWidget {
  const NewAssetRequestScreen({super.key});

  @override
  State<NewAssetRequestScreen> createState() => _NewAssetRequestScreenState();
}

class _NewAssetRequestScreenState extends State<NewAssetRequestScreen>
    with SingleTickerProviderStateMixin {
  String selectedFilter = 'All';
  String searchText = '';
  bool _updating = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final CollectionReference requestsRef = FirebaseFirestore.instance.collection(
    'asset_requests',
  );

  final Map<String, String> _userCache = {}; // uid -> name

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ============================================================
  // 🔔 STEP 1: HELPER FUNCTION (SEND NOTIFICATION)
  // ============================================================
  Future<void> sendAssetRequestNotification({
    required String userUid,
    required String assetName,
    required bool approved,
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userUid': userUid,
      'title': approved ? 'Asset Request Approved' : 'Asset Request Rejected',
      'message': approved
          ? 'Your request for $assetName was approved'
          : 'Your request for $assetName was rejected',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Color statusColor(String status) {
    if (status == 'Approved') return Colors.green;
    if (status == 'Rejected') return Colors.red;
    return Colors.orange;
  }

  String timeAgo(Timestamp? ts) {
    if (ts == null) return 'Just now';
    final d = DateTime.now().difference(ts.toDate());
    if (d.inDays > 0) return '${d.inDays} day(s) ago';
    if (d.inHours > 0) return '${d.inHours} hour(s) ago';
    return '${d.inMinutes} min ago';
  }

  Future<String> getUserName(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid]!;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final name = doc.data()?['name'] ?? 'Unknown';
    _userCache[uid] = name;
    return name;
  }

  // ============================================================
  // 🔁 STEP 2: UPDATE APPROVE / REJECT LOGIC (NO UI CHANGE)
  // ============================================================
  Future<void> updateStatus(String docId, String status) async {
    if (_updating) return;

    setState(() => _updating = true);

    try {
      final docRef =
          FirebaseFirestore.instance.collection('asset_requests').doc(docId);

      final docSnap = await docRef.get();
      final data = docSnap.data() as Map<String, dynamic>;

      final String userUid = data['requestedBy'];
      final String assetName = data['assetName'];

      // ✅ Update request status
      await docRef.update({'status': status});

      // 🔔 Send notification
      await sendAssetRequestNotification(
        userUid: userUid,
        assetName: assetName,
        approved: status == 'Approved',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Request $status successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  /// 🔢 CLICKABLE COUNT CARD
  Widget countCard(String label, int count, Color color) {
    final bool active = selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedFilter = label),
        child: Card(
          elevation: active ? 10 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: active ? BorderSide(color: color, width: 2) : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
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
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Asset Requests'),
        backgroundColor: const Color(0xFF2F6FD6),
        centerTitle: true,
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
          stream:
              requestsRef.orderBy('requestedAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            final all = docs.length;
            final pending = docs.where((d) => d['status'] == 'Pending').length;
            final approved =
                docs.where((d) => d['status'] == 'Approved').length;
            final rejected =
                docs.where((d) => d['status'] == 'Rejected').length;

            final filtered = docs.where((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final statusOk =
                  selectedFilter == 'All' || d['status'] == selectedFilter;
              final searchOk = d['assetName'].toString().toLowerCase().contains(
                    searchText.toLowerCase(),
                  );
              return statusOk && searchOk;
            }).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      countCard('All', all, Colors.blue),
                      const SizedBox(width: 8),
                      countCard('Pending', pending, Colors.orange),
                      const SizedBox(width: 8),
                      countCard('Approved', approved, Colors.green),
                      const SizedBox(width: 8),
                      countCard('Rejected', rejected, Colors.red),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: const InputDecoration(
                      filled: true,
                      hintText: 'Search asset name',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => searchText = v),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final doc = filtered[i];
                          final d = doc.data() as Map<String, dynamic>;

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.inventory_2,
                                        color: statusColor(d['status']),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          d['assetName'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Chip(
                                        backgroundColor: statusColor(
                                          d['status'],
                                        ),
                                        label: Text(
                                          d['status'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Type: ${d['assetType']}'),
                                  Text('Department: ${d['department']}'),
                                  Text('Purpose: ${d['purpose']}'),
                                  const SizedBox(height: 6),
                                  FutureBuilder<String>(
                                    future: getUserName(d['requestedBy']),
                                    builder: (_, snap) => Text(
                                      '👤 ${snap.data ?? 'Loading...'} · ⏱ ${timeAgo(d['requestedAt'])}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (d['status'] == 'Pending')
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          onPressed: () =>
                                              updateStatus(doc.id, 'Approved'),
                                          child: const Text('Approve'),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () =>
                                              updateStatus(doc.id, 'Rejected'),
                                          child: const Text('Reject'),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      '✔ ${d['status']}',
                                      style: TextStyle(
                                        color: statusColor(d['status']),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
