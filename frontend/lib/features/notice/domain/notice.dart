class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.publishedAt,
  });

  final int id;
  final String title;
  final String content;
  final DateTime publishedAt;

  static Notice fromJson(Map<String, dynamic> json) => Notice(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        publishedAt: _requiredDateTime(json['publishedAt']),
      );
}

DateTime _requiredDateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    throw const FormatException('공지 게시일 형식이 올바르지 않습니다.');
  }
  return DateTime.parse(value);
}
