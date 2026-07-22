import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

enum StorageStatus { success, permissionDenied, permissionPermanentlyDenied, failed }

/// Outcome of a storage operation. Never thrown — always returned.
class StorageResult {
  final StorageStatus status;
  final String? path; // e.g. "Download/woofer/x.mp4" or an absolute path
  final String? uri; // content:// (API 29+) or file:// (legacy)
  final String? message;

  const StorageResult(this.status, {this.path, this.uri, this.message});

  bool get isSuccess => status == StorageStatus.success;

  @override
  String toString() => 'StorageResult($status, path=$path, uri=$uri, message=$message)';
}

/// Returns null to proceed, or a denial [StorageResult] to short-circuit.
/// Injectable so the permission branch is testable without a device.
typedef PermissionGate = Future<StorageResult?> Function();

/// Saves downloaded files to the public Downloads folder and opens/shares them.
///
/// Backed by a native MethodChannel: API 29+ uses MediaStore (scoped storage,
/// no runtime permission); API <=28 writes the legacy public dir after a
/// WRITE_EXTERNAL_STORAGE grant. Permission denial is a typed status, not a crash.
class StorageService {
  static const String appSubfolder = 'woofer';
  static const MethodChannel _defaultChannel = MethodChannel('woofer/storage');

  final MethodChannel _channel;
  final PermissionGate? _permissionGate;

  StorageService({MethodChannel? channel, PermissionGate? permissionGate})
      : _channel = channel ?? _defaultChannel,
        _permissionGate = permissionGate;

  /// Copy [source] into public Downloads/woofer. Returns the saved uri + path.
  Future<StorageResult> saveToDownloads(
    File source, {
    String? fileName,
    String mimeType = 'application/octet-stream',
  }) async {
    try {
      if (!await source.exists()) {
        return const StorageResult(StorageStatus.failed, message: 'Source file does not exist.');
      }
      final denied = await _ensurePermission();
      if (denied != null) return denied;

      final result = await _channel.invokeMapMethod<String, dynamic>('saveToDownloads', {
        'sourcePath': source.path,
        'fileName': fileName ?? source.uri.pathSegments.last,
        'subDir': appSubfolder,
        'mimeType': mimeType,
      });
      if (result == null) {
        return const StorageResult(StorageStatus.failed, message: 'No result from platform.');
      }
      return StorageResult(
        StorageStatus.success,
        path: result['path'] as String?,
        uri: result['uri'] as String?,
      );
    } on PlatformException catch (e) {
      return StorageResult(StorageStatus.failed, message: e.message ?? 'Save failed (${e.code}).');
    } on MissingPluginException {
      return const StorageResult(StorageStatus.failed, message: 'Storage channel unavailable.');
    } catch (e) {
      return StorageResult(StorageStatus.failed, message: 'Save failed: $e');
    }
  }

  /// Open [pathOrUri] in an external viewer. Returns false if nothing handled it.
  Future<bool> openFile(String pathOrUri, {String mimeType = '*/*'}) =>
      _invokeBool('openFile', pathOrUri, mimeType);

  /// Share [pathOrUri] via the system share sheet. Returns false on failure.
  Future<bool> shareFile(String pathOrUri, {String mimeType = '*/*'}) =>
      _invokeBool('shareFile', pathOrUri, mimeType);

  Future<bool> _invokeBool(String method, String path, String mimeType) async {
    try {
      return await _channel.invokeMethod<bool>(method, {'path': path, 'mimeType': mimeType}) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// null => proceed; non-null => a denial result to return to the caller.
  Future<StorageResult?> _ensurePermission() async {
    if (_permissionGate != null) return _permissionGate();
    if (!Platform.isAndroid) return null; // nothing to request off-Android
    if (await _sdkInt() >= 29) return null; // MediaStore path: no runtime permission
    final status = await Permission.storage.request();
    if (status.isGranted) return null;
    return StorageResult(
      status.isPermanentlyDenied
          ? StorageStatus.permissionPermanentlyDenied
          : StorageStatus.permissionDenied,
      message: 'Storage permission denied.',
    );
  }

  Future<int> _sdkInt() async {
    try {
      return await _channel.invokeMethod<int>('getSdkInt') ?? 0;
    } on PlatformException {
      return 0;
    } on MissingPluginException {
      return 0;
    }
  }
}
