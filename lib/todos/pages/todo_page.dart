import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/todo_controller.dart';
import '../models/todo_model.dart';

class TodoPage extends GetView<TodoController> {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFD),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360
                ? 16.0
                : constraints.maxWidth < 600
                ? 20.0
                : 32.0;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                24,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Greeting(),
                        const SizedBox(height: 24),
                        _StatusTabs(controller: controller),
                        const SizedBox(height: 24),
                        _TasksHeading(
                          controller: controller,
                          onAdd: _showEditor,
                        ),
                        const SizedBox(height: 14),
                        _TodoGrid(
                          controller: controller,
                          onAdd: _showEditor,
                          onEdit: (todo) => _showEditor(todo),
                          onDelete: _confirmDelete,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showEditor([TodoModel? todo]) {
    Get.dialog<void>(
      _TodoEditorDialog(controller: controller, todo: todo),
      barrierDismissible: false,
    );
  }

  Future<void> _confirmDelete(TodoModel todo) async {
    final shouldDelete = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Delete this task?'),
        content: Text('“${todo.title}” will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Keep task'),
          ),
          FilledButton(
            onPressed: () => Get.back<bool>(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE45F58),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) await controller.deleteTodo(todo);
  }
}

class _TodoEditorDialog extends StatefulWidget {
  const _TodoEditorDialog({required this.controller, this.todo});

  final TodoController controller;
  final TodoModel? todo;

  @override
  State<_TodoEditorDialog> createState() => _TodoEditorDialogState();
}

