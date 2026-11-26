/// Images in a `RichEditor`: what a picked file is, what the app does with
/// it, the rules both platforms share, and the state they keep about the
/// uploads.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// How long a removed image waits before it is reported for deletion. A
/// behaviour delay, not an animation timing.
const Duration _kDeleteDelay = Duration(seconds: 10);

/// An image the user picked, handed to `onImageUpload`.
@immutable
class CoreRichEditorImageFile {
  /// Creates a [CoreRichEditorImageFile].
  const CoreRichEditorImageFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  /// The file's name (`photo.png`), without its folder.
  final String name;

  /// The file's MIME type — one of [CoreRichEditorImage.mimeTypes].
  final String mimeType;

  /// The file's content.
  final Uint8List bytes;

  /// The file's size in bytes.
  int get size => bytes.length;
}

/// Uploads [file] to the app's server and completes with the URL the image
/// can be shown from. That URL is what the Markdown holds: `![photo](url)`.
///
/// Throw to refuse the upload; the editor then shows it failed.
typedef CoreRichEditorImageUpload =
    Future<String> Function(CoreRichEditorImageFile file);

/// Deletes the image at [url] — one `onImageUpload` returned — from the
/// app's server. See `CoreRichEditorContract.onImageDelete` for when the
/// editor asks for it.
typedef CoreRichEditorImageDelete = Future<void> Function(String url);

/// Why an image was not added.
enum CoreRichEditorImageIssue {
  /// The file is not one of [CoreRichEditorImage.mimeTypes].
  notAllowed,

  /// The file is bigger than the editor's `maxImageBytes`.
  tooLarge,

  /// `onImageUpload` threw, or returned an address the editor will not
  /// show (see [CoreRichEditorImage.normalizeSource]).
  uploadFailed,
}

/// The rules about images that both platforms read.
abstract final class CoreRichEditorImage {
  /// The image types the editor accepts. SVG is left out: it can carry
  /// script, and nothing in a comment needs it.
  static const List<String> mimeTypes = [
    'image/png',
    'image/jpeg',
    'image/gif',
    'image/webp',
  ];

  /// The file extensions of [mimeTypes], lower-case, without the dot — what
  /// a file picker filters on.
  static const List<String> extensions = ['png', 'jpg', 'jpeg', 'gif', 'webp'];

  /// Default for `maxImageBytes`: 10 MiB. The editor reads a picked file
  /// into memory before it hands it over, so the limit is checked first.
  static const int defaultMaxBytes = 10 * 1024 * 1024;

  /// How long an image the user removed stays unreported to `onImageDelete`
  /// — long enough to undo the removal or to cut an image and paste it
  /// elsewhere.
  static const Duration deleteDelay = _kDeleteDelay;

