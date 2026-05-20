import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityService {
  static Future<void> log({required String title, required String icon}) async {
    await FirebaseFirestore.instance.collection('activities').add({
      'title': title,
      'icon': icon, // assign | issue | resolve | inventory
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
