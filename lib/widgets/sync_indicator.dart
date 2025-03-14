import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_provider.dart';
import '../services/sync_service.dart';

class SyncIndicator extends ConsumerStatefulWidget {
  const SyncIndicator({super.key});

  @override
  ConsumerState<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends ConsumerState<SyncIndicator> {
  Timer? _successTimer;
  bool _showSuccess = false; // Start as false
  SyncStatus? _previousStatus;

  @override
  void dispose() {
    _successTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncStatusAsync = ref.watch(syncStatusProvider);

    return syncStatusAsync.when(
      data: (status) {
        // Reset success flag when sync state changes to syncing
        if (status == SyncStatus.syncing) {
          _successTimer?.cancel();
          if (!_showSuccess) {
            setState(() {
              _showSuccess = true;
            });
          }
        }

        // Only start timer when transitioning to synced state
        if (status == SyncStatus.synced &&
            _previousStatus != SyncStatus.synced) {
          setState(() {
            _showSuccess = true;
          });

          _successTimer?.cancel();
          _successTimer = Timer(const Duration(seconds: 10), () {
            if (mounted) {
              setState(() {
                _showSuccess = false;
              });
            }
          });
        }

        // Update previous status after handling the current one
        _previousStatus = status;

        switch (status) {
          case SyncStatus.syncing:
            return const Tooltip(
              message: 'Syncing with server...',
              child: Icon(Icons.sync, color: Colors.amber),
            );
          case SyncStatus.synced:
            return _showSuccess
                ? const Tooltip(
                    message: 'All changes synced',
                    child: Icon(Icons.cloud_done, color: Colors.green),
                  )
                : const SizedBox.shrink(); // Hide after timer expires
          case SyncStatus.offline:
            return const Tooltip(
              message:
                  'You\'re offline. Changes will sync when connection returns',
              child: Icon(Icons.cloud_off, color: Colors.grey),
            );
          case SyncStatus.error:
            return const Tooltip(
              message: 'Sync error. Will retry automatically',
              child: Icon(Icons.sync_problem, color: Colors.red),
            );
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const Icon(Icons.warning, color: Colors.red),
    );
  }
}
