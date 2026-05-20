import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// =======================
/// ASSET MODEL (UNCHANGED)
/// =======================
class Asset {
  final String docId;
  final String assetId;
  final String assetName;
  final String category;
  final String status;
  final String functionality;
  final String lastUsedPerson;
  final String incharge;
  final String block;
  final String purchaseDate;
  final String lastUsedDate;
  final int yearsUsed;
  final Timestamp? repairEndDate;

  Asset({
    required this.docId,
    required this.assetId,
    required this.assetName,
    required this.category,
    required this.status,
    required this.functionality,
    required this.lastUsedPerson,
    required this.incharge,
    required this.block,
    required this.purchaseDate,
    required this.lastUsedDate,
    required this.yearsUsed,
    this.repairEndDate,
  });

  factory Asset.fromFirestore(Map<String, dynamic> data, String docId) {
    return Asset(
      docId: docId,
      assetId: data['assetId']?.toString() ?? '',
      assetName: data['assetName']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      status: data['status']?.toString() ?? 'Available',
      functionality: data['functionality']?.toString() ?? '',
      lastUsedPerson: data['lastUsedPerson']?.toString() ?? '',
      incharge: data['incharge']?.toString() ?? '',
      block: data['block']?.toString() ?? '',
      purchaseDate: data['purchaseDate']?.toString() ?? '',
      lastUsedDate: data['lastUsedDate']?.toString() ?? '',
      yearsUsed: int.tryParse(data['yearsUsed']?.toString() ?? '0') ?? 0,
      repairEndDate: data['repairEndDate'],
    );
  }
}

/// =======================
/// SEARCH SCREEN
/// =======================
class SearchAssetScreen extends StatefulWidget {
  const SearchAssetScreen({super.key});

  @override
  State<SearchAssetScreen> createState() => _SearchAssetScreenState();
}

class _SearchAssetScreenState extends State<SearchAssetScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  bool isLoading = false;
  List<Asset> results = [];

  late AnimationController _warningController;
  late Animation<double> _warningScale;

  static const Color primaryBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _warningController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _warningScale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _warningController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _warningController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// =======================
  /// SEARCH LOGIC (UPDATED)
  /// =======================
  Future<void> _searchAssets() async {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() => results = []);
      return;
    }

    setState(() => isLoading = true);

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('assets').get();

      final allAssets = snapshot.docs
          .map((doc) => Asset.fromFirestore(doc.data(), doc.id))
          .toList();

      /// 🔍 Exact match
      final exactMatches = allAssets.where((a) {
        return a.assetId.toLowerCase() == query;
      }).toList();

      if (exactMatches.isNotEmpty) {
        setState(() {
          results = exactMatches;
          isLoading = false;
        });
        return;
      }

      /// 🔍 Partial match
      final filtered = allAssets.where((a) {
        return a.assetId.toLowerCase().contains(query) ||
            a.assetName.toLowerCase().contains(query);
      }).toList();

      setState(() => results = filtered);

      if (filtered.isEmpty) {
        _warningController.forward(from: 0);
      }
    } catch (_) {
      setState(() => results = []);
    }

    setState(() => isLoading = false);
  }

  /// =======================
  /// UI HELPERS
  /// =======================
  Color getStatusColor(String status) =>
      status == 'Available' ? Colors.green : Colors.orange;

  Widget infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$label: ',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =======================
  /// BUILD
  /// =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        centerTitle: true,
        title: const Text(
          'Search Asset',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          /// 🌌 BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF203A43),
                  Color(0xFF2C5364)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          /// 🧊 CONTENT
          SafeArea(
            child: Column(
              children: [
                /// 🔍 SEARCH BAR
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _searchAssets(),
                        decoration: InputDecoration(
                          hintText: 'Search by Asset ID or Name',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(18),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// 📦 RESULTS
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : results.isEmpty && _searchController.text.isNotEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ScaleTransition(
                                    scale: _warningScale,
                                    child: const Icon(
                                      Icons.search_off,
                                      size: 70,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No assets found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                itemCount: results.length,
                                itemBuilder: (context, index) {
                                  final asset = results[index];
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 12,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
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
                                            Chip(
                                              label: Text(asset.status),
                                              backgroundColor:
                                                  getStatusColor(asset.status),
                                              labelStyle: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        const Divider(),
                                        infoRow(Icons.qr_code, 'Asset ID',
                                            asset.assetId),
                                        infoRow(Icons.category, 'Category',
                                            asset.category),
                                        infoRow(Icons.settings, 'Functionality',
                                            asset.functionality),
                                        infoRow(Icons.person, 'Last Used By',
                                            asset.lastUsedPerson),
                                        infoRow(Icons.badge, 'Incharge',
                                            asset.incharge),
                                        infoRow(Icons.apartment, 'Block',
                                            asset.block),
                                        infoRow(Icons.event, 'Purchase Date',
                                            asset.purchaseDate),
                                        infoRow(Icons.history, 'Last Used Date',
                                            asset.lastUsedDate),
                                        infoRow(Icons.timelapse, 'Years Used',
                                            asset.yearsUsed.toString()),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
