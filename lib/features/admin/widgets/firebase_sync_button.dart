import 'package:flutter/material.dart';

import '../../../core/data/mock_database.dart';
import '../../../core/services/firestore_database_service.dart';

class FirebaseSyncButton extends StatefulWidget {
  const FirebaseSyncButton({super.key});

  @override
  State<FirebaseSyncButton> createState() => _FirebaseSyncButtonState();
}

class _FirebaseSyncButtonState extends State<FirebaseSyncButton> {
  final _firestoreService = FirestoreDatabaseService();
  bool _isSyncing = false;

  Future<void> _syncLocalDataToFirebase() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      await _firestoreService.syncLocalData(
        students: MockDatabase.students,
        attendanceRecords: MockDatabase.attendanceRecords,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت مزامنة البيانات مع Firebase بنجاح')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشلت المزامنة مع Firebase: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _isSyncing ? null : _syncLocalDataToFirebase,
      icon: _isSyncing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.cloud_upload),
      label: Text(
        _isSyncing ? 'جاري المزامنة...' : 'مزامنة البيانات مع Firebase',
      ),
    );
  }
}
