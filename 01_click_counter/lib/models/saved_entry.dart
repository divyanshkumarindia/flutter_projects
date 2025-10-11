class SavedEntry {
  final int value;
  final DateTime? savedAt;
  final String? label;

  SavedEntry({required this.value, this.savedAt, this.label});

  SavedEntry copyWith({int? value, DateTime? savedAt, String? label}) {
    return SavedEntry(
      value: value ?? this.value,
      savedAt: savedAt ?? this.savedAt,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() => {
    'value': value,
    'savedAt': savedAt?.millisecondsSinceEpoch,
    'label': label,
  };

  static SavedEntry fromJson(Map<String, dynamic> m) {
    final savedAtMillis = m['savedAt'] as int?;
    return SavedEntry(
      value: (m['value'] as num).toInt(),
      savedAt: savedAtMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(savedAtMillis)
          : null,
      label: m['label'] as String?,
    );
  }

  @override
  String toString() =>
      'SavedEntry(value: $value, savedAt: $savedAt, label: $label)';
}
