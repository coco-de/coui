// #3908 — parity capture must not depend on real network reachability.
//
// A handful of docs examples this file's manifest entries render
// (`Diff`/`HoverGallery`/`CardImage`) use `Image.network(...)` against real
// CDNs (`img.daisyui.com`/`picsum.photos`) so the docs site shows realistic
// photography, not because the *capture* cares what the pixels are — the
// capture's own contract only ever reads chrome (padding/border/color/…),
// never image content (`flutter_capture_matrix_test.dart`'s own
// `_isVacuousSnapshot` paint-relevant field list has no image-content
// field). On a GitHub Actions hosted runner these CDNs intermittently
// return `HTTP 400` to the exact same request `dart:io HttpClient` sends
// successfully in isolation (confirmed empirically: a diagnostic step
// issuing the identical unheaded `HttpClient.getUrl` request immediately
// before this test file runs got `200` every time; the failure only shows
// up once several of this file's entries request the same CDN host in
// quick succession) — a shared-IP rate-limit/bot-mitigation edge case this
// test suite has no business being sensitive to. `NetworkImageLoadException`
// then fails not just the entry that requested the image but, because the
// exception surfaces asynchronously (the image `Future` can resolve after
// its own `testWidgets` body has already returned), whichever *later*
// entry happens to be running when the error is finally delivered —
// `mockup-phone`/`window-default` failing alongside `diff`/`hover-gallery`/
// `card-image` in the same run is exactly that, not four independent CDN
// bugs (`mockup-phone`/`window-default` failures are a real, unrelated
// layout defect — see #3908's own PR for the follow-up issue, not this
// file).
//
// The fix is `debugNetworkImageHttpClientProvider`
// (`package:flutter/painting.dart`) — the same hook Flutter's own SDK test
// suite uses for exactly this purpose
// (`packages/flutter/test/painting/image_provider_network_image_test.dart`)
// — so every `NetworkImage` load in this test process is served a locally
// shared, always-decodable PNG instead of ever touching the network.
// This is deliberately scoped to *this test process only* — the doc
// example source (`docs_core/lib/previews/examples/**`) is untouched. The Web
// capture uses the same fixture bytes; docs_site visitors keep real photos.
//
// Scoping: `debugNetworkImageHttpClientProvider` must be set-then-unset
// *inside every single `testWidgets` body*, not once for the whole file —
// `TestWidgetsFlutterBinding._verifyInvariants` (via
// `debugAssertAllPaintingVarsUnset`) asserts every `debug*` painting
// global is back to its default the instant each `testWidgets` callback
// returns, and fails the *next* entry with "The value of a painting debug
// variable was changed by the test" if it's still set (confirmed
// empirically — a `setUpAll`-only version of this fix passed its first
// entry and failed every one after). [runParityEntryWithStubbedNetwork]
// is the wrap-every-entry helper that keeps this scoped correctly while
// still only reading the placeholder PNG once per file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart' show debugNetworkImageHttpClientProvider;
import 'package:flutter/widgets.dart' show Image, precacheImage;
import 'package:flutter_test/flutter_test.dart' show Fake, WidgetTester, find;

import '../../../../tool/parity/src/model/network_image_fixture.dart';

/// Loads the placeholder PNG once (call from `setUpAll`) and hands the
/// result to [runParityEntryWithStubbedNetwork] for every entry — avoids
/// re-reading the shared flat-color PNG per manifest entry while still
/// letting each entry scope the debug hook to just itself.
Future<Uint8List> renderParityStubImageBytes() => _renderStubImageBytes();

/// Runs [body] with [debugNetworkImageHttpClientProvider] pointed at a
/// stub `HttpClient` that resolves every `NetworkImage` request to
/// [stubImageBytes], then always unsets it before returning — see this
/// file's top comment for why the unset has to happen inside every single
/// `testWidgets` body rather than once for the whole suite.
Future<T> runParityEntryWithStubbedNetwork<T>(
  Uint8List stubImageBytes,
  Future<T> Function() body,
) async {
  debugNetworkImageHttpClientProvider = () => _StubHttpClient(stubImageBytes);
  try {
    return await body();
  } finally {
    debugNetworkImageHttpClientProvider = null;
  }
}

/// Waits until every [Image] in the pumped tree has decoded, then pumps
/// once so the decoded frames are painted.
///
/// The stub above makes the *bytes* deterministic, not the moment they
/// arrive. Decoding is real async work, and a `testWidgets` body only
/// lets real async work run inside `runAsync` — so the first entry in a
/// run to request an image was captured before its decode completed and
/// painted the page background where the image should be, while every
/// later entry found the decoded image already in the image cache and
/// painted it. Which entry came first was an accident of manifest order:
/// the light `liquidGlass` hover gallery happened to lead, so it alone
/// read as "the style changed 99.9% of the pixels", against a baseline
/// that simply had its image.
///
/// Resolving the providers here makes every entry paint the same stub no
/// matter where it sits in the run. A tree with no [Image] returns at
/// once.
Future<void> settleImagesInTree(WidgetTester tester) async {
  final elements = find.byType(Image).evaluate().toList();
  if (elements.isEmpty) return;
  await tester.runAsync(() async {
    for (final element in elements) {
      final widget = element.widget as Image;
      await precacheImage(widget.image, element);
    }
  });
  await tester.pump();
}

/// Loads the shared 400 × 300 flat-color PNG used by both capture backends.
Future<Uint8List> _renderStubImageBytes() async =>
    loadParityNetworkImageBytes();

/// Minimal fake covering only the members `NetworkImage._loadAsync`
/// (`package:flutter/src/painting/_network_image_io.dart`) actually calls —
/// same shape as the Flutter SDK's own `_FakeHttpClient` in
/// `image_provider_network_image_test.dart`.
class _StubHttpClient extends Fake implements HttpClient {
  _StubHttpClient(this._bytes);

  final Uint8List _bytes;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _StubHttpClientRequest(_bytes);
}

class _StubHttpClientRequest extends Fake implements HttpClientRequest {
  _StubHttpClientRequest(this._bytes);

  final Uint8List _bytes;

  @override
  final HttpHeaders headers = _StubHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _StubHttpClientResponse(_bytes);
}

class _StubHttpClientResponse extends Fake implements HttpClientResponse {
  _StubHttpClientResponse(this._bytes);

  final Uint8List _bytes;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable(<List<int>>[
      _bytes,
    ]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _StubHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}
