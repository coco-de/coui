// Pins the accept-list semantics shared by the Flutter and Web FileInput.
//
// Both platforms ask the same question — "does this file satisfy `accept`?"
// — about files whose type they learned differently (Flutter: `XFile` name
// + optional MIME, Web: `File` name + `type`). If the two answered it
// differently, the same dropped file would pass on one platform and
// disappear on the other, so the rule lives here once and both call it.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreFileInputAccept.matches', () {
    test('an empty accept list admits everything', () {
      expect(
        CoreFileInputAccept.matches(fileName: 'anything', accept: const []),
        isTrue,
      );
    });

    test('matches an extension entry with the leading dot', () {
      expect(
        CoreFileInputAccept.matches(
          fileName: 'report.pdf',
          accept: const ['.pdf'],
        ),
        isTrue,
      );
      expect(
        CoreFileInputAccept.matches(
          fileName: 'report.txt',
          accept: const ['.pdf'],
        ),
        isFalse,
      );
    });

    test('matches case-insensitively on both sides', () {
      expect(
        CoreFileInputAccept.matches(
          fileName: 'REPORT.PDF',
          accept: const [' .Pdf '],
        ),
        isTrue,
      );
    });

    test('matches a bare extension entry (the HTML form without a dot)', () {
      expect(
        CoreFileInputAccept.matches(
          fileName: 'photo.png',
          accept: const ['png'],
        ),
        isTrue,
      );
    });

    test('matches an exact MIME type', () {
      expect(
        CoreFileInputAccept.matches(
          fileName: 'report',
          accept: const ['application/pdf'],
          mimeType: 'application/pdf',
        ),
        isTrue,
      );
      expect(
        CoreFileInputAccept.matches(
          fileName: 'report',
          accept: const ['application/pdf'],
          mimeType: 'text/plain',
        ),
        isFalse,
      );
    });

    test('matches a MIME wildcard', () {
      expect(
        CoreFileInputAccept.matches(
          fileName: 'photo',
          accept: const ['image/*'],
          mimeType: 'image/png',
        ),
        isTrue,
      );
      expect(
        CoreFileInputAccept.matches(
          fileName: 'clip',
          accept: const ['image/*'],
          mimeType: 'video/mp4',
        ),
        isFalse,
      );
      expect(
        CoreFileInputAccept.matches(
          fileName: 'clip',
          accept: const ['*/*'],
          mimeType: 'video/mp4',
        ),
        isTrue,
      );
    });

    test('falls back to the extension when a MIME entry has no MIME to '
        'compare', () {
      // A drop often arrives without a MIME type; rejecting on that alone
      // would silently discard a file the same list admits when picked.
      expect(
        CoreFileInputAccept.matches(
          fileName: 'photo.png',
          accept: const ['image/png'],
        ),
        isTrue,
      );
      expect(
        CoreFileInputAccept.matches(
          fileName: 'photo.jpg',
          accept: const ['image/png'],
        ),
        isFalse,
      );
    });

    test('a wildcard MIME entry cannot fall back to an extension', () {
      expect(
        CoreFileInputAccept.matches(
          fileName: 'photo.png',
          accept: const ['image/*'],
        ),
        isFalse,
      );
    });

    test('treats a leading dot as a hidden name, not an extension', () {
      expect(
        CoreFileInputAccept.matches(
          fileName: '.gitignore',
          accept: const ['.gitignore'],
        ),
        isFalse,
      );
      expect(
        CoreFileInputAccept.matches(
          fileName: '.gitignore',
          accept: const ['.gitignore'],
          mimeType: 'text/plain',
        ),
        isFalse,
      );
    });

    test('admits a file that satisfies any entry in the list', () {
      expect(
        CoreFileInputAccept.matches(
          fileName: 'photo.png',
          accept: const ['.pdf', 'image/*'],
          mimeType: 'image/png',
        ),
        isTrue,
      );
    });
  });

  group('CoreFileInputAccept.extensions', () {
    test('returns nothing for a null or empty list', () {
      expect(CoreFileInputAccept.extensions(null), isEmpty);
      expect(CoreFileInputAccept.extensions(const []), isEmpty);
    });

    test('normalises dotted, bare, and MIME entries to bare extensions', () {
      expect(
        CoreFileInputAccept.extensions(const [
          ' .PDF ',
          'image/png',
          'png',
          'image/*',
        ]),
        ['pdf', 'png', 'png'],
      );
    });
  });
}
