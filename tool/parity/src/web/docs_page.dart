/// Opens a component page of the hydrated docs site and waits until it is
/// worth driving — shared by every probe that plays input against it.
///
/// "Hydrated" is not a signal the page emits: the Web pane's island
/// attaches its handlers some time after load, and jaspr says nothing when
/// it is done. Each probe therefore proves hydration itself, by the effect
/// its first input has (a key reaching a listener, a hover opening a
/// panel). What this file owns is the part every probe shares — the page
/// load and the quiet period the page's embedded Flutter pane needs.
library;

import 'package:puppeteer/puppeteer.dart' as pptr;

/// How long the page's embedded Flutter view may take to attach.
const _kFlutterViewTimeout = Duration(seconds: 30);

/// Quiet period after the page's embedded Flutter view attaches. The docs
/// page mounts a Flutter pane beside the Web one, and while it initialises
/// its text-input host can take focus and its glass pane can claim the
/// pointer — an input sent inside that window lands nowhere and fails the
/// probe for a reason that is not the component's. The same settle
/// `tool/screenshot.dart` waits.
const _kSettleDelay = Duration(seconds: 2);

/// Opens `/components/<component>/` under [baseUrl] in [page], waits
/// (bounded) for the embedded Flutter view, then for a fixed settle.
Future<void> loadDocsComponentPage(
  pptr.Page page, {
  required Uri baseUrl,
  required String component,
}) async {
  final url = baseUrl.resolve('components/$component/');
  await page.goto(url.toString(), wait: pptr.Until.networkIdle);
  await _waitForFlutterView(page);
  await Future<void>.delayed(_kSettleDelay);
}

/// Opens `/embed/<component>` under [baseUrl] — the chrome-less route that
/// mounts one Web preview, the component's default registry example, and
/// nothing else. There is no Flutter pane on it, so nothing has to settle
/// before the first input.
///
/// A probe whose expectations are written against that example loads this
/// instead of the docs page: which previews a component page renders is an
/// editorial choice, and it changes without the example changing.
Future<void> loadDocsEmbedPage(
  pptr.Page page, {
  required Uri baseUrl,
  required String component,
}) async {
  final url = baseUrl.resolve('embed/$component/');
  await page.goto(url.toString(), wait: pptr.Until.networkIdle);
}

/// Waits (bounded) for the page's embedded Flutter view to attach. A page
/// whose Flutter pane never attaches is still probed — the Web pane does
/// not depend on it — so the timeout is not a failure.
Future<void> _waitForFlutterView(pptr.Page page) async {
  final _ = await page.evaluate<bool>(
    '''
(timeoutMs) => new Promise((resolve) => {
  const attached = () => !!document.querySelector('flutter-view, flt-glass-pane');
  if (attached()) return resolve(true);
  const timer = setTimeout(() => resolve(false), timeoutMs);
  new MutationObserver((_, observer) => {
    if (attached()) { observer.disconnect(); clearTimeout(timer); resolve(true); }
  }).observe(document.body, { childList: true, subtree: true });
})''',
    args: [_kFlutterViewTimeout.inMilliseconds],
  );
}
