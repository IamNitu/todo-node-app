import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static const _storageKey = 'todo_device_id';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final Uuid _uuid = Uuid();

  Future<String> getOrCreate() async {
    final saveId = await _preferences.getString(_storageKey);
    if (saveId != null && saveId.isNotEmpty) {
      return saveId;
    }
    final newId = _uuid.v4();
    await _preferences.setString(_storageKey, newId);
    return newId;
  }
}
