import 'package:cloud_firestore/cloud_firestore.dart';

class AssetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addAsset({
    required String assetId,
    required String assetName,
    required String category,
    required String block,
    required String purpose,
    required String lastUsedPerson,
    required String incharge,
    required String purchaseDate,
    required String lastUsedDate,
    required int yearsUsed,
  }) async {
    await _firestore.collection('assets').add({
      'assetId': assetId,
      'assetName': assetName,
      'category': category,
      'block': block,
      'purpose': purpose,
      'lastUsedPerson': lastUsedPerson,
      'incharge': incharge,
      'purchaseDate': purchaseDate,
      'lastUsedDate': lastUsedDate,
      'yearsUsed': yearsUsed,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
