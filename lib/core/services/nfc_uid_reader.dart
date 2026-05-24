import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

class NfcUidReader {
  const NfcUidReader._();

  static String? extractUid(NfcTag tag) {
    final androidTag = NfcTagAndroid.from(tag);
    final androidUid = _bytesToHex(androidTag?.id);

    if (_looksLikeUid(androidUid)) return androidUid;

    final tagData = tag.data;

    if (tagData is! Map) return null;

    final uid = _findUidCandidate(tagData);
    return uid == null || uid.isEmpty ? null : uid;
  }

  static String? _findUidCandidate(dynamic value) {
    if (value == null) return null;

    final directHex = _bytesToHex(value);
    if (_looksLikeUid(directHex)) return directHex;

    if (value is Map) {
      const preferredKeys = [
        'identifier',
        'id',
        'uid',
        'serialNumber',
        'tagId',
        'manufacturerId',
      ];

      for (final key in preferredKeys) {
        if (value.containsKey(key)) {
          final uid = _findUidCandidate(value[key]);
          if (_looksLikeUid(uid)) return uid;
        }
      }

      for (final entry in value.entries) {
        final key = entry.key.toString().toLowerCase();
        final isLikelyUidKey = key.contains('identifier') ||
            key == 'id' ||
            key.contains('uid') ||
            key.contains('serial') ||
            key.contains('tagid');

        if (!isLikelyUidKey) continue;

        final uid = _findUidCandidate(entry.value);
        if (_looksLikeUid(uid)) return uid;
      }

      for (final entry in value.entries) {
        final uid = _findUidCandidate(entry.value);
        if (_looksLikeUid(uid)) return uid;
      }
    }

    if (value is List) {
      for (final item in value) {
        final uid = _findUidCandidate(item);
        if (_looksLikeUid(uid)) return uid;
      }
    }

    return null;
  }

  static bool _looksLikeUid(String? value) {
    if (value == null || value.isEmpty) return false;

    final normalized = value.replaceAll(RegExp(r'[^A-Fa-f0-9]'), '');
    return normalized.length >= 8 && normalized.length <= 20;
  }

  static String? _bytesToHex(dynamic value) {
    if (value == null) return null;

    List<int>? bytes;

    if (value is Uint8List) {
      bytes = value.toList();
    } else if (value is List<int>) {
      bytes = value;
    } else if (value is List) {
      bytes = value.whereType<int>().toList();
    } else if (value is String) {
      final normalized = value.replaceAll(RegExp(r'[^A-Fa-f0-9]'), '');
      if (normalized.length >= 8 && normalized.length.isEven) {
        return normalized.toUpperCase();
      }
    }

    if (bytes == null || bytes.isEmpty) return null;

    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }
}
