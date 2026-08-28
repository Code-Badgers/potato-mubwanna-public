import 'package:shared_preferences/shared_preferences.dart';

abstract interface class FeatureTourStatusStore {
  Future<bool> hasCompleted(String version);

  Future<void> markCompleted(String version);
}

class SharedPreferencesFeatureTourStatusStore
    implements FeatureTourStatusStore {
  const SharedPreferencesFeatureTourStatusStore();

  static const currentVersion = '1';
  static const _versionKey = 'completedFeatureTourVersion';

  @override
  Future<bool> hasCompleted(String version) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_versionKey) == version;
  }

  @override
  Future<void> markCompleted(String version) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_versionKey, version);
  }
}
