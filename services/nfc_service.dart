import 'dart:async';
import 'package:nfc_manager/nfc_manager.dart';

class NFCService {
  /// Check if NFC is available
  static Future<bool> isAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  /// Scan NFC Tag and return UID
  static Future<String?> scanTag() async {
    Completer<String?> completer = Completer<String?>();

    await NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        try {
          final data = tag.data as Map;

          List<int>? identifier;

          if (data.containsKey('nfca')) {
            identifier = List<int>.from(
              (data['nfca'] as Map)['identifier'] as List,
            );
          } else if (data.containsKey('mifareclassic')) {
            identifier = List<int>.from(
              (data['mifareclassic'] as Map)['identifier'] as List,
            );
          } else if (data.containsKey('mifareultralight')) {
            identifier = List<int>.from(
              (data['mifareultralight'] as Map)['identifier'] as List,
            );
          }

          String? uid;

          if (identifier != null) {
            uid = identifier
                .map((e) => e.toRadixString(16).padLeft(2, '0'))
                .join(':')
                .toUpperCase();
          }

          await NfcManager.instance.stopSession();

          completer.complete(uid);
        } catch (e) {
          await NfcManager.instance.stopSession();
          completer.complete(null);
        }
      },
    );

    return completer.future;
  }

  /// Stop NFC session manually
  static Future<void> stop() async {
    await NfcManager.instance.stopSession();
  }
}
