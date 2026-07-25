import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// The download's presence outside the app: the ongoing progress notification
/// that keeps it alive, and the one that reports how it ended.
///
/// The pipeline runs in the Dart isolate, so it only lives as long as the process
/// does. [show] starts a native foreground service that pins the process at
/// foreground priority (and survives the task being swiped away); [hide] stops it;
/// [showResult] posts the outcome on a separate channel that outlives the service.
///
/// Copy is written here rather than natively so the notification and the screens
/// say the same thing. Every call is best-effort — a notification that failed to
/// appear must never fail a download, so nothing here throws.
///
/// Shares the `woofer/storage` channel rather than adding a second one; the
/// native side is a single MethodChannel handler.
class ForegroundService {
  static const MethodChannel _defaultChannel = MethodChannel('woofer/storage');

  final MethodChannel _channel;
  ForegroundService({MethodChannel? channel}) : _channel = channel ?? _defaultChannel;

  bool _askedForNotifications = false;

  /// Start or refresh the ongoing notification. [percent] < 0 shows an
  /// indeterminate bar — merging and transcoding have no reliable percentage.
  Future<void> show(String title, {required String text, int percent = -1}) async {
    // Android 13+ needs the grant to *display* it. The service runs either way,
    // so ask once and never block on the answer.
    if (!_askedForNotifications) {
      _askedForNotifications = true;
      try {
        await Permission.notification.request();
      } catch (_) {}
    }
    await _invoke('showDownloadNotification', {
      'title': title,
      'text': text,
      'percent': percent,
    });
  }

  Future<void> hide() => _invoke('hideDownloadNotification', const <String, dynamic>{});

  /// Report the outcome. Passing [uri] makes tapping it open the saved file;
  /// leaving it null (a failure) makes the tap reopen WOOFER.
  Future<void> showResult(
    String title,
    String text, {
    String? uri,
    String? mimeType,
  }) =>
      _invoke('showDownloadResult', {
        'title': title,
        'text': text,
        'uri': uri,
        'mimeType': mimeType,
      });

  /// Run [onCancel] when the notification's Cancel button is tapped.
  void onCancelRequested(void Function() onCancel) {
    try {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'cancelDownload') onCancel();
        return null;
      });
    } catch (_) {}
  }

  Future<void> _invoke(String method, Map<String, dynamic> args) async {
    try {
      await _channel.invokeMethod<bool>(method, args);
    } on PlatformException {
      // ignored: see class doc
    } on MissingPluginException {
      // ignored: off-device (tests) there is no native side
    }
  }
}
