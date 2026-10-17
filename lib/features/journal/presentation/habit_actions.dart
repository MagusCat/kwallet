import 'package:flutter/material.dart';

import '../models/journal_models.dart';
import 'journal_sheets.dart';

Future<void> editHabit(BuildContext context, {Habit? habit}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => HabitSheet(initial: habit?.title ?? '', habit: habit),
  );
}
