import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreInputFocusModality', () {
    test('keyboard focus shows a focus ring', () {
      final modality = CoreInputFocusModality();
      expect(modality.focus(platformShowsRing: true), isTrue);
    });

    test('a pointer-originated focus does not show a ring', () {
      final modality = CoreInputFocusModality()..pointerDown();
      expect(modality.focus(platformShowsRing: true), isFalse);
    });

    test('a pointer press is consumed by the focus it caused', () {
      final modality = CoreInputFocusModality()..pointerDown();
      expect(modality.focus(platformShowsRing: true), isFalse);
      // The next focus is a new event and nobody pressed for it.
      expect(modality.focus(platformShowsRing: true), isTrue);
    });

    test(
      'a click on an already focused input does not hide later keyboard focus',
      () {
        final modality = CoreInputFocusModality();
        expect(modality.focus(platformShowsRing: true), isTrue);
        modality
          ..pointerDown()
          ..blur();
        expect(modality.focus(platformShowsRing: true), isTrue);
      },
    );

    test('the platform signal still decides whether a ring is appropriate', () {
      final modality = CoreInputFocusModality();
      expect(modality.focus(platformShowsRing: false), isFalse);
    });

    test('a pointer press wins over a platform that reports keyboard', () {
      // Browsers match `:focus-visible` on a text input for a mouse click,
      // and Flutter's highlight mode stays `traditional` under a mouse.
      final modality = CoreInputFocusModality()..pointerDown();
      expect(modality.focus(platformShowsRing: true), isFalse);
    });
  });
}
