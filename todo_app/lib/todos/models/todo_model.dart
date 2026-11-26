class TodoModel {
  TodoModel({
    required this.title,
    required this.dueAt,
    required this.priority,
    required this.reminderEnabled,
    required this.colorValue,
    this.description='',
    this.id,
    this.completed = false,
  });

  final String? id;
  final String title;
  final String description;
  final DateTime? dueAt;
  final String priority;
  final bool reminderEnabled;
  final int colorValue;
  final bool completed;

  String get category => switch (priority) {
    'important' => 'Important',
    'urgent' => 'Urgent',
    _ => 'Basic',
  };

  String get dateLabel {
    final date = dueAt;
    if (date == null) return 'No due date';
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String get timeLabel {
    final date = dueAt;
    if (date == null) return 'No time set';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  factory TodoModel.fromJson(Map<String, dynamic> json, {int? colorValue}) {
    final id = json['_id']?.toString() ?? json['id']?.toString();
    final title = json['title']?.toString() ?? '';
    final description = json['description']?.toString() ?? '';
    final dueAtValue = json['dueAt']?.toString();
    final dueAt = dueAtValue == null
        ? null
        : DateTime.tryParse(dueAtValue)?.toLocal();

    return TodoModel(
      id: id,
      title: title,
      description: description,
      completed: json['completed'] == true,
      dueAt: dueAt,
      priority: json['priority']?.toString() ?? 'basic',
      reminderEnabled: json['reminderEnabled'] == true,
      colorValue: colorValue ?? _colorFor(id ?? title),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description':description,
    'completed': completed,
    'dueAt': dueAt?.toUtc().toIso8601String(),
    'priority': priority,
    'reminderEnabled': reminderEnabled,
  };

  static int _colorFor(String seed) {
    const colors = [
      0xFFFF6F61,
      0xFFD0A68F,
      0xFFB9F17A,
      0xFFFFEF4D,
      0xFFF18AAA,
      0xFFA9DDF2,
    ];
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return colors[hash % colors.length];
  }
}
