// Tests for the `RichEditor` image rules both platforms share — which files
// and addresses are accepted, the Markdown an image is written as — and for
// [CoreRichEditorImages], the upload / delete state machine around them.

import 'dart:async';
import 'dart:typed_data';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

CoreRichEditorImageFile _file({
  String name = 'photo.png',
  String mimeType = 'image/png',
  int size = 4,
}) => CoreRichEditorImageFile(
  name: name,
  mimeType: mimeType,
  bytes: Uint8List(size),
);

/// A timer the test fires by hand.
class _FakeTimer implements Timer {
  _FakeTimer(this.callback);

  final void Function() callback;
  bool cancelled = false;
  bool fired = false;

  void fire() {
    if (cancelled || fired) return;
    fired = true;
    callback();
  }

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled && !fired;

  @override
  int get tick => fired ? 1 : 0;
}

class _Harness {
  _Harness({
    this.maxBytes = 1000,
    Future<String> Function(CoreRichEditorImageFile file)? upload,
    bool withDelete = true,
  }) {
    images = CoreRichEditorImages(
      onChanged: () => changes++,
      upload:
          upload ??
          (file) async {
            uploads.add(file.name);
            return 'https://cdn.test/${file.name}';
          },
      delete: withDelete
          ? (url) async {
              deleted.add(url);
            }
          : null,
      maxBytes: maxBytes,
      scheduler: (duration, callback) {
        final timer = _FakeTimer(callback);
        timers.add(timer);
        delays.add(duration);
        return timer;
      },
    );
  }

  late final CoreRichEditorImages images;
  final int? maxBytes;
  final uploads = <String>[];
  final deleted = <String>[];
  final timers = <_FakeTimer>[];
  final delays = <Duration>[];
  int changes = 0;

  /// Lets the unawaited delete call run.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  void fireAll() {
    for (final timer in List.of(timers)) {
      timer.fire();
    }
  }
}

