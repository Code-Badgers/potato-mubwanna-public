import 'package:shared_preferences/shared_preferences.dart';

abstract interface class FeatureTourStatusStore {
  bool wasSeenInCurrentProcess(String version);

  Future<bool> hasSeen(String version);

  Future<void> markSeen(String version);

  Future<int> readStepIndex(String version);

  Future<void> markStepIndex(String version, int stepIndex);

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
  static const _stepKeyPrefix = 'featureTourStepIndex.';
  static final _seenInProcess = <String>{};
  static final _stepInProcess = <String, int>{};
  // Keep a process-local guard while the SharedPreferences write is pending.
  // This closes the small gap between completing a tour and leaving its route.
  static final _completedInProcess = <String>{};

  static void resetInProcessForTesting() {
    _seenInProcess.clear();
    _stepInProcess.clear();
    _completedInProcess.clear();
  }

  @override
  bool wasSeenInCurrentProcess(String version) {
    return _seenInProcess.contains(version) ||
        _completedInProcess.contains(version);
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
  Future<int> readStepIndex(String version) async {
    final inProcess = _stepInProcess[version];
    if (inProcess != null) {
      return inProcess;
    }
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt('$_stepKeyPrefix$version') ?? 0;
  }

  @override
  Future<void> markStepIndex(String version, int stepIndex) async {
    final normalizedIndex = stepIndex < 0 ? 0 : stepIndex;
    _stepInProcess[version] = normalizedIndex;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt('$_stepKeyPrefix$version', normalizedIndex);
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
    _stepInProcess.remove(version);
    final preferences = await SharedPreferences.getInstance();
    final completedVersions = <String>{
      ...(preferences.getStringList(_versionsKey) ?? const <String>[]),
      version,
    }.toList();
    await preferences.setStringList(_versionsKey, completedVersions);
    await preferences.setString(_versionKey, version);
    await preferences.remove('$_stepKeyPrefix$version');
  }
}
