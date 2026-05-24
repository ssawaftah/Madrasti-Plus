import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

import '../../core/data/mock_database.dart';
import '../../core/services/auth_service.dart';

class GateHomeScreen extends StatefulWidget {
  const GateHomeScreen({super.key});

  @override
  State<GateHomeScreen> createState() => _GateHomeScreenState();
}

class _GateHomeScreenState extends State<GateHomeScreen> {
  bool _isNfcSessionActive = false;
  bool _isProcessingCard = false;
  _GateScanState _scanState = _GateScanState.ready;
  String _title = 'Madrasti Plus Gate';
  String _message = 'Touch your school card';
  String? _studentName;
  DateTime? _lastScanAt;
  Timer? _resetTimer;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoNfcScan();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
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
        _title = 'NFC Offline';
        _message = 'فعّل NFC على الجهاز ثم أعد المحاولة';
        _studentName = null;
      });
      return;
    }

    setState(() {
      _isNfcSessionActive = true;
      _scanState = _GateScanState.ready;
      _title = 'Madrasti Plus Gate';
      _message = 'Touch your school card';
      _studentName = null;
      _lastScanAt = null;
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
            _showErrorAndRestart('Card unreadable');
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
        _title = 'Reader Error';
        _message = 'تعذر تشغيل قارئ NFC';
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
      _showErrorAndRestart('Unregistered card');
      return;
    }

    final isCheckIn = record.isCheckIn;

    setState(() {
      _scanState = isCheckIn ? _GateScanState.checkIn : _GateScanState.checkOut;
      _title = isCheckIn ? 'تم تسجيل الحضور' : 'تم تسجيل الخروج';
      _message = isCheckIn ? 'Welcome to school' : 'See you tomorrow';
      _studentName = record.studentName;
      _lastScanAt = record.timestamp;
    });

    _restartAfterResult();
  }

  void _showErrorAndRestart(String message) {
    setState(() {
      _scanState = _GateScanState.error;
      _title = 'Access Denied';
      _message = message;
      _studentName = null;
      _lastScanAt = DateTime.now();
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

  List<Color> _backgroundGradient() {
    switch (_scanState) {
      case _GateScanState.ready:
        return const [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF1D4ED8)];
      case _GateScanState.checkIn:
        return const [Color(0xFF052E16), Color(0xFF15803D), Color(0xFF22C55E)];
      case _GateScanState.checkOut:
        return const [Color(0xFF450A0A), Color(0xFFB91C1C), Color(0xFFEF4444)];
      case _GateScanState.error:
        return const [Color(0xFF451A03), Color(0xFFB45309), Color(0xFFF59E0B)];
    }
  }

  IconData _mainIcon() {
    switch (_scanState) {
      case _GateScanState.ready:
        return Icons.contactless;
      case _GateScanState.checkIn:
        return Icons.verified_rounded;
      case _GateScanState.checkOut:
        return Icons.logout_rounded;
      case _GateScanState.error:
        return Icons.gpp_maybe_rounded;
    }
  }

  String _statusLabel() {
    switch (_scanState) {
      case _GateScanState.ready:
        return 'ONLINE';
      case _GateScanState.checkIn:
        return 'CHECK-IN';
      case _GateScanState.checkOut:
        return 'CHECK-OUT';
      case _GateScanState.error:
        return 'ATTENTION';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _backgroundGradient();
    final timeText = _formatTime(_now);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: -90,
                  left: -70,
                  child: _GlowCircle(size: 210, opacity: 0.18),
                ),
                Positioned(
                  bottom: -120,
                  right: -90,
                  child: _GlowCircle(size: 260, opacity: 0.12),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.18)),
                            ),
                            child: const Icon(
                              Icons.door_sliding_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Madrasti Plus',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              Text(
                                'Gate Access Terminal',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          _StatusPill(label: _statusLabel()),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            color: const Color(0xFF0F172A),
                            onSelected: (value) {
                              if (value == 'refresh') {
                                _startAutoNfcScan();
                              } else if (value == 'logout') {
                                AuthService().signOut();
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'refresh',
                                child: Text('إعادة تشغيل القارئ'),
                              ),
                              PopupMenuItem(
                                value: 'logout',
                                child: Text('تسجيل الخروج'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        timeText,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: 42,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _AccessOrb(
                        icon: _mainIcon(),
                        state: _scanState,
                      ),
                      const SizedBox(height: 38),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Column(
                          key: ValueKey('$_scanState-$_studentName-$_title'),
                          children: [
                            Text(
                              _title,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                height: 1.12,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (_studentName != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.22),
                                  ),
                                ),
                                child: Text(
                                  _studentName!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            Text(
                              _message,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.82),
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_lastScanAt != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Recorded at ${_formatTime(_lastScanAt!)}',
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.72),
                                  fontSize: 13,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Spacer(),
                      _BottomGlassPanel(
                        isActive: _isNfcSessionActive,
                        studentsCount: MockDatabase.students.length,
                      ),
                    ],
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

class _AccessOrb extends StatelessWidget {
  final IconData icon;
  final _GateScanState state;

  const _AccessOrb({required this.icon, required this.state});

  @override
  Widget build(BuildContext context) {
    final isReady = state == _GateScanState.ready;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (isReady) ...[
          _Ring(size: 260, opacity: 0.08),
          _Ring(size: 218, opacity: 0.12),
        ],
        Container(
          width: 174,
          height: 174,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(0.28),
                Colors.white.withOpacity(0.10),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.26), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.24),
                blurRadius: 40,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 92),
        ),
      ],
    );
  }
}

class _BottomGlassPanel extends StatelessWidget {
  final bool isActive;
  final int studentsCount;

  const _BottomGlassPanel({required this.isActive, required this.studentsCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          _MiniMetric(
            icon: Icons.wifi_tethering_rounded,
            label: isActive ? 'Active' : 'Paused',
          ),
          const Spacer(),
          _MiniMetric(
            icon: Icons.groups_rounded,
            label: '$studentsCount Students',
          ),
          const Spacer(),
          const _MiniMetric(
            icon: Icons.lock_rounded,
            label: 'Secure Gate',
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniMetric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.82), size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            color: Colors.white.withOpacity(0.82),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Text(
        label,
        textDirection: TextDirection.ltr,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _GlowCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double size;
  final double opacity;

  const _Ring({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(opacity), width: 2),
      ),
    );
  }
}

enum _GateScanState {
  ready,
  checkIn,
  checkOut,
  error,
}