  /// The MIME type a file named [fileName] has, or null when its extension
  /// is not one of [extensions].
  static String? mimeTypeOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0) return null;
    return switch (fileName.substring(dot + 1).toLowerCase()) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => null,
    };
  }

  /// Why a file cannot be added, or null when it can.
  ///
  /// [mimeType] is what the platform reported (null or empty when it did
  /// not, then the extension decides); [size] is in bytes; [maxBytes] is the
  /// editor's `maxImageBytes` (null for no limit).
  static CoreRichEditorImageIssue? check({
    required String name,
    required int size,
    String? mimeType,
    int? maxBytes,
  }) {
    final reported = mimeType?.toLowerCase();
    final allowed = reported == null || reported.isEmpty
        ? mimeTypeOf(name) != null
        : mimeTypes.contains(reported);
    if (!allowed) return CoreRichEditorImageIssue.notAllowed;
    if (maxBytes != null && size > maxBytes) {
      return CoreRichEditorImageIssue.tooLarge;
    }
    return null;
  }

  /// The alternative text an image gets from its file name: the name
  /// without folder or extension (`holiday-2026.png` → `holiday-2026`).
  static String altTextFor(String fileName) {
    var name = fileName.split(RegExp(r'[\\/]')).last;
    final dot = name.lastIndexOf('.');
    if (dot > 0) name = name.substring(0, dot);
    return name.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static final RegExp _kUnsafeChars = RegExp(r'[\s\x00-\x1f<>"`]');
  static final RegExp _kDataImage = RegExp(
    r'^data:image/(?:png|jpeg|gif|webp|avif|bmp);base64,[A-Za-z0-9+/_=-]+$',
    caseSensitive: false,
  );

  /// The address an image may be shown from, or null for one the editor
  /// refuses — a `javascript:` or `file:` address never reaches the
  /// document.
  ///
  /// Accepted: `http(s)`, a base64 `data:image/…` of the types in
  /// [mimeTypes] (and AVIF / BMP), and an address with no scheme (a path on
  /// the page's own server; it only loads on the web). A `blob:` address is
  /// refused: it lives as long as the page that made it, so in a Markdown
  /// value it would be a picture that is gone the next time it is opened.
  /// Anything with whitespace, control characters or `<>"` in it is
  /// refused.
  static String? normalizeSource(String input) {
    final value = input.trim();
    if (value.isEmpty || _kUnsafeChars.hasMatch(value)) return null;
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    if (!uri.hasScheme) return value;
    return switch (uri.scheme.toLowerCase()) {
      'http' || 'https' => uri.host.isEmpty ? null : value,
      'data' => _kDataImage.hasMatch(value) ? value : null,
      _ => null,
    };
  }

  /// The Markdown of an image: `![alt](url)`, with the characters that
  /// would end it early written out.
  static String markdown({required String alt, required String url}) {
    final label = alt
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .replaceAllMapped(RegExp(r'[\\\[\]]'), (m) => '\\${m[0]}');
    final destination = url.replaceAll('(', '%28').replaceAll(')', '%29');
    return '![$label]($destination)';
  }
}

/// One upload that is under way or has failed — a row above the editor.
@immutable
class CoreRichEditorPendingImage {
  /// Creates a [CoreRichEditorPendingImage].
  const CoreRichEditorPendingImage({
    required this.id,
    required this.name,
    this.issue,
  });

  /// Identifies the row.
  final int id;

  /// The file's name.
  final String name;

  /// Why the image was not added; null while it is uploading.
  final CoreRichEditorImageIssue? issue;

  /// Whether the upload is still under way.
  bool get uploading => issue == null;
}

/// What both `RichEditor`s keep about images, apart from drawing them: the
/// uploads under way or failed, and which uploaded images may be deleted
/// from the server.
///
/// The platform picks a file and hands it to [submit]; a URL back means the
/// image is ready to go into the document. After every change of the
/// document the platform reports the image URLs it now holds with [sync].
///
/// **The editor only deletes what it uploaded.** An image that was in the
/// Markdown the editor started with is never reported to [delete]: whether
/// the edit will be saved is not the editor's to know.
///
/// An uploaded image that is not in the document is reported to [delete]
/// once, after [deleteDelay], unless it comes back first (undo, or a cut
/// and paste), and immediately when the editor goes away ([dispose]). A
/// document replaced from outside is not the user's removal: [reset] makes
/// the editor forget what it uploaded.
class CoreRichEditorImages {
  /// Creates the image state. [scheduler] makes the delay testable.
  CoreRichEditorImages({
    this.onChanged,
    this.upload,
    this.delete,
    this.maxBytes = CoreRichEditorImage.defaultMaxBytes,
    this.deleteDelay = CoreRichEditorImage.deleteDelay,
    Timer Function(Duration, void Function())? scheduler,
  }) : _schedule = scheduler ?? Timer.new;

  /// Called whenever [pending] changes.
  void Function()? onChanged;

  /// The app's upload; the editor takes images only with this and [delete].
  CoreRichEditorImageUpload? upload;

  /// The app's delete: what taking an uploaded image out means on its server.
  /// Without it the editor takes no images ([enabled]).
  CoreRichEditorImageDelete? delete;

  /// The largest file accepted, in bytes; null for no limit.
  int? maxBytes;

  /// How long a removed image waits before it is reported to [delete].
  final Duration deleteDelay;

  final Timer Function(Duration, void Function()) _schedule;

