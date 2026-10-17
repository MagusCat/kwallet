import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/mvvm/view_model_state.dart';
import '../view_models/journal_actions_view_model.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/finance_widgets.dart';
import '../models/journal_models.dart';
import 'journal_sheets.dart';

class NotePreview extends StatefulWidget {
  final PersonalNote note;
  const NotePreview({super.key, required this.note});
  @override
  State<NotePreview> createState() => _NotePreviewState();
}

class _NotePreviewState
    extends ViewModelState<NotePreview, JournalActionsViewModel> {
  @override
  JournalActionsViewModel createViewModel(AppDependencies dependencies) =>
      dependencies.journalActions();
  bool get _busy => model.busy;
  Future<void> _check(int index, bool done) async {
    if (await model.checkNote(widget.note, index, done)) {
      HapticFeedback.selectionClick();
    } else if (mounted) {
      showFailure(context, model.error ?? 'No se pudo actualizar la lista.');
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: LedgerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              widget.note.kind == 'list'
                  ? Icons.checklist_rounded
                  : Icons.edit_note_rounded,
              color: KwallTheme.accent,
            ),
            title: Text(
              widget.note.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: KwallTheme.fontTitle,
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => NoteSheet(note: widget.note),
            ),
          ),
          if (widget.note.body.isNotEmpty)
            Text(
              widget.note.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          for (var i = 0; i < widget.note.items.length && i < 3; i++)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: widget.note.items[i].done,
              title: Text(
                widget.note.items[i].text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  decoration: widget.note.items[i].done
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              onChanged: _busy ? null : (value) => _check(i, value!),
            ),
          if (widget.note.items.length > 3)
            Text(
              '+${widget.note.items.length - 3} en la lista',
              style: TextStyle(color: KwallTheme.textSecondary, fontSize: 12),
            ),
        ],
      ),
    ),
  );
}
