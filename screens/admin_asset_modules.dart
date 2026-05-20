import 'package:flutter/material.dart';

/// =====================
/// ADD ASSET PAGE
/// =====================
class AddAssetPage extends StatefulWidget {
  const AddAssetPage({super.key});

  @override
  State<AddAssetPage> createState() => _AddAssetPageState();
}

class _AddAssetPageState extends State<AddAssetPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController assetIdCtrl = TextEditingController();
  final TextEditingController assetNameCtrl = TextEditingController();
  final TextEditingController categoryCtrl = TextEditingController();
  final TextEditingController blockCtrl = TextEditingController();
  final TextEditingController functionalityCtrl = TextEditingController();
  final TextEditingController lastUsedPersonCtrl = TextEditingController();
  final TextEditingController inchargeCtrl = TextEditingController();
  final TextEditingController yearsUsedCtrl = TextEditingController();

  DateTime? purchaseDate;
  DateTime? lastUsedDate;

  Future<void> _pickDate(BuildContext context, bool isPurchase) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        isPurchase ? purchaseDate = picked : lastUsedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Asset"),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _field(assetIdCtrl, "Asset ID", Icons.qr_code),
                    _field(assetNameCtrl, "Asset Name", Icons.inventory),
                    _field(categoryCtrl, "Category", Icons.category),
                    _field(blockCtrl, "Block / Location", Icons.location_on),
                    _field(
                      functionalityCtrl,
                      "Functionality Details",
                      Icons.settings,
                    ),
                    _field(
                      lastUsedPersonCtrl,
                      "Last Used Person",
                      Icons.person,
                    ),
                    _field(inchargeCtrl, "Asset Incharge", Icons.badge),
                    _field(
                      yearsUsedCtrl,
                      "Years Used",
                      Icons.timelapse,
                      keyboard: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _dateTile(
                      "Purchase Date",
                      purchaseDate,
                      () => _pickDate(context, true),
                    ),
                    _dateTile(
                      "Last Used Date",
                      lastUsedDate,
                      () => _pickDate(context, false),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("Save Asset"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Asset Added Successfully"),
                              ),
                            );
                          }
                        },
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
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: (v) => v!.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _dateTile(String title, DateTime? date, VoidCallback onTap) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Colors.blue.shade50,
      title: Text(title),
      subtitle: Text(
        date == null ? "Select date" : date.toLocal().toString().split(' ')[0],
      ),
      trailing: const Icon(Icons.calendar_month),
      onTap: onTap,
    );
  }
}

/// =====================
/// DUMMY PAGES (CLEAN)
/// =====================
class IssueAssetPage extends StatelessWidget {
  const IssueAssetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _simplePage("Issue Assets");
  }
}

class AddUserPage extends StatelessWidget {
  const AddUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _simplePage("Add Users");
  }
}

class AssetRequestPage extends StatelessWidget {
  const AssetRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _simplePage("New Asset Requests");
  }
}

class DeleteAssetPage extends StatelessWidget {
  const DeleteAssetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _simplePage("Delete Assets");
  }
}

Widget _simplePage(String title) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Text("$title Page", style: const TextStyle(fontSize: 18)),
    ),
  );
}
