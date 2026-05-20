import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  final int _limit = 10;
  final ScrollController _scrollController = ScrollController();

  List<DocumentSnapshot> _docs = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        fetchNotifications();
      }
    });
  }

  /// ✅ ICON LOGIC (APPROVE / REJECT / DEFAULT)
  Widget buildNotificationIcon(String title, bool isRead) {
    IconData icon;
    Color color;

    if (title.toLowerCase().contains("approved")) {
      icon = Icons.thumb_up;
      color = Colors.green;
    } else if (title.toLowerCase().contains("rejected")) {
      icon = Icons.thumb_down;
      color = Colors.red;
    } else {
      icon = Icons.check;
      color = const Color(0xFF4CAF50);
    }

    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isRead ? Colors.grey.withOpacity(0.2) : color.withOpacity(0.15),
      ),
      child: Center(
        child: Container(
          height: 26,
          width: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
          child: Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// FETCH WITH PAGINATION
  Future<void> fetchNotifications() async {
    if (userId == null) return;

    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('notifications')
        .where('userUid', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(_limit);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastDoc = snapshot.docs.last;
    }

    setState(() {
      _docs.addAll(snapshot.docs);
      _isLoading = false;
      if (snapshot.docs.length < _limit) _hasMore = false;
    });
  }

  /// CLEAR ALL
  Future<void> clearAllNotifications() async {
    if (userId == null) return;

    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Clear all notifications?"),
        content: const Text("Are you sure to clear all?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Clear")),
        ],
      ),
    );

    if (confirm != true) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userUid', isEqualTo: userId)
        .get();

    final backup = snapshot.docs;

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    setState(() {
      _docs.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("All notifications cleared"),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () async {
            for (var doc in backup) {
              await FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(doc.id)
                  .set(doc.data() as Map<String, dynamic>);
            }
            _resetPagination();
          },
        ),
      ),
    );
  }

  /// DELETE SINGLE
  Future<void> deleteNotification(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;

    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(doc.id)
        .delete();

    setState(() {
      _docs.removeWhere((d) => d.id == doc.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Notification deleted"),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection('notifications')
                .doc(doc.id)
                .set(data);
            _resetPagination();
          },
        ),
      ),
    );
  }

  void _resetPagination() {
    _docs.clear();
    _lastDoc = null;
    _hasMore = true;
    fetchNotifications();
  }

  Future<void> markAsRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'read': true});
  }

  String getGroupLabel(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return "Today";
    if (difference == 1) return "Yesterday";
    return "Older";
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    final Map<String, List<DocumentSnapshot>> grouped = {};

    for (var doc in _docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['createdAt'];
      final createdAt = ts != null ? ts.toDate() : DateTime.now();
      final label = getGroupLabel(createdAt);

      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(doc);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userUid', isEqualTo: userId)
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {},
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          TextButton(
            onPressed: clearAllNotifications,
            child:
                const Text("Clear all", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              ...grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(entry.key,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70)),
                    ),
                    ...entry.value.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final isRead = data['read'] ?? false;
                      final ts = data['createdAt'];
                      final createdAt =
                          ts != null ? ts.toDate() : DateTime.now();

                      return Dismissible(
                        key: Key(doc.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => deleteNotification(doc),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: GestureDetector(
                          onTap: () => markAsRead(doc.id),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 18),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: isRead
                                        ? Colors.white.withOpacity(0.85)
                                        : Colors.white.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      /// ✅ ICON HERE
                                      buildNotificationIcon(
                                          data['title'] ?? '', isRead),

                                      const SizedBox(width: 16),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(data['title'] ?? '',
                                                style: TextStyle(
                                                    fontWeight: isRead
                                                        ? FontWeight.w600
                                                        : FontWeight.bold)),
                                            const SizedBox(height: 6),
                                            Text(data['message'] ?? ''),
                                            const SizedBox(height: 10),
                                            Text(timeago.format(createdAt),
                                                style: const TextStyle(
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),

                                      if (!isRead)
                                        Container(
                                          height: 10,
                                          width: 10,
                                          decoration: const BoxDecoration(
                                            color: Colors.blue,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
