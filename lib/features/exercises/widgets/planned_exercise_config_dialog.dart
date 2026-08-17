import 'package:flutter/material.dart';

import '../../../models/workout_plan.dart';

/// Dialog for editing a planned exercise's sets/reps/rest. Returns the
/// updated [PlannedExercise], or null if cancelled.
Future<PlannedExercise?> showPlannedExerciseConfigDialog(
  BuildContext context,
  PlannedExercise planned,
) {
  return showDialog<PlannedExercise>(
    context: context,
    builder: (context) => _PlannedExerciseConfigDialog(planned: planned),
  );
}

class _PlannedExerciseConfigDialog extends StatefulWidget {
  final PlannedExercise planned;

  const _PlannedExerciseConfigDialog({required this.planned});

  @override
  State<_PlannedExerciseConfigDialog> createState() =>
      _PlannedExerciseConfigDialogState();
}

class _PlannedExerciseConfigDialogState
    extends State<_PlannedExerciseConfigDialog> {
  late int _sets = widget.planned.sets;
  late int _targetReps = widget.planned.targetReps;
  late bool _isTimed = widget.planned.isTimed;
  late int _restSeconds = widget.planned.restSeconds;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.planned.exerciseName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _sets.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sets'),
                  onChanged: (v) => _sets = int.tryParse(v) ?? _sets,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: _targetReps.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _isTimed ? 'Seconds' : 'Reps',
                  ),
                  onChanged:
                      (v) => _targetReps = int.tryParse(v) ?? _targetReps,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Timed (e.g. plank)'),
            value: _isTimed,
            onChanged: (v) => setState(() => _isTimed = v),
          ),
          TextFormField(
            initialValue: _restSeconds.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Rest between sets (seconds)',
            ),
            onChanged: (v) => _restSeconds = int.tryParse(v) ?? _restSeconds,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed:
              () => Navigator.pop(
                context,
                widget.planned.copyWith(
                  sets: _sets,
                  targetReps: _targetReps,
                  isTimed: _isTimed,
                  restSeconds: _restSeconds,
                ),
              ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
