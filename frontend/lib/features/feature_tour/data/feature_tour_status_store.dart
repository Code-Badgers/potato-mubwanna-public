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
  static const _versionsKey = 'completedFeatureTourVersions';

  @override
  Future<bool> hasCompleted(String version) async {
    final preferences = await SharedPreferences.getInstance();
    final completedVersions =
        preferences.getStringList(_versionsKey) ?? const <String>[];
    return completedVersions.contains(version) ||
        preferences.getString(_versionKey) == version;
  }

  @override
  Future<void> markCompleted(String version) async {
    final preferences = await SharedPreferences.getInstance();
    final completedVersions = <String>{
      ...(preferences.getStringList(_versionsKey) ?? const <String>[]),
      version,
    }.toList();
    await preferences.setStringList(_versionsKey, completedVersions);
    await preferences.setString(_versionKey, version);
  }
}
