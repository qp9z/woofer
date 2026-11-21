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

/// Bumped each time a shared link is dropped because a download owns yt-dlp, so
/// the shell can tell the user instead of the share vanishing silently.
final shareRejectedProvider = NotifierProvider<ShareRejections, int>(
  ShareRejections.new,
);

class ShareRejections extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

/// URLs shared into the app from other apps (text/plain): the cold-start share
/// first, then live shares while the app runs.
///
/// Watching this also routes each URL into [downloadControllerProvider] as if
/// the user pasted it — so your screen just needs to `ref.watch`/`ref.listen`
/// this to both display the URL and see the controller advance.
// ponytail: routing is lazy — it starts when something first listens. HomeShell
// holds the always-on listener (it is never offstage); a tab must NOT be the
// only subscriber, because Riverpod 3 pauses listeners of offstage widgets and a
// paused stream stops routing shared links.
final sharedUrlProvider = StreamProvider<String>((ref) async* {
  final controller = ref.read(downloadControllerProvider.notifier);
  // Read up front: `ref` must not be touched again once this stream is running.
  final rejected = ref.read(shareRejectedProvider.notifier);

  // Cold start: the share that launched the app. reset() so a provider rebuild
  // doesn't replay it.
  final initial = await ReceiveSharingIntent.instance.getInitialMedia();
  ReceiveSharingIntent.instance.reset();
  final initialUrl = _pickUrl(initial);
  if (initialUrl != null) {
    if (controller.canExtract) {
      unawaited(controller.extract(initialUrl));
      yield initialUrl;
    } else {
      rejected.bump();
    }
  }

  // Live shares while the app is already running.
  await for (final items in ReceiveSharingIntent.instance.getMediaStream()) {
    final url = _pickUrl(items);
    if (url != null) {
      if (controller.canExtract) {
        unawaited(controller.extract(url));
        yield url;
      } else {
        rejected.bump();
      }
    }
  }
});
