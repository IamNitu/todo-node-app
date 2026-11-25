import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/todos/pages/todo_page.dart';

import 'todos/controllers/todo_controller.dart';
import 'todos/pages/onboarding_page.dart';
import 'todos/services/todo_notification_service.dart';
import 'todos/services/todo_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notifications = TodoNotificationService();
  await notifications.initialize();

  Get.put<TodoNotificationService>(notifications, permanent: true);
  Get.put<TodoService>(TodoService(), permanent: true);
  Get.put<TodoController>(TodoController(), permanent: true);

  final preferences = SharedPreferencesAsync();
  final hasSeenOnboarding =
      await preferences.getBool('has_seen_onboarding') ?? false;

  runApp(TodoApp(showOnboarding: !hasSeenOnboarding));
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key, this.showOnboarding = true});

  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2788F5)),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: showOnboarding ? const OnboardingPage() : const TodoPage(),
    );
  }
}