void main() {
  group('CoreRichEditorImage.mimeTypeOf', () {
    test('reads the extension, in any case', () {
      expect(CoreRichEditorImage.mimeTypeOf('a.PNG'), 'image/png');
      expect(CoreRichEditorImage.mimeTypeOf('a.jpg'), 'image/jpeg');
      expect(CoreRichEditorImage.mimeTypeOf('a.JPEG'), 'image/jpeg');
      expect(CoreRichEditorImage.mimeTypeOf('a.gif'), 'image/gif');
      expect(CoreRichEditorImage.mimeTypeOf('a.webp'), 'image/webp');
    });

    test('knows nothing of other extensions', () {
      expect(CoreRichEditorImage.mimeTypeOf('a.svg'), isNull);
      expect(CoreRichEditorImage.mimeTypeOf('a.heic'), isNull);
      expect(CoreRichEditorImage.mimeTypeOf('png'), isNull);
    });

    test('every accepted extension maps to an accepted type', () {
      for (final extension in CoreRichEditorImage.extensions) {
        expect(
          CoreRichEditorImage.mimeTypes,
          contains(CoreRichEditorImage.mimeTypeOf('x.$extension')),
          reason: extension,
        );
      }
    });
  });

  group('CoreRichEditorImage.check', () {
    test('accepts the four image types', () {
      for (final type in CoreRichEditorImage.mimeTypes) {
        expect(
          CoreRichEditorImage.check(name: 'x', mimeType: type, size: 1),
          isNull,
          reason: type,
        );
      }
    });

    test('refuses SVG and anything that is not an image', () {
      expect(
        CoreRichEditorImage.check(
          name: 'x.svg',
          mimeType: 'image/svg+xml',
          size: 1,
        ),
        CoreRichEditorImageIssue.notAllowed,
      );
      expect(
        CoreRichEditorImage.check(
          name: 'x.png',
          mimeType: 'text/plain',
          size: 1,
        ),
        CoreRichEditorImageIssue.notAllowed,
      );
    });

    test('falls back to the extension when no type was reported', () {
      expect(CoreRichEditorImage.check(name: 'x.webp', size: 1), isNull);
      expect(
        CoreRichEditorImage.check(name: 'x.webp', mimeType: '', size: 1),
        isNull,
      );
      expect(
        CoreRichEditorImage.check(name: 'x.bmp', size: 1),
        CoreRichEditorImageIssue.notAllowed,
      );
    });

    test('the limit is inclusive', () {
      expect(
        CoreRichEditorImage.check(
          name: 'x.png',
          mimeType: 'image/png',
          size: 10,
          maxBytes: 10,
        ),
        isNull,
      );
      expect(
        CoreRichEditorImage.check(
          name: 'x.png',
          mimeType: 'image/png',
          size: 11,
          maxBytes: 10,
        ),
        CoreRichEditorImageIssue.tooLarge,
      );
    });

    test('no limit means any size', () {
      expect(
        CoreRichEditorImage.check(
          name: 'x.png',
          mimeType: 'image/png',
          size: 1 << 40,
        ),
        isNull,
      );
    });

    test('the type is judged before the size', () {
      expect(
        CoreRichEditorImage.check(
          name: 'x.svg',
          mimeType: 'image/svg+xml',
          size: 100,
          maxBytes: 10,
        ),
        CoreRichEditorImageIssue.notAllowed,
      );
    });

    test('the default limit is 10 MiB', () {
      expect(CoreRichEditorImage.defaultMaxBytes, 10 * 1024 * 1024);
      expect(
        CoreRichEditorContract.defaultMaxImageBytes,
        CoreRichEditorImage.defaultMaxBytes,
      );
    });
  });

  group('CoreRichEditorImage.altTextFor', () {
    test('drops the extension', () {
      expect(
        CoreRichEditorImage.altTextFor('holiday-2026.png'),
        'holiday-2026',
      );
    });

    test('drops the folder, either separator', () {
      expect(CoreRichEditorImage.altTextFor('a/b/photo.jpg'), 'photo');
      expect(CoreRichEditorImage.altTextFor(r'C:\Users\me\photo.jpg'), 'photo');
    });

    test('keeps inner dots and collapses blanks', () {
      expect(CoreRichEditorImage.altTextFor('photo.final.jpeg'), 'photo.final');
      expect(
        CoreRichEditorImage.altTextFor('my   big  photo.gif'),
        'my big photo',
      );
    });

    test('a name that is only an extension stays', () {
      expect(CoreRichEditorImage.altTextFor('.png'), '.png');
    });
  });

  group('CoreRichEditorImage.normalizeSource', () {
    test('accepts web addresses', () {
      expect(
        CoreRichEditorImage.normalizeSource('https://cdn.test/a.png'),
        'https://cdn.test/a.png',
      );
      expect(
        CoreRichEditorImage.normalizeSource('  http://cdn.test/a.png '),
        'http://cdn.test/a.png',
      );
      expect(
        CoreRichEditorImage.normalizeSource('HTTPS://cdn.test/a.png'),
        'HTTPS://cdn.test/a.png',
      );
    });

    test("accepts a path on the page's own server", () {
      expect(
        CoreRichEditorImage.normalizeSource('/uploads/a.png'),
        '/uploads/a.png',
      );
      expect(
        CoreRichEditorImage.normalizeSource('uploads/a.png'),
        'uploads/a.png',
      );
      expect(
        CoreRichEditorImage.normalizeSource('//cdn.test/a.png'),
        '//cdn.test/a.png',
      );
    });

    test('accepts base64 images', () {
      expect(
        CoreRichEditorImage.normalizeSource(
          'data:image/png;base64,iVBORw0KGgo=',
        ),
        'data:image/png;base64,iVBORw0KGgo=',
      );
    });

    test('refuses script, files and other schemes', () {
      for (final bad in const [
        'javascript:alert(1)',
        'JaVaScRiPt:alert(1)',
        'vbscript:x',
        'file:///etc/passwd',
        'ftp://x.test/a.png',
        'about:blank',
        // Gone with the page that made it: not a value worth saving.
        'blob:https://x.test/0123-4567',
      ]) {
        expect(CoreRichEditorImage.normalizeSource(bad), isNull, reason: bad);
      }
    });

    test('refuses data addresses that are not a base64 raster image', () {
      for (final bad in const [
        'data:image/svg+xml;base64,PHN2Zz4=',
        'data:text/html;base64,PGI+',
        'data:image/png,notbase64',
        'data:image/png;base64,',
      ]) {
        expect(CoreRichEditorImage.normalizeSource(bad), isNull, reason: bad);
      }
    });

    test('refuses an address that cannot sit in Markdown or an attribute', () {
      for (final bad in const [
        '',
        '   ',
        'https://x.test/a b.png',
        'https://x.test/a"b.png',
        'https://x.test/<a>.png',
        'https://x.test/a`b.png',
        'https://x.test/a\nb.png',
        'https://',
      ]) {
        expect(CoreRichEditorImage.normalizeSource(bad), isNull, reason: bad);
      }
    });
  });

  group('CoreRichEditorImage.markdown', () {
    test('writes ![alt](url)', () {
      expect(
        CoreRichEditorImage.markdown(alt: 'photo', url: 'https://x.test/a.png'),
        '![photo](https://x.test/a.png)',
      );
    });

    test('writes out what would end the label early', () {
      expect(
        CoreRichEditorImage.markdown(alt: r'a [b] \c', url: '/a.png'),
        r'![a \[b\] \\c](/a.png)',
      );
      expect(
        CoreRichEditorImage.markdown(alt: 'two\nlines', url: '/a.png'),
        '![two lines](/a.png)',
      );
    });

    test('writes out parentheses in the address', () {
      expect(
        CoreRichEditorImage.markdown(alt: 'x', url: 'https://x.test/a_(1).png'),
        '![x](https://x.test/a_%281%29.png)',
      );
    });
  });

  group('CoreRichEditorImages.submit', () {
    test(
      'shows the row while it uploads, then hands the address back',
      () async {
        final gate = Completer<String>();
        final h = _Harness(upload: (file) => gate.future);

        final result = h.images.submit(_file());
        expect(h.images.pending, hasLength(1));
        expect(h.images.pending.single.name, 'photo.png');
        expect(h.images.pending.single.uploading, isTrue);

        gate.complete('https://cdn.test/photo.png');
        expect(await result, 'https://cdn.test/photo.png');
        expect(h.images.pending, isEmpty);
        expect(h.changes, 2, reason: 'row added, row removed');
      },
    );

    test('a refused file never reaches the upload', () async {
      final h = _Harness(maxBytes: 3);
      expect(await h.images.submit(_file()), isNull);
      expect(
        await h.images.submit(_file(name: 'a.svg', mimeType: 'image/svg+xml')),
        isNull,
      );
      expect(h.uploads, isEmpty);
      expect(h.images.pending.map((p) => p.issue), [
        CoreRichEditorImageIssue.tooLarge,
        CoreRichEditorImageIssue.notAllowed,
      ]);
      expect(h.images.pending.every((p) => !p.uploading), isTrue);
    });

    test('an upload that throws leaves a failed row', () async {
      final h = _Harness(upload: (file) async => throw StateError('503'));
      expect(await h.images.submit(_file()), isNull);
      expect(
        h.images.pending.single.issue,
        CoreRichEditorImageIssue.uploadFailed,
      );
    });

    test('an address the editor refuses fails the upload', () async {
      final h = _Harness(upload: (file) async => 'javascript:alert(1)');
      expect(await h.images.submit(_file()), isNull);
      expect(
        h.images.pending.single.issue,
        CoreRichEditorImageIssue.uploadFailed,
      );
    });

    test(
      'a file stored under an address the editor refuses is reported for '
      'deletion at once, and only once',
      () async {
        final h = _Harness(
          upload: (file) async => 'blob:https://x.test/0123-4567',
        );
        expect(await h.images.submit(_file()), isNull);
        expect(
          h.images.pending.single.issue,
          CoreRichEditorImageIssue.uploadFailed,
        );
        await h.settle();
        expect(h.deleted, ['blob:https://x.test/0123-4567']);

        // The same refused address again does not reach the app twice.
        expect(await h.images.submit(_file(name: 'b.png')), isNull);
        await h.settle();
        expect(h.deleted, hasLength(1));
      },
    );

    test(
      'an upload that threw, or answered nothing, has nothing to delete',
      () async {
        final thrown = _Harness(
          upload: (file) async => throw StateError('503'),
        );
        await thrown.images.submit(_file());
        final blank = _Harness(upload: (file) async => '   ');
        await blank.images.submit(_file());
        await thrown.settle();
        await blank.settle();
        expect(thrown.deleted, isEmpty);
        expect(blank.deleted, isEmpty);
      },
    );

    test('a failed row can be dismissed, an uploading one cannot', () async {
      final gate = Completer<String>();
      final h = _Harness(upload: (file) => gate.future);
      final result = h.images.submit(_file());
      final uploadingId = h.images.pending.single.id;
      h.images.dismiss(uploadingId);
      expect(h.images.pending, hasLength(1), reason: 'still uploading');

      gate.completeError(StateError('boom'));
      await result;
      expect(
        h.images.pending.single.issue,
        CoreRichEditorImageIssue.uploadFailed,
      );
      h.images.dismiss(h.images.pending.single.id);
      expect(h.images.pending, isEmpty);
    });

    test('without an upload the editor takes nothing', () async {
      final images = CoreRichEditorImages();
      expect(images.enabled, isFalse);
      expect(await images.submit(_file()), isNull);
      expect(images.pending, isEmpty);
    });

    test('the editor takes images only with an upload and its delete', () {
      Future<String> upload(CoreRichEditorImageFile file) async => 'u';
      Future<void> delete(String url) async {}
      // An upload alone would leave every removed image on the server.
      expect(CoreRichEditorImages(upload: upload).enabled, isFalse);
      // A delete alone has nothing to delete.
      expect(CoreRichEditorImages(delete: delete).enabled, isFalse);
      expect(
        CoreRichEditorImages(upload: upload, delete: delete).enabled,
        isTrue,
      );
    });

    test('reject records a file refused before it was read', () {
      final h = _Harness();
      h.images.reject('huge.png', CoreRichEditorImageIssue.tooLarge);
      expect(h.images.pending.single.name, 'huge.png');
      expect(h.images.pending.single.issue, CoreRichEditorImageIssue.tooLarge);
    });
  });

  group('CoreRichEditorImages deletion', () {
    test('an image that stays in the document is never deleted', () async {
      final h = _Harness();
      final url = (await h.images.submit(_file()))!;
      h.images.sync([url]);
      h.images.sync([url, 'https://other.test/b.png']);
      expect(h.timers, isEmpty);
      h.fireAll();
      await h.settle();
      expect(h.deleted, isEmpty);
    });

    test('a removed image is deleted once, after the delay', () async {
      final h = _Harness();
      final url = (await h.images.submit(_file()))!;
      h.images.sync([url]);
      h.images.sync(const []);
      expect(h.timers, hasLength(1));
      expect(h.delays.single, CoreRichEditorImage.deleteDelay);
      expect(h.deleted, isEmpty, reason: 'not before the delay');

      h.fireAll();
      await h.settle();
      expect(h.deleted, [url]);

      h.images.sync(const []);
      h.images.sync(const []);
      h.fireAll();
      await h.settle();
      expect(h.deleted, [url], reason: 'reported once');
    });

    test('an image that comes back in time is kept', () async {
      final h = _Harness();
      final url = (await h.images.submit(_file()))!;
      h.images.sync([url]);
      h.images.sync(const []);
      h.images.sync([url]); // undo, or the paste of a cut
      expect(h.timers.single.cancelled, isTrue);
      h.fireAll();
      await h.settle();
      expect(h.deleted, isEmpty);
    });

    test('the same image twice is deleted when the last copy goes', () async {
      final h = _Harness();
      final url = (await h.images.submit(_file()))!;
      // The document reports addresses, not how often: one copy left is
      // still the address.
      h.images.sync([url, url]);
      h.images.sync([url]);
      expect(h.timers, isEmpty);
      h.images.sync(const []);
      expect(h.timers, hasLength(1));
    });

    test('an image the editor did not upload is never deleted', () async {
      final h = _Harness();
      h.images.sync(['https://old.test/was-here.png']);
      h.images.sync(const []);
      expect(h.timers, isEmpty);
      await h.images.submit(_file());
      h.images.sync(const []);
      h.fireAll();
      await h.settle();
      expect(h.deleted, ['https://cdn.test/photo.png']);
    });

    test('an upload that never reached the document is deleted too', () async {
      final h = _Harness();
      final url = (await h.images.submit(_file()))!;
      h.images.sync(const []); // the platform could not place it
      h.fireAll();
      await h.settle();
      expect(h.deleted, [url]);
    });

    test('replacing the content from outside forgets the uploads', () async {
      final h = _Harness();
      final url = (await h.images.submit(_file()))!;
      h.images.sync([url]);
      h.images.sync(const []);
      expect(h.timers, hasLength(1));

      h.images.reset(); // controller.markdown = '' after the post was sent
      expect(h.timers.single.cancelled, isTrue);
      h.images.sync(const []);
      h.fireAll();
      await h.settle();
      expect(h.deleted, isEmpty);
    });

    test(
      'going away reports what was removed, not what is still there',
      () async {
        final h = _Harness();
        final kept = (await h.images.submit(_file(name: 'kept.png')))!;
        final gone = (await h.images.submit(_file(name: 'gone.png')))!;
        h.images.sync([kept, gone]);
        h.images.sync([kept]);

        h.images.dispose();
        await h.settle();
        expect(h.deleted, [gone]);
        expect(h.timers.single.cancelled, isTrue);
      },
    );

    test('a file that arrives after the editor went away is deleted', () async {
      final gate = Completer<String>();
      final h = _Harness(upload: (file) => gate.future);
      final result = h.images.submit(_file());
      h.images.dispose();
      gate.complete('https://cdn.test/late.png');
      expect(await result, isNull);
      await h.settle();
      expect(h.deleted, ['https://cdn.test/late.png']);
    });

    test('no delete handler means nothing is asked of the server', () async {
      final h = _Harness(withDelete: false);
      final url = (await h.images.submit(_file()))!;
      h.images.sync([url]);
      h.images.sync(const []);
      h.fireAll();
      h.images.dispose();
      await h.settle();
      expect(h.deleted, isEmpty);
    });

    test("a failing delete reaches the app's error handling", () async {
      final errors = <Object>[];
      await runZonedGuarded(() async {
        final images = CoreRichEditorImages(
          upload: (file) async => 'https://cdn.test/a.png',
          delete: (url) async => throw StateError('server down'),
        );
        await images.submit(_file());
        images.dispose();
        await Future<void>.delayed(Duration.zero);
      }, (error, stack) => errors.add(error));
      expect(errors.single, isA<StateError>());
    });

    test('nothing happens after dispose', () async {
      final h = _Harness();
      h.images.dispose();
      final changes = h.changes;
      h.images.reject('a.png', CoreRichEditorImageIssue.tooLarge);
      h.images.sync(const []);
      expect(h.images.pending, isEmpty);
      expect(h.changes, changes);
      expect(h.timers, isEmpty);
    });
  });
}
