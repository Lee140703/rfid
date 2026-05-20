import 'dart:async';
import 'dart:typed_data'; // ✅ IMPORTANT FIX
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/activity_service.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddAssetScreen extends StatefulWidget {
  const AddAssetScreen({super.key});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final assetId = TextEditingController();
  final assetName = TextEditingController();
  final functionality = TextEditingController();
  final lastUsedPerson = TextEditingController();
  final incharge = TextEditingController();
  final yearsUsed = TextEditingController();
  final purchaseDate = TextEditingController();
  final lastuseddate = TextEditingController();

  String? category;
  String? block;

  bool _isLoading = false;
  bool _checkingId = false;
  bool _isDuplicateId = false;
  bool _isAdminUser = false;
  bool _checkingAdmin = true;

  Timer? _debounce;

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeIn);

    _slide = Tween(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(_fade);

    _anim.forward();

    assetId.addListener(_onAssetIdChanged);

    _checkAdminAccess();
  }

  // ================= ADMIN ACCESS CHECK =================
  Future<void> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _checkingAdmin = false;
        _isAdminUser = false;
      });
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (mounted) {
      setState(() {
        _isAdminUser = doc.exists && doc['role'] == 'admin';
        _checkingAdmin = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    assetId.dispose();
    assetName.dispose();
    functionality.dispose();
    lastUsedPerson.dispose();
    incharge.dispose();
    yearsUsed.dispose();
    purchaseDate.dispose();
    lastuseddate.dispose();
    _anim.dispose();
    super.dispose();
  }

  // ================= NFC WRITE =================
  Future<void> _writeToNfc(String id) async {
    bool isAvailable = await NfcManager.instance.isAvailable();

    if (!isAvailable) {
      _showSnack("NFC not available ❌", Colors.red);
      return;
    }

    _showSnack("Tap NFC tag now...", Colors.blue);

    await NfcManager.instance.startSession(
      alertMessage: "Tap NFC tag to write Asset ID",
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);

          if (ndef == null) {
            throw Exception("NDEF not supported");
          }

          if (!ndef.isWritable) {
            throw Exception("Tag is read-only");
          }

          // ✅ CRITICAL FIX: Proper TEXT RECORD with encoding
          final textBytes = Uint8List.fromList(id.codeUnits);
          final languageCode = Uint8List.fromList('en'.codeUnits);

          final payload = Uint8List(1 + languageCode.length + textBytes.length);
          payload[0] = languageCode.length;
          payload.setRange(1, 1 + languageCode.length, languageCode);
          payload.setRange(1 + languageCode.length,
              1 + languageCode.length + textBytes.length, textBytes);

          final record = NdefRecord(
            typeNameFormat: NdefTypeNameFormat.nfcWellknown,
            type: Uint8List.fromList([0x54]), // "T"
            identifier: Uint8List(0),
            payload: payload,
          );

          final message = NdefMessage([record]);

          await ndef.write(message);

          await NfcManager.instance.stopSession();

          _showSnack("✅ Asset ID written successfully!", Colors.green);
        } catch (e) {
          await NfcManager.instance.stopSession(
            errorMessage: e.toString(),
          );

          _showSnack("❌ Write failed", Colors.red);
        }
      },
    );
  }

  // ================= ID CHECK =================
  void _onAssetIdChanged() {
    final value = assetId.text.trim();
    _debounce?.cancel();

    if (value.isEmpty) {
      setState(() {
        _isDuplicateId = false;
        _checkingId = false;
      });
      return;
    }

    setState(() => _checkingId = true);

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final snap = await FirebaseFirestore.instance
          .collection('assets')
          .doc(value)
          .get();

      if (!mounted) return;

      setState(() {
        _isDuplicateId = snap.exists;
        _checkingId = false;
      });
    });
  }

  // ================= VALIDATION =================
  bool _extraValidation() {
    if (_isDuplicateId) {
      _showSnack("Asset ID already exists", Colors.red);
      return false;
    }

    if (int.tryParse(yearsUsed.text.trim()) == null) {
      _showSnack("Years Used must be a number", Colors.orange);
      return false;
    }

    try {
      final p = _parseDate(purchaseDate.text);
      final l = _parseDate(lastuseddate.text);

      if (l.isBefore(p)) {
        _showSnack("Last used date cannot be before purchase date", Colors.red);
        return false;
      }
    } catch (e) {
      _showSnack("Invalid date format", Colors.orange);
      return false;
    }

    return true;
  }

  DateTime _parseDate(String d) {
    final parts = d.split("-");
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // ================= SUBMIT =================
  Future<void> _submit() async {
    if (!_isAdminUser) {
      _showSnack("Access Denied ❌ Admin only", Colors.red);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showSnack("Please fill all required fields", Colors.red);
      return;
    }

    if (!_extraValidation()) return;

    setState(() => _isLoading = true);

    try {
      final id = assetId.text.trim();

      await FirebaseFirestore.instance.collection('assets').doc(id).set({
        'assetId': id,
        'assetName': assetName.text.trim(),
        'category': category,
        'block': block,
        'purpose': functionality.text.trim(),
        'lastUsedPerson': lastUsedPerson.text.trim(),
        'incharge': incharge.text.trim(),
        'purchaseDate': purchaseDate.text.trim(),
        'lastUsedDate': lastuseddate.text.trim(),
        'yearsUsed': int.parse(yearsUsed.text.trim()),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await ActivityService.log(
        title: 'New asset added: ${assetName.text.trim()}',
        icon: 'inventory',
      );

      // ✅ ALWAYS write NFC (ADMIN ONLY SCREEN)
      await _writeToNfc(id);

      _formKey.currentState!.reset();
      assetId.clear();
      assetName.clear();
      functionality.clear();
      lastUsedPerson.clear();
      incharge.clear();
      yearsUsed.clear();
      purchaseDate.clear();
      lastuseddate.clear();
      category = null;
      block = null;

      setState(() {});
    } catch (e) {
      _showSnack("Error adding asset", Colors.red);
    }

    setState(() => _isLoading = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    // 🔴 BLOCK UI UNTIL ADMIN CHECK DONE
    if (_checkingAdmin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 🔴 BLOCK NON ADMIN
    if (!_isAdminUser) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Access Denied ❌\nAdmin Only Page",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F6FD6),
        elevation: 0,
        title: const Text("Add Asset"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Container(
                width: 380,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _header(),
                        _section("Asset Information"),
                        _label("Asset Name"),
                        _pillField(assetName, "Enter asset name"),
                        _label("Asset ID"),
                        _assetIdField(),
                        _label("Asset Type"),
                        _pillDropdown(
                            category,
                            ["Laptop", "Desktop", "Printer", "Monitor"],
                            (v) => setState(() => category = v)),
                        _label("Block"),
                        _pillDropdown(block, ["Block A", "Block B", "Block C"],
                            (v) => setState(() => block = v)),
                        _section("Usage Details"),
                        _label("Purpose"),
                        _pillField(functionality, "Enter purpose"),
                        _label("Last Used Person"),
                        _pillField(lastUsedPerson, "Enter name"),
                        _label("Incharge"),
                        _pillField(incharge, "Enter incharge"),
                        _section("Timeline"),
                        _label("Purchase Date"),
                        _pillDate(purchaseDate),
                        _label("Last Used Date"),
                        _pillDate(lastuseddate),
                        _label("Years Used"),
                        _pillField(yearsUsed, "Enter years",
                            keyboard: TextInputType.number),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                (_isLoading || _isDuplicateId) ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text("SUBMIT ASSET"),
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

  // ================= UI HELPERS =================
  Widget _header() => const Center(
        child: Column(
          children: [
            Icon(Icons.inventory_2, size: 48, color: Colors.deepPurple),
            SizedBox(height: 8),
            Text("Asset Registration",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text("Fill in the asset details carefully",
                style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
          ],
        ),
      );

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(t,
            style: const TextStyle(
                color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
      );

  Widget _label(String t) =>
      Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t));

  InputDecoration _pill(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
      );

  Widget _pillField(TextEditingController c, String hint,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        validator: (v) => v!.isEmpty ? "Required" : null,
        decoration: _pill(hint),
      ),
    );
  }

  Widget _pillDropdown(
      String? v, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField(
        value: v,
        decoration: _pill("Select"),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? "Required" : null,
      ),
    );
  }

  Widget _pillDate(TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        readOnly: true,
        validator: (v) => v!.isEmpty ? "Required" : null,
        decoration: _pill("Select date"),
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (d != null) {
            c.text = "${d.day}-${d.month}-${d.year}";
          }
        },
      ),
    );
  }

  Widget _assetIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: assetId,
          decoration: _pill("Enter asset ID").copyWith(
            suffixIcon: _checkingId
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          validator: (v) => v!.isEmpty ? "Required" : null,
        ),
        if (_isDuplicateId)
          const Padding(
            padding: EdgeInsets.only(left: 12, top: 6),
            child: Text(
              "Asset ID already exists",
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
