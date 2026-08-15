import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'download_controller.dart';

/// The first http(s) URL inside shared text. Apps often prepend a title
/// ("Cool clip https://youtu.be/x"), so we pull the link out rather than
/// trusting the whole string.
String? firstUrl(String text) =>
    RegExp(r'https?://\S+').firstMatch(text)?.group(0);

/// First shared text/url item that contains a URL.
String? _pickUrl(List<SharedMediaFile> items) {
  for (final it in items) {
    if (it.type == SharedMediaType.text || it.type == SharedMediaType.url) {
      final url = firstUrl(it.path);
      if (url != null) return url;
    }
  }
  return null;
}

/// URLs shared into the app from other apps (text/plain): the cold-start share
/// first, then live shares while the app runs.
///
/// Watching this also routes each URL into [downloadControllerProvider] as if
/// the user pasted it — so your screen just needs to `ref.watch`/`ref.listen`
/// this to both display the URL and see the controller advance.
// ponytail: routing is lazy — it activates when a screen watches this provider
// (there's no UI to route to otherwise). Keep it alive in your root if you want
// it always-on regardless of which screen is mounted.
final sharedUrlProvider = StreamProvider<String>((ref) async* {
  final controller = ref.read(downloadControllerProvider.notifier);

  // Cold start: the share that launched the app. reset() so a provider rebuild
  // doesn't replay it.
  final initial = await ReceiveSharingIntent.instance.getInitialMedia();
  ReceiveSharingIntent.instance.reset();
  final initialUrl = _pickUrl(initial);
  if (initialUrl != null && controller.canExtract) {
    unawaited(controller.extract(initialUrl));
    yield initialUrl;
  }

  // Live shares while the app is already running.
  await for (final items in ReceiveSharingIntent.instance.getMediaStream()) {
    final url = _pickUrl(items);
    if (url != null && controller.canExtract) {
      unawaited(controller.extract(url));
      yield url;
    }
  }
});
