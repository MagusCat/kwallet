import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../view_models/home_view_model.dart';

class HomeTasksPanel extends StatelessWidget {
  final HomeViewModel controller;
  final VoidCallback onNewTask;
  final VoidCallback onOpenNotes;

  const HomeTasksPanel({
    super.key,
    required this.controller,
    required this.onNewTask,
    required this.onOpenNotes,
  });

  @override
  Widget build(BuildContext context) {
    final tasks = controller.pendingTasks;
    final hasLists = controller.notes.any((n) => n.kind == 'list');

    return LedgerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: KwallTheme.accentLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.checklist_rounded,
                  color: KwallTheme.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tareas pendientes',
                      style: KwallTheme.fontTitle.copyWith(fontSize: 18),
                    ),
                    Text(
                      tasks.isEmpty
                          ? (hasLists ? '¡Todo completado!' : 'Sin tareas pendientes')
                          : '${tasks.length} ${tasks.length == 1 ? "tarea pendiente" : "tareas pendientes"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: KwallTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Nueva lista o tarea',
                onPressed: onNewTask,
                icon: const Icon(Icons.add_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: KwallTheme.incomeGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasLists
                          ? '¡Excelente! No tienes tareas pendientes hoy.'
                          : 'Crea una lista de compras o pendientes para organizarte.',
                      style: TextStyle(
                        fontSize: 13,
                        color: KwallTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            for (final item in tasks.take(4)) ...[
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.checkNote(item.note, item.index, true);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: KwallTheme.accent,
                            width: 2,
                          ),
                        ),
                        child: const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.item.text,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: KwallTheme.surfaceContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Lista: ${item.note.title}',
                            style: TextStyle(
                              fontSize: 11,
                              color: KwallTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 12),
            ],
            if (tasks.length > 4)
              TextButton.icon(
                onPressed: onOpenNotes,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text('Ver todas las tareas (${tasks.length})'),
              ),
          ],
        ],
      ),
    );
  }
}