  final List<CoreRichEditorPendingImage> _pending = [];
  final Set<String> _uploaded = {};
  final Set<String> _deleted = {};
  final Map<String, Timer> _timers = {};
  Set<String> _present = {};
  var _nextId = 0;
  var _disposed = false;

  /// Whether the editor takes images: the app gave an [upload] and the
  /// [delete] that goes with it.
  ///
  /// An upload alone would leave every image the user takes out on the
  /// server for good, with nobody told — so the editor offers no images
  /// until the app has said what removing one means (a delete that does
  /// nothing is an answer too).
  bool get enabled => upload != null && delete != null;

  /// The uploads under way and the failed ones, oldest first.
  List<CoreRichEditorPendingImage> get pending => List.unmodifiable(_pending);

  void _notify() {
    if (!_disposed) onChanged?.call();
  }

  /// Records that the file [name] was not added, for [issue] — a file the
  /// platform refused before reading it.
  void reject(String name, CoreRichEditorImageIssue issue) {
    if (_disposed) return;
    _pending.add(
      CoreRichEditorPendingImage(id: _nextId++, name: name, issue: issue),
    );
    _notify();
  }

  /// Checks [file], uploads it, and completes with the URL to put in the
  /// document, or null when the image was not added (a row above the editor
  /// then says why).
  Future<String?> submit(CoreRichEditorImageFile file) async {
    final handler = upload;
    if (handler == null || _disposed) return null;
    final issue = CoreRichEditorImage.check(
      name: file.name,
      mimeType: file.mimeType,
      size: file.size,
      maxBytes: maxBytes,
    );
    if (issue != null) {
      reject(file.name, issue);
      return null;
    }
    final id = _nextId++;
    _pending.add(CoreRichEditorPendingImage(id: id, name: file.name));
    _notify();

    String? returned;
    String? url;
    try {
      returned = await handler(file);
      url = CoreRichEditorImage.normalizeSource(returned);
    } on Object {
      url = null;
    }
    _pending.removeWhere((entry) => entry.id == id);
    if (url == null) {
      // The app answered, but with an address that cannot be shown (a
      // `blob:` URL, say): its server holds the file all the same, and no
      // document will ever hold the address.
      if (returned != null && returned.trim().isNotEmpty) _report(returned);
      _pending.add(
        CoreRichEditorPendingImage(
          id: id,
          name: file.name,
          issue: CoreRichEditorImageIssue.uploadFailed,
        ),
      );
      _notify();
      return null;
    }
    if (_disposed) {
      // The editor went away while the file was on its way: nobody will
      // ever put it in a document.
      _report(url);
      return null;
    }
    _uploaded.add(url);
    _deleted.remove(url);
    _notify();
    return url;
  }

  /// Removes the failed row [id].
  void dismiss(int id) {
    final before = _pending.length;
    _pending.removeWhere((entry) => entry.id == id && !entry.uploading);
    if (_pending.length != before) _notify();
  }

  /// Reports the image URLs the document holds now.
  void sync(Iterable<String> urls) {
    if (_disposed) return;
    _present = urls.toSet();
    for (final url in _uploaded.toList()) {
      if (_present.contains(url)) {
        _timers.remove(url)?.cancel();
      } else if (!_timers.containsKey(url)) {
        _timers[url] = _schedule(deleteDelay, () => _expire(url));
      }
    }
  }

  void _expire(String url) {
    _timers.remove(url);
    if (_present.contains(url)) return;
    _uploaded.remove(url);
    _report(url);
  }

  void _report(String url) {
    if (!_deleted.add(url)) return;
    final handler = delete;
    if (handler == null) return;
    // Not awaited: the document does not wait for the server, and an error
    // goes to the app's own error handling like any other.
    unawaited(Future<void>.sync(() => handler(url)));
  }

  /// Forgets what the editor uploaded — the document was replaced from
  /// outside, so its images belong to whoever supplied the new content.
  void reset() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _uploaded.clear();
    _deleted.clear();
    _present = {};
  }

  /// Ends the state: images removed and not yet reported are reported now.
  void dispose() {
    if (_disposed) return;
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    for (final url in _uploaded.toList()) {
      if (!_present.contains(url)) _report(url);
    }
    _uploaded.clear();
    _disposed = true;
  }
}
