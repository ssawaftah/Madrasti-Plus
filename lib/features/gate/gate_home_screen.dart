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
  final _nfcUidController = TextEditingController();
  bool _isNfcSessionActive = false;

  @override
  void dispose() {
    _stopNfcSession();
    _nfcUidController.dispose();
    super.dispose();
  }

  void _simulateScanByStudentId(String studentId) {
    final record = MockDatabase.toggleStudentAttendance(studentId);
    _showScanResult(record);
  }

  void _simulateScanByNfcUid() {
    final uid = _nfcUidController.text.trim();

    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل NFC UID أولًا')),
      );
      return;
    }

    _processNfcUid(uid, clearInput: true);
  }

  Future<void> _startRealNfcScan() async {
    final isAvailable = await NfcManager.instance.isAvailable();

    if (!isAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC غير متاح أو غير مفعّل على هذا الجهاز')),
      );
      return;
    }

    setState(() {
      _isNfcSessionActive = true;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قرّب بطاقة NFC من الهاتف الآن')),
    );

    await NfcManager.instance.startSession(
      pollingOptions: {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
        NfcPollingOption.iso18092,
      },
      onDiscovered: (NfcTag tag) async {
        final uid = _extractUidFromTag(tag);

        await _stopNfcSession();

        if (!mounted) return;

        if (uid == null || uid.isEmpty) {
          _showNfcDebugDialog(tag.data);
          return;
        }

        _nfcUidController.text = uid;
        _processNfcUid(uid, clearInput: false);
      },
    );
  }

  Future<void> _stopNfcSession() async {
    if (!_isNfcSessionActive) return;

    try {
      await NfcManager.instance.stopSession();
    } catch (_) {
      // Ignore stop errors during hot reload/navigation.
    }

    if (mounted) {
      setState(() {
        _isNfcSessionActive = false;
      });
    } else {
      _isNfcSessionActive = false;
    }
  }

  void _processNfcUid(String uid, {required bool clearInput}) {
    final record = MockDatabase.toggleStudentAttendanceByNfcUid(uid);

    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لم يتم العثور على طالب مرتبط بهذا UID: $uid')),
      );
      return;
    }

    if (clearInput) {
      _nfcUidController.clear();
    }

    _showScanResult(record);
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

  void _showNfcDebugDialog(Object? rawData) {
    final rawText = rawData.toString();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تمت قراءة البطاقة بدون UID واضح'),
            content: SingleChildScrollView(
              child: SelectableText(
                rawText,
                textDirection: TextDirection.ltr,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        );
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('انسخ بيانات البطاقة من النافذة وأرسلها لي لو لم يظهر UID'),
      ),
    );
  }

  void _showScanResult(dynamic record) {
    if (record == null) return;

    setState(() {});

    final message = record.isCheckIn
        ? 'تم تسجيل دخول ${record.studentName}'
        : 'تم تسجيل خروج ${record.studentName}';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final students = MockDatabase.students;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الحارس - NFC'), centerTitle: true),
        body: students.isEmpty
            ? const Center(
                child: Text(
                  'لا يوجد طلاب بعد. أضف طالب من شاشة الإدارة أولًا.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'مسح بطاقة الطالب',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'يمكنك قراءة بطاقة NFC حقيقية أو إدخال UID يدويًا للتجربة.',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),

                  FilledButton.icon(
                    onPressed: _isNfcSessionActive ? null : _startRealNfcScan,
                    icon: const Icon(Icons.sensors),
                    label: Text(
                      _isNfcSessionActive
                          ? 'بانتظار البطاقة...'
                          : 'قراءة NFC حقيقي',
                    ),
                  ),
                  if (_isNfcSessionActive) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _stopNfcSession,
                      icon: const Icon(Icons.close),
                      label: const Text('إلغاء القراءة'),
                    ),
                  ],
                  const SizedBox(height: 16),

                  TextField(
                    controller: _nfcUidController,
                    decoration: const InputDecoration(
                      labelText: 'NFC UID',
                      hintText: 'مثال: 04A1B2C3D4',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _simulateScanByNfcUid(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _simulateScanByNfcUid,
                    icon: const Icon(Icons.nfc),
                    label: const Text('مسح UID تجريبي'),
                  ),

                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 16),

                  const Text(
                    'اختبار سريع بدون UID',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'هذا الخيار مؤقت للتجربة السريعة أثناء التطوير.',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),

                  ...students.map((student) {
                    final statusText = student.isInsideSchool
                        ? 'داخل المدرسة'
                        : 'خارج المدرسة';

                    final lastScanText = student.lastAttendanceAt == null
                        ? 'لا يوجد تسجيل بعد'
                        : 'آخر تسجيل: ${_formatTime(student.lastAttendanceAt!)}';

                    final uidText = student.nfcUid == null
                        ? 'لا يوجد UID مرتبط'
                        : 'UID: ${student.nfcUid}';

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          student.isInsideSchool ? Icons.login : Icons.logout,
                        ),
                        title: Text(student.fullName),
                        subtitle: Text(
                          'الحالة: $statusText\n$uidText\n$lastScanText',
                        ),
                        isThreeLine: true,
                        trailing: FilledButton(
                          onPressed: () => _simulateScanByStudentId(student.id),
                          child: const Text('مسح تجريبي'),
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }
}
