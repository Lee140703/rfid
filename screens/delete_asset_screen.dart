import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// =======================
/// ASSET MODEL
/// =======================
class Asset {
  final String assetId;
  final String assetName;
  final String functionality;
  final String lastUsedPerson;
  final String incharge;
  final String block;
  final int yearsUsed;
  final String purchaseDate;
  final String lastUsedDate;

  Asset({
    required this.assetId,
    required this.assetName,
    required this.functionality,
    required this.lastUsedPerson,
    required this.incharge,
    required this.block,
    required this.yearsUsed,
    required this.purchaseDate,
    required this.lastUsedDate,
  });

  factory Asset.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    String safe(String? v) => (v == null || v.trim().isEmpty) ? '⚠ Missing' : v;

    final rawYears = data?['yearsUsed'];
    int years = rawYears is int
        ? rawYears
        : int.tryParse(rawYears?.toString() ?? '') ?? 0;

    return Asset(
      assetId: doc.id,
      assetName: safe(data?['assetName']),
      functionality: safe(data?['functionality']),
      lastUsedPerson: safe(data?['lastUsedPerson']),
      incharge: safe(data?['incharge']),
      block: safe(data?['block']),
      yearsUsed: years,
      purchaseDate: safe(data?['purchaseDate']),
      lastUsedDate: safe(data?['lastUsedDate']),
    );
  }
}

/// =======================
/// DELETE / RESTORE SCREEN
/// =======================
class DeleteAssetScreen extends StatefulWidget {
  const DeleteAssetScreen({super.key});

  @override
  State<DeleteAssetScreen> createState() => _DeleteAssetScreenState();
}

class _DeleteAssetScreenState extends State<DeleteAssetScreen> {
  String searchQuery = '';
  bool showArchived = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get assetsRef => _firestore.collection('assets');
  CollectionReference get archiveRef =>
      _firestore.collection('archived_assets');

  @override
  Widget build(BuildContext context) {
    final collection = showArchived ? archiveRef : assetsRef;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E63B6),
        centerTitle: true,
        title: Text(
          showArchived ? "Archived Assets" : "Delete Asset",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              showArchived ? Icons.list : Icons.archive,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                showArchived = !showArchived;
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0E2F3A), Color(0xFF1F4E5F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _searchBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: collection.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  final assets = snapshot.data!.docs
                      .map((doc) => Asset.fromFirestore(doc))
                      .where(
                        (a) =>
                            a.assetName.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ) ||
                            a.assetId.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ),
                      )
                      .toList();

                  if (assets.isEmpty) {
                    return const Center(
                      child: Text(
                        "No assets found",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: assets.length,
                    itemBuilder: (_, i) => _assetCard(assets[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (v) => setState(() => searchQuery = v),
        decoration: InputDecoration(
          hintText: "Search by Asset ID or Name",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _assetCard(Asset asset) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    asset.assetName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!showArchived)
                  IconButton(
                    icon: const Icon(Icons.archive, color: Colors.red),
                    onPressed: () => _confirmArchive(asset),
                  )
                else
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore, color: Colors.green),
                        onPressed: () => _confirmRestore(asset),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmPermanentDelete(asset),
                      ),
                    ],
                  ),
              ],
            ),
            _info("Asset ID", asset.assetId),
            _info("Functionality", asset.functionality),
            _info("Last Used By", asset.lastUsedPerson),
            _info("Incharge", asset.incharge),
            _info("Block", asset.block),
            const Divider(),
            _info("Purchase Date", asset.purchaseDate),
            _info("Last Used Date", asset.lastUsedDate),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        "$label: $value",
        style: TextStyle(
          color: value == '⚠ Missing' ? Colors.red : Colors.black,
        ),
      ),
    );
  }

  /// ================= CONFIRM DIALOGS =================

  void _confirmArchive(Asset asset) {
    _showConfirmDialog(
      "Archive Asset",
      "Are you sure you want to archive '${asset.assetName}'?",
      () => _archiveAsset(asset.assetId),
    );
  }

  void _confirmRestore(Asset asset) {
    _showConfirmDialog(
      "Restore Asset",
      "Restore '${asset.assetName}'?",
      () => _restoreAsset(asset.assetId),
    );
  }

  void _confirmPermanentDelete(Asset asset) {
    _showConfirmDialog(
      "Permanent Delete",
      "This will permanently delete '${asset.assetName}'. Continue?",
      () => _permanentDelete(asset.assetId),
    );
  }

  void _showConfirmDialog(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Confirm"),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
          ),
        ],
      ),
    );
  }

  /// ================= ARCHIVE =================
  Future<void> _archiveAsset(String assetId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final assetDocRef = assetsRef.doc(assetId);
      final archiveDocRef = archiveRef.doc(assetId);

      final snapshot = await assetDocRef.get();
      final data = snapshot.data() as Map<String, dynamic>;

      await archiveDocRef.set({
        ...data,
        'archivedAt': FieldValue.serverTimestamp(),
        'archivedBy': user!.uid,
      });

      await assetDocRef.delete();

      _showSnack("Asset archived successfully", Colors.green);
    } catch (e) {
      _showSnack("Archive failed: $e", Colors.red);
    }
  }

  /// ================= RESTORE =================
  Future<void> _restoreAsset(String assetId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final archivedDocRef = archiveRef.doc(assetId);
      final assetDocRef = assetsRef.doc(assetId);

      final snapshot = await archivedDocRef.get();
      final data = snapshot.data() as Map<String, dynamic>;

      await assetDocRef.set({
        ...data,
        'restoredAt': FieldValue.serverTimestamp(),
        'restoredBy': user!.uid,
      });

      await archivedDocRef.delete();

      _showSnack("Asset restored successfully", Colors.green);
    } catch (e) {
      _showSnack("Restore failed: $e", Colors.red);
    }
  }

  /// ================= PERMANENT DELETE =================
  Future<void> _permanentDelete(String assetId) async {
    try {
      await archiveRef.doc(assetId).delete();
      _showSnack("Asset permanently deleted", Colors.green);
    } catch (e) {
      _showSnack("Delete failed: $e", Colors.red);
    }
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(backgroundColor: color, content: Text(message)));
  }
}
