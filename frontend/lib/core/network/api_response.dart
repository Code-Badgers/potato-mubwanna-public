class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.code,
  });

  final bool success;
  final String message;
  final T? data;
  final String? code;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromData,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json.containsKey('data') ? fromData(json['data']) : null,
      code: json['code'] as String?,
    );
  }
}

