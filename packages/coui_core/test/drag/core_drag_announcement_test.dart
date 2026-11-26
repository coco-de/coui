import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _bin = CoreDragId('bin');
const _tray = CoreDragId('tray');

void main() {
  group('CoreDragAnnouncements.overChanged', () {
    test('entering a target speaks', () {
      expect(
        CoreDragAnnouncements.overChanged(from: null, to: _bin),
        CoreDragAnnouncement.enteredTarget,
      );
      expect(
        CoreDragAnnouncements.overChanged(from: _bin, to: _tray),
        CoreDragAnnouncement.enteredTarget,
      );
    });

    test('leaving a target stays silent', () {
      // The next entry says where the drag is; "left the bin" is not
      // actionable, and announcing it doubles every move between zones.
      expect(CoreDragAnnouncements.overChanged(from: _bin, to: null), isNull);
    });

    test('re-resolving the same target stays silent', () {
      expect(CoreDragAnnouncements.overChanged(from: _bin, to: _bin), isNull);
    });

    test('nothing over nothing stays silent', () {
      expect(CoreDragAnnouncements.overChanged(from: null, to: null), isNull);
    });
  });
}
