import 'package:flutter/material.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../view_models/home_view_model.dart';

import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../../../journal/presentation/journal_sheets.dart';
import '../../../journal/presentation/habit_check_in.dart';
import '../../../journal/presentation/note_preview.dart';
import '../../models/account.dart';
import 'account_card.dart';

class HomeHub extends StatefulWidget {
  final HomeViewModel controller;
  final VoidCallback onAddAccount;
  final ValueChanged<Account> onEditAccount;
  final ValueChanged<int> onJournal;
  const HomeHub({
    super.key,
    required this.controller,
    required this.onAddAccount,
    required this.onEditAccount,
    required this.onJournal,
  });
  @override
  State<HomeHub> createState() => _HomeHubState();
}

class _HomeHubState extends State<HomeHub> {
  int _homeTab = 0;
  DateTime? _selectedDay;
  DateTime get _habitDay => _selectedDay ?? DateTime.now();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (index, icon, label) in [
            (0, Icons.account_balance_wallet_outlined, 'Cuentas'),
            (1, Icons.edit_note_rounded, 'Notas'),
            (2, Icons.spa_outlined, 'Hábitos'),
          ])
            ChoiceChip(
              avatar: Icon(icon, size: 18),
              showCheckmark: false,
              label: Text(label),
              selected: _homeTab == index,
              onSelected: (_) {
                HapticFeedback.selectionClick();
                setState(() => _homeTab = index);
              },
            ),
        ],
      ),
      const SizedBox(height: 12),
      AnimatedSwitcher(
        duration: Duration(
          milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 180,
        ),
        child: KeyedSubtree(
          key: ValueKey(_homeTab),
          child: switch (_homeTab) {
            1 => _homeNotes(),
            2 => _homeHabits(),
            _ => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mis cuentas',
                        style: KwallTheme.fontTitle.copyWith(fontSize: 21),
                      ),
                    ),
                    if (widget.controller.filter != null)
                      IconButton(
                        tooltip: 'Ver todas',
                        onPressed: () {
                          widget.controller.selectAccount(null);
                        },
                        icon: const Icon(Icons.filter_alt_off_outlined),
                      ),
                    IconButton.filledTonal(
                      tooltip: 'Nueva cuenta',
                      onPressed: widget.onAddAccount,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.controller.accounts.isEmpty)
                  TextButton.icon(
                    onPressed: widget.onAddAccount,
                    icon: const Icon(Icons.add_card_outlined),
                    label: const Text('Crea tu primera cuenta'),
                  ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width =
                        (constraints.maxWidth -
                            (constraints.maxWidth > 600 ? 28 : 12)) /
                        (constraints.maxWidth > 600 ? 3 : 2);
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final account in widget.controller.accounts)
                          SizedBox(
                            width: width,
                            child: AccountCard(
                              account: account,
                              currency: widget.controller.currency,
                              selected: widget.controller.filter == account.id,
                              onTap: () =>
                                  widget.controller.selectAccount(account.id),
                              onEdit: () => widget.onEditAccount(account),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          },
        ),
      ),
    ],
  );

  Widget _homeNotes() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Mis notas',
              style: KwallTheme.fontTitle.copyWith(fontSize: 21),
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Nueva nota o lista',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const NoteSheet(),
            ),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      if (widget.controller.notes.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Una idea, una lista, lo que necesites.',
            style: TextStyle(color: KwallTheme.textSecondary),
          ),
        ),
      for (final note in widget.controller.notes.take(3))
        NotePreview(key: ValueKey(note.id), note: note),
      if (widget.controller.notes.isNotEmpty)
        TextButton.icon(
          onPressed: () => widget.onJournal(0),
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Todas mis notas'),
        ),
    ],
  );

  Widget _homeHabits() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _habitDay,
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (date != null && mounted) {
                  setState(
                    () => _selectedDay =
                        DateUtils.isSameDay(date, DateTime.now()) ? null : date,
                  );
                }
              },
              icon: const Icon(Icons.today_outlined),
              label: Text(
                DateUtils.isSameDay(_habitDay, DateTime.now())
                    ? 'Hoy'
                    : DateFormat('d MMM y', 'es').format(_habitDay),
              ),
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Nuevo hábito',
            onPressed: () => editHabit(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      if (widget.controller.habits.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Tu primer hábito empieza aquí.',
            style: TextStyle(color: KwallTheme.textSecondary),
          ),
        )
      else ...[
        HabitDaySummary(
          habits: widget.controller.habits,
          day: _habitDay,
          settings: widget.controller.settings,
          reward: widget.controller.xp,
        ),
        const SizedBox(height: 12),
        for (final habit in widget.controller.habits.take(3))
          HabitCard(
            key: ValueKey(habit.id),
            habit: habit,
            day: _habitDay,
            compact: true,
          ),
        TextButton.icon(
          onPressed: () => widget.onJournal(1),
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Todos mis hábitos'),
        ),
      ],
    ],
  );
}
