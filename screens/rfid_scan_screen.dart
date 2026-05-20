import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RFIDScanScreen extends StatefulWidget {
  const RFIDScanScreen({Key? key}) : super(key: key);

  @override
  State<RFIDScanScreen> createState() => _RFIDScanScreenState();
}

class _RFIDScanScreenState extends State<RFIDScanScreen> {
  bool _isScanning = false;

  String _status = "Ready to Scan";
  Map<String, dynamic>? _assetData;

  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      _startScan();
    });
  }

  /// ================= START SCAN =================
  Future<void> _startScan() async {
    await NfcManager.instance.stopSession();

    bool isAvailable = await NfcManager.instance.isAvailable();

    if (!isAvailable) {
      if (!mounted) return;
      setState(() => _status = "NFC not available ❌");
      return;
    }

    if (!mounted) return;

    setState(() {
      _isScanning = true;
      _status = "Tap NFC tag...";
      _assetData = null;
      _tabIndex = 0;
    });

    NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      onDiscovered: (NfcTag tag) async {
        if (!mounted) return;

        try {
          final ndef = Ndef.from(tag);

          if (ndef == null) throw Exception("Tag not supported");

          final message = ndef.cachedMessage;

          if (message == null || message.records.isEmpty) {
            throw Exception("Empty tag");
          }

          final record = message.records.first;
          String assetId = "";

          if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
            final payload = record.payload;
            final langLength = payload[0] & 0x3F;
            assetId = String.fromCharCodes(payload.sublist(1 + langLength));
          }

          assetId = assetId.replaceAll("asset:", "").trim();

          await _fetchAsset(assetId);

          if (!mounted) return;

          setState(() {
            _isScanning = false;
          });

          await NfcManager.instance.stopSession();
        } catch (e) {
          if (!mounted) return;

          setState(() {
            _status = "Scan Failed ❌";
            _isScanning = false;
          });

          await NfcManager.instance.stopSession(
            errorMessage: "Scan Failed",
          );
        }
      },
    );
  }

  /// ================= FETCH =================
  Future<void> _fetchAsset(String id) async {
    final doc =
        await FirebaseFirestore.instance.collection('assets').doc(id).get();

    if (doc.exists) {
      if (!mounted) return;

      setState(() {
        _assetData = doc.data();
        _status = "Asset Found ✅";
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _tabIndex = 1;
          });
        }
      });
    } else {
      if (!mounted) return;

      setState(() {
        _status = "No Asset Found ❌";
        _assetData = null;
      });
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          /// HEADER
          Container(
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
            height: 100,
            color: const Color(0xFF2F6DB3),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 28),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      "RFID Scanner",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),

          /// BODY
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F2A2E), Color(0xFF1F4D57)],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  /// TABS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _tabButton("SCAN TAG", 0),
                      const SizedBox(width: 40),
                      _tabButton("ASSET DETAILS", 1),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Expanded(
                    child: _tabIndex == 0 ? _scanView() : _detailsView(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// SCAN VIEW
  Widget _scanView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 200,
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.blueAccent, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.nfc, size: 80, color: Colors.blueAccent),
          ),
        ),
        const SizedBox(height: 30),
        Text(_status,
            style: const TextStyle(color: Colors.white70, fontSize: 16)),
      ],
    );
  }

  /// DETAILS VIEW
  Widget _detailsView() {
    if (_assetData == null) {
      return const Center(
        child: Text("No Data", style: TextStyle(color: Colors.white)),
      );
    }

    String status = _assetData!['status'] ?? "Available";

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _assetData!['name'] ?? "Asset",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          status == "Available" ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(status,
                        style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const Divider(height: 25),
              _infoRow(Icons.qr_code, "Asset ID", _assetData!['assetId'] ?? ""),
              _infoRow(
                  Icons.category, "Category", _assetData!['category'] ?? ""),
              _infoRow(
                  Icons.person,
                  "Last Used By",
                  _assetData!['lastUser'] ??
                      _assetData!['lastUsedPerson'] ??
                      "N/A"),
              _infoRow(
                  Icons.person_outline,
                  "Incharge",
                  _assetData!['incharge'] ??
                      _assetData!['inchargeName'] ??
                      "N/A"),
              _infoRow(Icons.business, "Block", _assetData!['block'] ?? ""),
              _infoRow(Icons.calendar_today, "Purchase Date",
                  _assetData!['purchaseDate'] ?? ""),
              _infoRow(Icons.access_time, "Last Used",
                  _assetData!['lastUsedDate'] ?? ""),
              _infoRow(Icons.timer, "Years Used",
                  _assetData!['yearsUsed']?.toString() ?? ""),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _tabButton(String title, int index) {
    final isActive = _tabIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Column(
        children: [
          Text(title,
              style:
                  TextStyle(color: isActive ? Colors.white : Colors.white54)),
          const SizedBox(height: 5),
          Container(
            height: 3,
            width: 80,
            color: isActive ? Colors.blue : Colors.transparent,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }
}
