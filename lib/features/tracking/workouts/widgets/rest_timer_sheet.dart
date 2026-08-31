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
  // Deadline-based rather than decrementing a counter each tick: the
  // remaining time is always `deadline - now`, so it stays correct even if
  // the app is backgrounded/throttled and misses ticks — a `Timer.periodic`
  // that just subtracts 1 each call would drift or freeze in that case.
  late DateTime _deadline = DateTime.now().add(
    Duration(seconds: widget.initialSeconds),
  );
  Duration _pausedRemaining = Duration.zero;
  Timer? _ticker;
  bool _paused = false;
  bool _finished = false;

  int get _remainingSeconds {
    if (_paused) return _pausedRemaining.inSeconds;
    final remaining = _deadline.difference(DateTime.now());
    return remaining.isNegative ? 0 : remaining.inSeconds;
  }

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_paused) return;
      if (_remainingSeconds <= 0 && !_finished) {
        _finished = true;
        HapticFeedback.mediumImpact();
        _ticker?.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) Navigator.pop(context);
        });
      }
      setState(() {});
    });
  }

  void _addSeconds(int amount) {
    setState(() {
      if (_paused) {
        _pausedRemaining = Duration(
          seconds: (_pausedRemaining.inSeconds + amount).clamp(0, 3600),
        );
      } else {
        _deadline = _deadline.add(Duration(seconds: amount));
      }
    });
  }

  void _togglePause() {
    setState(() {
      if (_paused) {
        // Resuming: rebuild the deadline from however much time was left.
        _deadline = DateTime.now().add(_pausedRemaining);
        _paused = false;
      } else {
        _pausedRemaining = Duration(seconds: _remainingSeconds);
        _paused = true;
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
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
              _format(_remainingSeconds),
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
                  onPressed: _togglePause,
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
