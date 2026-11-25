import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/todo_model.dart';
import '../services/device_id_service.dart';

class TodoService {
  TodoService({http.Client? client, DeviceIdService? deviceIdService})
    : _client = client ?? http.Client(),
      _deviceIdService = deviceIdService ?? DeviceIdService();

  final DeviceIdService _deviceIdService;

  final http.Client _client;
  static const _configuredBaseUrl = String.fromEnvironment('TODO_API_URL');

  Uri get _baseUri {
    if (_configuredBaseUrl.isNotEmpty) {
      return Uri.parse(_configuredBaseUrl);
    }

    final host = kIsWeb
        ? 'localhost'
        : defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';
    return Uri.parse('http://$host:5000/api/todos');
  }

  Future<List<TodoModel>> getTodos() async {
    final response = await _client
        .get(_baseUri, headers: await _headers())
        .timeout(const Duration(seconds: 15));
    final data = _decodeResponse(response);
    if (data is! List) {
      throw const FormatException('The server returned an invalid todo list.');
    }

    return data
        .whereType<Map>()
        .map((item) => TodoModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<TodoModel> createTodo({
    required String title,
    required String description,
    required DateTime dueAt,
    required String priority,
    required bool reminderEnabled,
  }) async {
    final response = await _client
        .post(
          _baseUri,
          headers: await _headers(json: true),
          body: jsonEncode({
            'title': title,
            'description':description.trim(),
            'completed': false,
            'dueAt': dueAt.toUtc().toIso8601String(),
            'priority': priority,
            'reminderEnabled': reminderEnabled,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final data = _decodeResponse(response);
    return _todoFromResponse(data);
  }

  Future<TodoModel> updateTodo({
    required String id,
    required int colorValue,
    String? title,
    String? description,
    bool? completed,
    DateTime? dueAt,
    String? priority,
    bool? reminderEnabled,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if(description != null){ updates['description']=description.trim();}
    if (completed != null) updates['completed'] = completed;
    if (dueAt != null) updates['dueAt'] = dueAt.toUtc().toIso8601String();
    if (priority != null) updates['priority'] = priority;
    if (reminderEnabled != null) updates['reminderEnabled'] = reminderEnabled;

    final response = await _client
        .put(
          _baseUri.replace(path: '${_baseUri.path}/${Uri.encodeComponent(id)}'),
          headers: await _headers(json: true),
          body: jsonEncode(updates),
        )
        .timeout(const Duration(seconds: 15));

    final data = _decodeResponse(response);
    return _todoFromResponse(data, colorValue: colorValue);
  }

  Future<void> deleteTodo(String id) async {
    final uri = _baseUri.replace(
      path: '${_baseUri.path}/${Uri.encodeComponent(id)}',
    );
    final response = await _client
        .delete(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));
    _decodeResponse(response);
  }

  TodoModel _todoFromResponse(Object? data, {int? colorValue}) {
    if (data is Map && data['todo'] is Map) {
      return TodoModel.fromJson(
        Map<String, dynamic>.from(data['todo'] as Map),
        colorValue: colorValue,
      );
    }
    if (data is Map) {
      return TodoModel.fromJson(
        Map<String, dynamic>.from(data),
        colorValue: colorValue,
      );
    }
    throw const FormatException('The server returned an invalid todo.');
  }

  Object? _decodeResponse(http.Response response) {
    Object? data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } on FormatException {
        throw const FormatException('The server returned invalid JSON.');
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map && data['error'] is String
          ? data['error'] as String
          : 'Request failed with status ${response.statusCode}.';
      throw Exception(message);
    }
    return data;
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    final deviceId = await _deviceIdService.getOrCreate();

    return {
      'x-device-id': deviceId,
      if (json) 'Content-Type': 'application/json',
      if (!json) 'Accept': 'application/json',
    };
  }
}
