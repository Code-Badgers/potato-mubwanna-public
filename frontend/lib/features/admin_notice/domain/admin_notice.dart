class AdminNotice {
  const AdminNotice({
    required this.id,
    required this.title,
    required this.content,
    required this.published,
    required this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String content;
  final bool published;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AdminNotice.fromJson(Map<String, dynamic> json) => AdminNotice(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        published: json['published'] as bool? ?? false,
        publishedAt: _optionalDateTime(json['publishedAt']),
        createdAt: _requiredDateTime(json['createdAt'], '생성일'),
        updatedAt: _requiredDateTime(json['updatedAt'], '수정일'),
      );
}

DateTime? _optionalDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is! String || value.isEmpty) {
    throw const FormatException('공지 게시일 형식이 올바르지 않습니다.');
  }
  return DateTime.parse(value);
}

DateTime _requiredDateTime(Object? value, String label) {
  if (value is! String || value.isEmpty) {
    throw FormatException('공지 $label 형식이 올바르지 않습니다.');
  }
  return DateTime.parse(value);
}
