class BackupPreview {
  final int accounts;
  final int movements;
  final int notes;
  final int habits;
  const BackupPreview({
    required this.accounts,
    required this.movements,
    required this.notes,
    required this.habits,
  });
  factory BackupPreview.fromCounts(Map<String, int> counts) => BackupPreview(
    accounts: counts['accounts'] ?? 0,
    movements: counts['transactions'] ?? 0,
    notes: counts['personal_notes'] ?? 0,
    habits: counts['habits'] ?? 0,
  );
}
