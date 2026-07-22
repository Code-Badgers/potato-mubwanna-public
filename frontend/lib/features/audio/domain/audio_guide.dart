class AudioGuide {
  const AudioGuide({
    required this.id,
    required this.title,
    required this.audioUrl,
    required this.script,
    required this.characterScript,
  });

  factory AudioGuide.fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    final characterScript = data['characterScript'] as String?;

    return AudioGuide(
      id: data['id'] as int? ?? 0,
      title: data['title'] as String? ?? '',
      audioUrl: data['audioUrl'] as String? ?? '',
      script: data['script'] as String? ?? '',
      characterScript: characterScript == null || characterScript.trim().isEmpty
          ? null
          : characterScript,
    );
  }

  final int id;
  final String title;
  final String audioUrl;
  final String script;
  final String? characterScript;
}
