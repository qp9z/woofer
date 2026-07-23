import '../services/api_exception.dart';

/// Display helpers shared by the screens. Pure functions — no widgets.

/// "1.4 GB", "720 KB", "—" when unknown.
String formatBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return '—';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  // Whole numbers for bytes and for anything >= 100; one decimal otherwise.
  final digits = (unit == 0 || value >= 100) ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

/// Seconds -> "3:07" or "1:02:07".
String formatDuration(double? seconds) {
  if (seconds == null || seconds <= 0) return '';
  final total = seconds.round();
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
}

/// "22 Jul 2026" — no intl dependency for one date format.
String formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// Short, human headline for an error state. The controller's message carries
/// the detail; this is the title above it.
String describeError(ApiErrorCode code) => switch (code) {
      ApiErrorCode.private => 'This video is private',
      ApiErrorCode.unavailable => 'Video unavailable',
      ApiErrorCode.unsupported => 'Site not supported',
      ApiErrorCode.noVideo => 'No video here',
      ApiErrorCode.invalidUrl => 'That link looks wrong',
      ApiErrorCode.tooLarge => 'Not enough space',
      ApiErrorCode.rateLimited => 'Slow down a moment',
      ApiErrorCode.botCheck => 'YouTube is blocking us',
      ApiErrorCode.network => 'Connection problem',
      ApiErrorCode.unknown => 'Something went wrong',
    };
