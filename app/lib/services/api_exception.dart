import '../models/api_error.dart';

/// Backend error codes, plus a client-side [network] value for
/// connection/timeout failures that never reached the server.
enum ApiErrorCode {
  private,
  unavailable,
  unsupported,
  noVideo,
  invalidUrl,
  tooLarge,
  rateLimited,
  botCheck,
  unknown,
  network;

  static ApiErrorCode fromWire(String? code) {
    switch (code) {
      case 'PRIVATE':
        return ApiErrorCode.private;
      case 'UNAVAILABLE':
        return ApiErrorCode.unavailable;
      case 'UNSUPPORTED':
        return ApiErrorCode.unsupported;
      case 'INVALID_URL':
        return ApiErrorCode.invalidUrl;
      case 'TOO_LARGE':
        return ApiErrorCode.tooLarge;
      case 'RATE_LIMITED':
        return ApiErrorCode.rateLimited;
      default:
        return ApiErrorCode.unknown;
    }
  }
}

/// Typed error thrown by [ApiClient]. Carries the mapped [code], the server
/// [message], the HTTP [statusCode] (null for network failures), and the
/// original [rawCode] string so unrecognized codes aren't lost.
class ApiException implements Exception {
  final ApiErrorCode code;
  final String message;
  final int? statusCode;
  final String? rawCode;

  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.rawCode,
  });

  factory ApiException.fromError(ApiError error, {int? statusCode}) => ApiException(
        code: ApiErrorCode.fromWire(error.errorCode),
        message: error.message,
        statusCode: statusCode,
        rawCode: error.errorCode,
      );

  factory ApiException.network(String message) =>
      ApiException(code: ApiErrorCode.network, message: message);

  @override
  String toString() =>
      'ApiException(${rawCode ?? code.name}, status=$statusCode): $message';
}
