import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

import '../../core/data/mock_database.dart';

class GateHomeScreen extends StatefulWidget {
  const GateHomeScreen({super.key});

  @override
  State<GateHomeScreen> createState() => _GateHomeScreenState();
}

class _GateHomeScreenState extends State<GateHomeScreen> {
  bool _isNfcSessionActive = false;
  bool _isProcessingCard = false;
  _GateScanState _scanState = _GateScanState.waiting;
  String _title = 'امسح بطاقة الطالب';
  String _message = 'قرّب بطاقة الطالب من قارئ NFC عند البوابة';
  String? _studentName;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoNfcScan();
    });
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _stopNfcSession();
    super.dispose();
  }

  Future<void> _startAutoNfcScan() async {
    if (_isNfcSessionActive || _isProcessingCard) return;

    final isAvailable = await NfcManager.instance.isAvailable();

    if (!mounted) return;

    if (!isAvailable) {
      setState(() {
        _scanState = _GateScanState.error;
        _title = 'NFC غير متاح';
        _message = 'تأكد أن NFC مفعّل وأن الجهاز يدعم القراءة';
        _studentName = null;
      });
      return;
    }

    setState(() {
      _isNfcSessionActive = true;
      _scanState = _GateScanState.waiting;
      _title = 'امسح بطاقة الطالب';
      _message = 'قرّب البطاقة من الجهاز لتسجيل الدخول أو الخروج';
      _studentName = null;
    });

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          if (_isProcessingCard) return;

          _isProcessingCard = true;
          final uid = _extractUidFromTag(tag);

          await _stopNfcSession();

          if (!mounted) return;

          if (uid == null || uid.isEmpty) {
            _showErrorAndRestart('لم أستطع قراءة UID من البطاقة');
            return;
          }

          _processNfcUid(uid);
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isNfcSessionActive = false;
        _isProcessingCard = false;
        _scanState = _GateScanState.error;
        _title = 'تعذر تشغيل قارئ NFC';
        _message = error.toString();
        _studentName = null;
      });
    }
  }

  Future<void> _stopNfcSession() async {
    if (!_isNfcSessionActive) return;

    try {
      await NfcManager.instance.stopSession();
    } catch (_) {
      // Ignore stop errors during navigation/hot restart.
    }

    if (mounted) {
      setState(() {
        _isNfcSessionActive = false;
      });
    } else {
      _isNfcSessionActive = false;
    }
  }

  void _processNfcUid(String uid) {
    final record = MockDatabase.toggleStudentAttendanceByNfcUid(uid);

    if (record == null) {
      _showErrorAndRestart('هذه البطاقة غير مرتبطة بأي طالب');
      return;
    }

    final isCheckIn = record.isCheckIn;

    setState(() {
      _scanState = isCheckIn ? _GateScanState.checkIn : _GateScanState.checkOut;
      _title = isCheckIn ? 'تم تسجيل حضورك بنجاح' : 'تم تسجيل خروجك بنجاح';
      _message = isCheckIn ? 'أهلًا وسهلًا، يوم موفق' : 'يعطيك العافية، نراك لاحقًا';
      _studentName = record.studentName;
    });

    _restartAfterResult();
  }

  void _showErrorAndRestart(String message) {
    setState(() {
      _scanState = _GateScanState.error;
      _title = 'لم تتم العملية';
      _message = message;
      _studentName = null;
    });

    _restartAfterResult();
  }

  void _restartAfterResult() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _isProcessingCard = false;
      _startAutoNfcScan();
    });
  }

  String? _extractUidFromTag(NfcTag tag) {
    final androidTag = NfcTagAndroid.from(tag);
    final androidUid = _bytesToHex(androidTag?.id);

    if (_looksLikeUid(androidUid)) return androidUid;

    final tagData = tag.data;

    if (tagData is! Map) return null;

    final uid = _findUidCandidate(tagData);
    return uid == null || uid.isEmpty ? null : uid;
  }

  String? _findUidCandidate(dynamic value) {
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

  bool _looksLikeUid(String? value) {
    if (value == null || value.isEmpty) return false;

    final normalized = value.replaceAll(RegExp(r'[^A-Fa-f0-9]'), '');
    return normalized.length >= 8 && normalized.length <= 20;
  }

  String? _bytesToHex(dynamic value) {
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

  Color _backgroundColor() {
    switch (_scanState) {
      case _GateScanState.waiting:
        return const Color(0xFF0F172A);
      case _GateScanState.checkIn:
        return const Color(0xFF16A34A);
      case _GateScanState.checkOut:
        return const Color(0xFFDC2626);
      case _GateScanState.error:
        return const Color(0xFF92400E);
    }
  }

  IconData _mainIcon() {
    switch (_scanState) {
      case _GateScanState.waiting:
        return Icons.nfc;
      case _GateScanState.checkIn:
        return Icons.check_circle;
      case _GateScanState.checkOut:
        return Icons.logout;
      case _GateScanState.error:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _backgroundColor(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.door_front_door, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      'جهاز بوابة Madrasti Plus',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _isNfcSessionActive ? null : _startAutoNfcScan,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'إعادة تشغيل القراءة',
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
                  ),
                  child: Icon(
                    _mainIcon(),
                    color: Colors.white,
                    size: 96,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (_studentName != null) ...[
                  Text(
                    _studentName!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 18,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                if (_scanState == _GateScanState.waiting)
                  const _PulsingHint(),
                const Spacer(),
                Text(
                  _isNfcSessionActive ? 'القارئ يعمل الآن' : 'القارئ متوقف مؤقتًا',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingHint extends StatelessWidget {
  const _PulsingHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'بانتظار البطاقة...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

enum _GateScanState {
  waiting,
  checkIn,
  checkOut,
  error,
}
