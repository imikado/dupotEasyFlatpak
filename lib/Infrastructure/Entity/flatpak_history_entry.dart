class FlatpakHistoryEntry {
  final String commit;
  final String? subject;
  final String? date;

  FlatpakHistoryEntry({
    required this.commit,
    this.subject,
    this.date,
  });

  @override
  String toString() =>
      'History(commit: $commit, subject: $subject, date: $date)';
}
