import '../../../core/contracts/app_repositories.dart';
import '../models/journal_models.dart';
import 'journal_actions_view_model.dart';

class JournalViewModel extends JournalActionsViewModel {
  final SettingsRepository preferences;
  List<PersonalNote> notes = const [];
  List<Habit> habits = const [];
  Map<String, String> settings = const {};
  int xp = 0;
  bool loading = true;
  JournalViewModel(super.repository, this.preferences) {
    for (final source in {repository.changes, preferences.changes}) {
      observe(source, load);
    }
  }
  Future<void> load() async {
    final request = beginRequest();
    try {
      final nextNotes = await repository.getNotes();
      final nextHabits = await repository.getHabits();
      final nextSettings = await preferences.getSettings();
      final nextXp = await repository.getExperience();
      if (!isCurrent(request)) return;
      notes = List.unmodifiable(nextNotes);
      habits = List.unmodifiable(nextHabits);
      settings = Map.unmodifiable(nextSettings);
      xp = nextXp;
      loading = false;
      error = null;
      changed();
    } catch (_) {
      if (isCurrent(request)) {
        loading = false;
        fail('No se pudo abrir tu espacio. Reintenta.');
      }
    }
  }
}