class _TodoEditorDialogState extends State<_TodoEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _dueAt;
  late String _priority;
  late bool _reminderEnabled;
  bool _saving = false;
  bool _showTitleError = false;

  @override
  void initState() {
    super.initState();
    final todo = widget.todo;
    _titleController = TextEditingController(text: todo?.title ?? '');
    _descriptionController = TextEditingController(
      text: todo?.description ?? '',
    );
    _dueAt = todo?.dueAt ?? DateTime.now().add(const Duration(hours: 1));
    _priority = todo?.priority ?? 'basic';
    _reminderEnabled = todo?.reminderEnabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.todo != null;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(isEditing ? 'Edit task' : 'Add a task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 120,
              decoration: InputDecoration(
                labelText: 'Task title',
                hintText: 'What do you need to do?',
                errorText: _showTitleError ? 'Enter a task title' : null,
                filled: true,
                fillColor: const Color(0xFFF7F4F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF1687F8),
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (_) {
                if (_showTitleError) setState(() => _showTitleError = false);
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Add more details about this task...',
                alignLabelWithHint: true,
                filled: true,
                fillColor: const Color(0xFFF7F4F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF1687F8),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'DATE & TIME',
              style: TextStyle(
                color: Color(0xFF85808B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DateTimeButton(
                  icon: Icons.calendar_month_rounded,
                  label: _formatDate(_dueAt),
                  onPressed: _pickDate,
                ),
                const SizedBox(height: 8),
                _DateTimeButton(
                  icon: Icons.access_time_rounded,
                  label: _formatTime(_dueAt),
                  onPressed: _pickTime,
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'basic', child: Text('Basic')),
                DropdownMenuItem(value: 'important', child: Text('Important')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _priority = value);
              },
            ),
            const SizedBox(height: 7),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Remind me',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'At ${_formatTime(_dueAt)} on ${_formatDate(_dueAt)}',
              ),
              value: _reminderEnabled,
              activeTrackColor: const Color(0xFF2788F5),
              onChanged: (value) => setState(() => _reminderEnabled = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Get.back<void>(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isEditing ? Icons.save_rounded : Icons.add_rounded,
                  size: 18,
                ),
          label: Text(isEditing ? 'Save changes' : 'Add task'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1687F8),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueAt,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 20),
    );
    if (selected == null) return;

    setState(() {
      _dueAt = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _dueAt.hour,
        _dueAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt),
    );
    if (selected == null) return;

    setState(() {
      _dueAt = DateTime(
        _dueAt.year,
        _dueAt.month,
        _dueAt.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _showTitleError = true);
      return;
    }

    setState(() => _saving = true);
    final todo = widget.todo;
    try {
      final save = todo == null
          ? widget.controller.createTodo(
              title: title,
              description: _descriptionController.text.trim(),
              dueAt: _dueAt,
              priority: _priority,
              reminderEnabled: _reminderEnabled,
            )
          : widget.controller.editTodo(
              todo: todo,
              title: title,
              description: _descriptionController.text.trim(),
              dueAt: _dueAt,
              priority: _priority,
              reminderEnabled: _reminderEnabled,
            );
      final success = await save.timeout(const Duration(seconds: 20));

      if (!mounted) return;
      if (success) {
        // This editor is presented with Get.dialog, so close that dialog route
        // directly after the API reports a successful update.
        Navigator.of(context, rootNavigator: true).pop();
      } else {
        setState(() => _saving = false);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      Get.snackbar(
        'Could not save task',
        'The save did not finish. Check the server connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _DateTimeButton extends StatelessWidget {
  const _DateTimeButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        foregroundColor: const Color(0xFF383239),
        side: const BorderSide(color: Color(0xFFE5DFE8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  String _greetingFor(int hour) {
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }

  String _messageFor(int hour) {
    if (hour < 12) return 'A fresh start, one task at a time.';
    if (hour < 17) return 'Keep your momentum going.';
    return 'Wrap up the day at your own pace.';
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF3698F5),
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3698F5).withValues(alpha: 0.2),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 34,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR DAY AT A GLANCE',
                style: TextStyle(
                  color: Color(0xFF85808B),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _greetingFor(hour),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF17151A),
                  fontSize: 25,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _messageFor(hour),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF85808B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({required this.controller});

  final TodoController controller;
  static const labels = ['Today', 'Upcoming', 'Done'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDF2),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Obx(
        () => Row(
          children: List.generate(labels.length, (index) {
            final selected = controller.selectedTab.value == index;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index == labels.length - 1 ? 0 : 4,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: selected ? Colors.black : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => controller.selectTab(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 10,
                      ),
                      child: Center(
                        child: Text(
                          labels[index],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFFFFE83D)
                                : const Color(0xFF625D67),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TasksHeading extends StatelessWidget {
  const _TasksHeading({required this.controller, required this.onAdd});

  final TodoController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final title = switch (controller.selectedTab.value) {
        1 => 'Upcoming tasks',
        2 => 'Completed tasks',
        _ => 'Today’s tasks',
      };
      final count = controller.visibleTodos.length;
      final countLabel = '$count ${count == 1 ? 'task' : 'tasks'}';

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF17151A),
                    fontSize: 25,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  countLabel,
                  style: const TextStyle(
                    color: Color(0xFF89838E),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            tooltip: 'Add task',
            onPressed: onAdd,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1687F8),
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      );
    });
  }
}

class _TodoGrid extends StatelessWidget {
  const _TodoGrid({
    required this.controller,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final TodoController controller;
  final VoidCallback onAdd;
  final ValueChanged<TodoModel> onEdit;
  final ValueChanged<TodoModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFFC956D8)),
          ),
        );
      }

      final error = controller.errorMessage.value;
      if (error != null && controller.todos.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: Color(0xFFB34FC7),
                  size: 44,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Could not load your tasks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(error, textAlign: TextAlign.center),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: controller.fetchTodos,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        );
      }

      final todos = controller.visibleTodos;
      if (todos.isEmpty) {
        return _EmptyTasks(
          onAdd: onAdd,
          isDoneTab: controller.selectedTab.value == 2,
          isUpcomingTab: controller.selectedTab.value == 1,
        );
      }

      return Column(
        children: [
          for (final todo in todos)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _TodoCard(
                todo: todo,
                onToggle: () => controller.toggleCompleted(todo),
                onEdit: () => onEdit(todo),
                onDelete: () => onDelete(todo),
              ),
            ),
        ],
      );
    });
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({
    required this.onAdd,
    required this.isDoneTab,
    required this.isUpcomingTab,
  });

  final VoidCallback onAdd;
  final bool isDoneTab;
  final bool isUpcomingTab;

  @override
  Widget build(BuildContext context) {
    final title = isDoneTab
        ? 'Nothing completed yet'
        : isUpcomingTab
        ? 'No upcoming tasks'
        : 'A clear day';
    final subtitle = isDoneTab
        ? 'Finished tasks will show up here.'
        : isUpcomingTab
        ? 'Tasks scheduled for later will appear here.'
        : 'Add a task and make today count.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF2E5F5),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                isDoneTab ? Icons.task_alt_rounded : Icons.edit_note_rounded,
                color: const Color(0xFFB34FC7),
                size: 38,
              ),
            ),
            const SizedBox(height: 17),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF26212B),
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF89838E),
                fontSize: 14,
                height: 1.35,
              ),
            ),
            if (!isDoneTab) ...[
              const SizedBox(height: 17),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add a task'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _TodoMenuAction { edit, delete }

class _TodoCard extends StatelessWidget {
  const _TodoCard({
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final TodoModel todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cardColor = Color(todo.colorValue);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.23),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 15, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.48),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      todo.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF302A31),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (todo.reminderEnabled) ...[
                  const SizedBox(width: 7),
                  const Icon(Icons.notifications_active_rounded, size: 15),
                ],
                const Spacer(),
                PopupMenuButton<_TodoMenuAction>(
                  tooltip: 'Task options',
                  padding: EdgeInsets.zero,
                  iconSize: 21,
                  onSelected: (action) {
                    if (action == _TodoMenuAction.edit) onEdit();
                    if (action == _TodoMenuAction.delete) onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _TodoMenuAction.edit,
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _TodoMenuAction.delete,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Color(0xFF342D31),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              todo.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF111111),
                fontSize: 20,
                height: 1.12,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                decoration: todo.completed ? TextDecoration.lineThrough : null,
              ),
            ),
            if (todo.description.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                todo.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.3),
              ),
            ],
            const Divider(height: 24),
            _CardDetail(
              icon: Icons.calendar_month_outlined,
              label: todo.dateLabel,
            ),
            const SizedBox(height: 7),
            _CardDetail(icon: Icons.access_time_rounded, label: todo.timeLabel),
            Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                button: true,
                label: todo.completed
                    ? 'Mark task as not done'
                    : 'Mark task as done',
                child: IconButton(
                  tooltip: todo.completed ? 'Mark as not done' : 'Mark as done',
                  onPressed: onToggle,
                  icon: Icon(
                    todo.completed
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardDetail extends StatelessWidget {
  const _CardDetail({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF383239)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 1.15,
              color: Color(0xFF383239),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
