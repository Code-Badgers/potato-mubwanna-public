import 'package:shared_preferences/shared_preferences.dart';

abstract interface class FeatureTourStatusStore {
  Future<bool> hasSeen(String version);

  Future<void> markSeen(String version);

  Future<bool> hasCompleted(String version);

  Future<void> markCompleted(String version);
}

class SharedPreferencesFeatureTourStatusStore
    implements FeatureTourStatusStore {
  const SharedPreferencesFeatureTourStatusStore();

  static const currentVersion = '1';
  static const _seenVersionsKey = 'seenFeatureTourVersions';
  static const _versionKey = 'completedFeatureTourVersion';
  static const _versionsKey = 'completedFeatureTourVersions';
  static final _seenInProcess = <String>{};
  // Keep a process-local guard while the SharedPreferences write is pending.
  // This closes the small gap between completing a tour and leaving its route.
  static final _completedInProcess = <String>{};

  static void resetInProcessForTesting() {
    _seenInProcess.clear();
    _completedInProcess.clear();
  }

  @override
  Future<bool> hasSeen(String version) async {
    if (_seenInProcess.contains(version) ||
        _completedInProcess.contains(version)) {
      return true;
    }
    final preferences = await SharedPreferences.getInstance();
    final seenVersions =
        preferences.getStringList(_seenVersionsKey) ?? const <String>[];
    if (seenVersions.contains(version)) {
      return true;
    }
    final completedVersions =
        preferences.getStringList(_versionsKey) ?? const <String>[];
    return completedVersions.contains(version) ||
        preferences.getString(_versionKey) == version;
  }

  @override
  Future<void> markSeen(String version) async {
    _seenInProcess.add(version);
    final preferences = await SharedPreferences.getInstance();
    final seenVersions = <String>{
      ...(preferences.getStringList(_seenVersionsKey) ?? const <String>[]),
      version,
    }.toList();
    await preferences.setStringList(_seenVersionsKey, seenVersions);
  }

  @override
  Future<bool> hasCompleted(String version) async {
    if (_completedInProcess.contains(version)) {
      return true;
    }
    final preferences = await SharedPreferences.getInstance();
    final completedVersions =
        preferences.getStringList(_versionsKey) ?? const <String>[];
    return completedVersions.contains(version) ||
        preferences.getString(_versionKey) == version;
  }

  @override
  Future<void> markCompleted(String version) async {
    _completedInProcess.add(version);
    final preferences = await SharedPreferences.getInstance();
    final completedVersions = <String>{
      ...(preferences.getStringList(_versionsKey) ?? const <String>[]),
      version,
    }.toList();
    await preferences.setStringList(_versionsKey, completedVersions);
    await preferences.setString(_versionKey, version);
  }
}
