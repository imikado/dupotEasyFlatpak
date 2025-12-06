import 'package:dupot_easy_flatpak/Infrastructure/Entity/flatpak_history_entry.dart';

class FlatpakApi {
  List<FlatpakHistoryEntry> parseFlatpakHistory(String raw) {
    final lines = raw.split('\n');

    List<FlatpakHistoryEntry> history = [];
    bool inHistory = false;

    Map<String, String>? current;

    final kv = RegExp(r'^([A-Za-z]+):\s*(.*)$');

    for (final rawLine in lines) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) continue;

      final match = kv.firstMatch(trimmed);
      if (match == null) continue;

      final key = match.group(1)!;
      final value = match.group(2)!.trim();

      if (key == 'Commit') {
        // Close previous entry
        if (current != null && current.containsKey('Commit')) {
          history.add(
            FlatpakHistoryEntry(
              commit: current['Commit']!,
              subject: current['Subject'],
              date: current['Date'],
            ),
          );
        }
        current = {'Commit': value};
      } else if (key == 'Subject' || key == 'Date') {
        current ??= {};
        current[key] = value;
      }
    }

    // Add last entry
    if (current != null && current.containsKey('Commit')) {
      history.add(
        FlatpakHistoryEntry(
          commit: current['Commit']!,
          subject: current['Subject'],
          date: current['Date'],
        ),
      );
    }

    return history;
  }
}
