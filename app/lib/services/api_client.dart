import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../config.dart';
import '../models/api_error.dart';
import '../models/video_info.dart';
import 'api_exception.dart';

/// Progress callback. [total] is -1 when the server sends no Content-Length.
typedef ProgressCallback = void Function(int received, int total);

class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            ));

  /// `POST /extract` -> [VideoInfo]. Throws [ApiException] on any failure.
  Future<VideoInfo> extract(String url) async {
    try {
      final resp = await _dio.post<Map<String, dynamic>>('/extract', data: {'url': url});
      return VideoInfo.fromJson(resp.data!);
    } on DioException catch (e) {
      throw _fromDioException(e);
    }
  }

  /// `POST /download` -> streams the response body to [savePath] and returns the
  /// [File]. Reports progress via [onProgress]. Throws [ApiException] on failure
  /// (the error body is a small JSON, so we read it off the stream to recover the
  /// backend error_code). A partial file is deleted on error.
  Future<File> download(
    String url,
    String formatId,
    String mode, {
    required String savePath,
    ProgressCallback? onProgress,
  }) async {
    final Response<ResponseBody> resp;
    try {
      resp = await _dio.post<ResponseBody>(
        '/download',
        data: {'url': url, 'format_id': formatId, 'mode': mode},
        options: Options(
          responseType: ResponseType.stream,
          validateStatus: (_) => true, // inspect error bodies ourselves
        ),
      );
    } on DioException catch (e) {
      throw _networkException(e);
    }

    final status = resp.statusCode ?? 0;
    if (status != 200) {
      throw await _errorFromStream(resp.data!, status);
    }

    final total =
        int.tryParse(resp.headers.value(Headers.contentLengthHeader) ?? '') ?? -1;
    final file = File(savePath);
    final sink = file.openWrite();
    var received = 0;
    try {
      await for (final chunk in resp.data!.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.close();
    } catch (e) {
      await sink.close();
      await _deleteQuietly(file);
      throw ApiException(code: ApiErrorCode.network, message: 'Download interrupted: $e');
    }
    return file;
  }

  // ---- error mapping ----
  ApiException _fromDioException(DioException e) {
    final resp = e.response;
    if (resp == null) return _networkException(e);
    final map = _asJsonMap(resp.data);
    if (map != null && map['error_code'] != null) {
      return ApiException.fromError(ApiError.fromJson(map), statusCode: resp.statusCode);
    }
    return ApiException(
      code: ApiErrorCode.unknown,
      message: 'Unexpected server response (${resp.statusCode}).',
      statusCode: resp.statusCode,
    );
  }

  ApiException _networkException(DioException e) =>
      ApiException.network(e.message ?? 'Network error (${e.type.name}).');

  Future<ApiException> _errorFromStream(ResponseBody body, int status) async {
    try {
      final bytes = <int>[];
      await for (final chunk in body.stream) {
        bytes.addAll(chunk);
      }
      final map = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (map['error_code'] != null) {
        return ApiException.fromError(ApiError.fromJson(map), statusCode: status);
      }
    } catch (_) {
      // fall through to a generic error below
    }
    return ApiException(
      code: ApiErrorCode.unknown,
      message: 'Server error ($status).',
      statusCode: status,
    );
  }

  Map<String, dynamic>? _asJsonMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return null;
  }

  Future<void> _deleteQuietly(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
