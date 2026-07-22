/// Backend error body: `{ "error_code": ..., "message": ... }`.
class ApiError {
  final String errorCode;
  final String message;

  const ApiError({required this.errorCode, required this.message});

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        errorCode: json['error_code'] as String? ?? 'UNKNOWN',
        message: json['message'] as String? ?? 'Unknown error',
      );
}
