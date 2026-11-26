import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// A stand-in implementation — the contract is an interface, so this is what
/// the Flutter and Web `Drawer` each are once the platform types are removed.
class _FakeDrawer implements CoreDrawerContract<String> {
  const _FakeDrawer({
    this.fillSafeArea = CoreDrawerContract.defaultFillSafeArea,
  });

  @override
  final bool fillSafeArea;

  @override
  String get content => 'content';

  @override
  CoreDrawerSide get side => CoreDrawerSide.bottom;

  @override
  String? get title => null;

  @override
  String? get description => null;

  @override
  String? get footer => null;

  @override
  bool get showDragHandle => CoreDrawerContract.defaultShowDragHandle;

  @override
  bool get showCloseButton => CoreDrawerContract.defaultShowCloseButton;

  @override
  bool get barrierDismissible => true;

  @override
  bool get draggable => true;

  @override
  double get dragDismissThreshold =>
      CoreDrawerContract.defaultDragDismissThreshold;

  @override
  bool get rubberBand => CoreDrawerContract.defaultRubberBand;

  @override
  bool get dismissOnEscape => true;

  @override
  bool get transformBackdrop => true;

  @override
  CoreDrawerStyle? get drawerStyle => null;
}

void main() {
  group('CoreDrawerContract.fillSafeArea', () {
    test('is off by default, so no existing drawer changes', () {
      // Flutter's `Drawer` / `openDrawer` and Web's `Drawer` all reference
      // this one constant. Flipping it would move every drawer at once.
      expect(CoreDrawerContract.defaultFillSafeArea, isFalse);
    });

    test('is part of the contract every implementation reads through', () {
      const CoreDrawerContract<String> plain = _FakeDrawer();
      const CoreDrawerContract<String> filled = _FakeDrawer(fillSafeArea: true);

      expect(plain.fillSafeArea, isFalse);
      expect(filled.fillSafeArea, isTrue);
    });

    test('leaves the other shared defaults alone', () {
      expect(CoreDrawerContract.defaultDragDismissThreshold, 0.5);
      expect(CoreDrawerSide.defaultSide, CoreDrawerSide.left);
    });
  });

  group('CoreDrawerContract sheet parts', () {
    test('default to what a drawer drew before they existed', () {
      // No handle, and the header keeps its close button — flipping either
      // would change every drawer already on screen.
      expect(CoreDrawerContract.defaultShowDragHandle, isFalse);
      expect(CoreDrawerContract.defaultShowCloseButton, isTrue);
    });

    test('are part of the contract every implementation reads through', () {
      const CoreDrawerContract<String> drawer = _FakeDrawer();

      expect(drawer.description, isNull);
      expect(drawer.showDragHandle, isFalse);
      expect(drawer.showCloseButton, isTrue);
    });
  });

  group('CoreDrawerContract.rubberBand', () {
    test('is off by default, so no draggable drawer changes', () {
      // Flutter's `Drawer` / `openDrawer` and Web's `Drawer` all reference
      // this one constant. Flipping it would let every drawer stretch.
      expect(CoreDrawerContract.defaultRubberBand, isFalse);
    });

    test('is part of the contract every implementation reads through', () {
      const CoreDrawerContract<String> drawer = _FakeDrawer();

      expect(drawer.rubberBand, isFalse);
    });
  });

  group('CoreDrawerContract.dismissesOnRelease', () {
    test('dismisses once the drag covers the threshold share of the panel', () {
      expect(
        CoreDrawerContract.dismissesOnRelease(
          dragDistance: 150,
          panelExtent: 300,
          threshold: CoreDrawerContract.defaultDragDismissThreshold,
        ),
        isTrue,
        reason: 'exactly half of a 300 px sheet is the threshold itself',
      );
      expect(
        CoreDrawerContract.dismissesOnRelease(
          dragDistance: 149,
          panelExtent: 300,
          threshold: CoreDrawerContract.defaultDragDismissThreshold,
        ),
        isFalse,
      );
    });

    test('measures against the panel, not the screen it sits on', () {
      // The same 150 px drag that dismisses a 300 px sheet does not dismiss
      // an 800 px one — the share of the panel is what counts.
      expect(
        CoreDrawerContract.dismissesOnRelease(
          dragDistance: 150,
          panelExtent: 800,
          threshold: CoreDrawerContract.defaultDragDismissThreshold,
        ),
        isFalse,
      );
    });

    test('a drag back toward the docked edge never dismisses', () {
      expect(
        CoreDrawerContract.dismissesOnRelease(
          dragDistance: -200,
          panelExtent: 300,
          threshold: CoreDrawerContract.defaultDragDismissThreshold,
        ),
        isFalse,
      );
    });

    test('a panel with no extent has covered nothing', () {
      expect(
        CoreDrawerContract.dismissesOnRelease(
          dragDistance: 40,
          panelExtent: 0,
          threshold: CoreDrawerContract.defaultDragDismissThreshold,
        ),
        isFalse,
      );
      expect(
        CoreDrawerContract.dismissesOnRelease(
          dragDistance: 40,
          panelExtent: 0,
          threshold: 0,
        ),
        isTrue,
        reason: 'a zero threshold is met by any release',
      );
    });
  });
}
