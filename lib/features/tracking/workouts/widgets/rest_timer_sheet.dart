import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows a countdown rest-timer bottom sheet. Dismisses itself on skip, on
/// reaching zero (with haptic feedback), or if the user swipes it away.
void showRestTimerSheet(BuildContext context, {int seconds = 90}) {
  showModalBottomSheet(
    context: context,
    isDismissible: true,
    enableDrag: true,
    builder: (context) => _RestTimerSheet(initialSeconds: seconds),
  );
}

class _RestTimerSheet extends StatefulWidget {
  final int initialSeconds;

  const _RestTimerSheet({required this.initialSeconds});

  @override
  State<_RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends State<_RestTimerSheet> {
  late int _remaining = widget.initialSeconds;
  Timer? _timer;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      if (_remaining <= 1) {
        setState(() => _remaining = 0);
        HapticFeedback.mediumImpact();
        _timer?.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) Navigator.pop(context);
        });
        return;
      }
      setState(() => _remaining -= 1);
    });
  }

  void _addSeconds(int amount) {
    setState(() => _remaining = (_remaining + amount).clamp(0, 3600));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rest Timer', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              _format(_remaining),
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => _addSeconds(15),
                  child: const Text('+15s'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _addSeconds(30),
                  child: const Text('+30s'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => setState(() => _paused = !_paused),
                  child: Text(_paused ? 'Resume' : 'Pause'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip'),
            ),
          ],
        ),
      ),
    );
  }
}
