import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';

import '../models/todo_model.dart';
import '../services/todo_notification_service.dart';
import '../services/todo_service.dart';

class TodoController extends GetxController {
  TodoController({TodoService? service, TodoNotificationService? notifications})
    : _service = service ?? Get.find<TodoService>(),
      _notifications = notifications ?? Get.find<TodoNotificationService>();

  final TodoService _service;
  final TodoNotificationService _notifications;
  final selectedTab = 0.obs;
  final searchQuery = ''.obs;
  final todos = <TodoModel>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();
  Timer? _searchDebounce;
  int _fetchRequestId = 0;

  @override
  void onInit() {
    super.onInit();
    fetchTodos();
  }

  List<TodoModel> get visibleTodos {
    return todosForTab(selectedTab.value);
  }

  List<TodoModel> todosForTab(int tabIndex) {
    final now = DateTime.now();
    final startOfTomorrow = DateTime(now.year, now.month, now.day + 1);

    final tabTodos = switch (tabIndex) {
      1 =>
        todos
            .where(
              (todo) =>
                  !todo.completed &&
                  (todo.dueAt == null ||
                      !todo.dueAt!.isBefore(startOfTomorrow)),
            )
            .toList(growable: false),
      2 => todos.where((todo) => todo.completed).toList(growable: false),
      _ =>
        todos
            .where(
              (todo) =>
                  !todo.completed &&
                  todo.dueAt != null &&
                  todo.dueAt!.isBefore(startOfTomorrow),
            )
            .toList(growable: false),
    };

    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return tabTodos;

    return tabTodos
        .where(
          (todo) =>
              todo.title.toLowerCase().contains(query) ||
              todo.description.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  void setSearchQuery(String value) {
    searchQuery.value = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      fetchTodos(search: value);
    });
  }

  void selectTab(int index) {
    selectedTab.value = index;
  }

  Future<void> fetchTodos({String? search}) async {
    final requestId = ++_fetchRequestId;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final result = await _service.getTodos(
        search: search ?? searchQuery.value,
      );
      if (requestId != _fetchRequestId) return;

      todos.assignAll(result);
      for (final todo in result) {
        if (todo.reminderEnabled && !todo.completed) {
          // Re-register reminders without delaying the task list from appearing.
          unawaited(_scheduleReminder(todo));
        }
      }
    } catch (error) {
      if (requestId == _fetchRequestId) {
        errorMessage.value = _messageFor(error);
      }
    } finally {
      if (requestId == _fetchRequestId) isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  Future<bool> createTodo({
    required String title,
    required String description,
    required DateTime dueAt,
    required String priority,
    required bool reminderEnabled,
  }) async {
    isSaving.value = true;
    errorMessage.value = null;

    try {
      final todo = await _service.createTodo(
        title: title.trim(),
        description: description.trim(),
        dueAt: dueAt,
        priority: priority,
        reminderEnabled: reminderEnabled,
      );
      todos.insert(0, todo);
      selectedTab.value = 0;
      if (todo.reminderEnabled) {
        // Ask for platform permissions only after saving. Android can open
        // system settings here, so this must never hold the editor open.
        unawaited(_requestAndScheduleReminder(todo));
      }
      return true;
    } catch (error) {
      _showMessage('Could not add task', _messageFor(error));
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> editTodo({
    required TodoModel todo,
    required String title,
    required String description,
    required DateTime dueAt,
    required String priority,
    required bool reminderEnabled,
  }) async {
    final id = todo.id;
    if (id == null) return false;

    isSaving.value = true;
    errorMessage.value = null;

    try {
      final updated = await _service.updateTodo(
        id: id,
        colorValue: todo.colorValue,
        title: title.trim(),
        description: description.trim(),
        dueAt: dueAt,
        priority: priority,
        reminderEnabled: reminderEnabled,
      );
      final index = todos.indexOf(todo);
      if (index != -1) todos[index] = updated;

      unawaited(_cancelReminder(id));
      if (updated.reminderEnabled && !updated.completed) {
        unawaited(_requestAndScheduleReminder(updated));
      }
      return true;
    } catch (error) {
      _showMessage('Could not update task', _messageFor(error));
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> toggleCompleted(TodoModel todo) async {
    final id = todo.id;
    if (id == null) return;

    try {
      final updated = await _service.updateTodo(
        id: id,
        colorValue: todo.colorValue,
        completed: !todo.completed,
      );
      final index = todos.indexOf(todo);
      if (index != -1) todos[index] = updated;

      if (updated.completed) {
        await _notifications.cancel(id);
      } else if (updated.reminderEnabled) {
        await _notifications.schedule(updated);
      }
    } catch (error) {
      _showMessage('Could not update task', _messageFor(error));
    }
  }

  Future<bool> deleteTodo(TodoModel todo) async {
    final id = todo.id;
    if (id == null) return false;

    try {
      await _service.deleteTodo(id);
      todos.remove(todo);
      await _notifications.cancel(id);
      return true;
    } catch (error) {
      _showMessage('Could not delete task', _messageFor(error));
      return false;
    }
  }

  String _messageFor(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _scheduleReminder(TodoModel todo) async {
    try {
      await _notifications.schedule(todo).timeout(const Duration(seconds: 5));
    } catch (error) {
      _showMessage('Task saved, reminder unavailable', _messageFor(error));
    }
  }

  Future<void> _cancelReminder(String id) async {
    try {
      await _notifications.cancel(id).timeout(const Duration(seconds: 5));
    } catch (_) {
      // The task was already updated on the server; local cleanup is best effort.
    }
  }

  Future<void> _requestAndScheduleReminder(TodoModel todo) async {
    if (!_notifications.isSupportedPlatform) {
      _showMessage(
        'Reminder preference saved',
        'Automatic reminders are currently available on Android and iOS only.',
      );
      return;
    }

    try {
      final permissionGranted = await _notifications
          .requestPermissions()
          .timeout(const Duration(seconds: 30));
      if (!permissionGranted) {
        _showMessage(
          'Reminder saved',
          'Allow notifications in system settings to receive it.',
        );
        return;
      }

      await _scheduleReminder(todo);
    } catch (error) {
      _showMessage('Task saved, reminder unavailable', _messageFor(error));
    }
  }

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      backgroundColor: const Color(0xFF28232D),
      colorText: const Color(0xFFFFFFFF),
      duration: const Duration(seconds: 3),
    );
  }
}
