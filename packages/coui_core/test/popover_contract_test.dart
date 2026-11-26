import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CorePopoverPlacement', () {
    test('has 12 canonical values', () {
      expect(CorePopoverPlacement.values.length, 12);
      expect(
        CorePopoverPlacement.values.map((v) => v.name).toSet(),
        {
          'top',
          'topStart',
          'topEnd',
          'bottom',
          'bottomStart',
          'bottomEnd',
          'left',
          'leftStart',
          'leftEnd',
          'right',
          'rightStart',
          'rightEnd',
        },
      );
    });

    group('flipY', () {
      test('maps top ↔ bottom on same alignment', () {
        expect(
          CorePopoverPlacement.top.flipY(),
          CorePopoverPlacement.bottom,
        );
        expect(
          CorePopoverPlacement.topStart.flipY(),
          CorePopoverPlacement.bottomStart,
        );
        expect(
          CorePopoverPlacement.topEnd.flipY(),
          CorePopoverPlacement.bottomEnd,
        );
        expect(
          CorePopoverPlacement.bottom.flipY(),
          CorePopoverPlacement.top,
        );
        expect(
          CorePopoverPlacement.bottomStart.flipY(),
          CorePopoverPlacement.topStart,
        );
        expect(
          CorePopoverPlacement.bottomEnd.flipY(),
          CorePopoverPlacement.topEnd,
        );
      });

      test('is identity for horizontal placements', () {
        for (final p in [
          CorePopoverPlacement.left,
          CorePopoverPlacement.leftStart,
          CorePopoverPlacement.leftEnd,
          CorePopoverPlacement.right,
          CorePopoverPlacement.rightStart,
          CorePopoverPlacement.rightEnd,
        ]) {
          expect(p.flipY(), p, reason: '$p.flipY() should be itself');
        }
      });

      test('is an involution on vertical placements', () {
        for (final p in [
          CorePopoverPlacement.top,
          CorePopoverPlacement.topStart,
          CorePopoverPlacement.topEnd,
          CorePopoverPlacement.bottom,
          CorePopoverPlacement.bottomStart,
          CorePopoverPlacement.bottomEnd,
        ]) {
          expect(p.flipY().flipY(), p);
        }
      });
    });

    group('flipX', () {
      test('maps left ↔ right on same alignment', () {
        expect(
          CorePopoverPlacement.left.flipX(),
          CorePopoverPlacement.right,
        );
        expect(
          CorePopoverPlacement.leftStart.flipX(),
          CorePopoverPlacement.rightStart,
        );
        expect(
          CorePopoverPlacement.leftEnd.flipX(),
          CorePopoverPlacement.rightEnd,
        );
        expect(
          CorePopoverPlacement.right.flipX(),
          CorePopoverPlacement.left,
        );
        expect(
          CorePopoverPlacement.rightStart.flipX(),
          CorePopoverPlacement.leftStart,
        );
        expect(
          CorePopoverPlacement.rightEnd.flipX(),
          CorePopoverPlacement.leftEnd,
        );
      });

      test('is identity for vertical placements', () {
        for (final p in [
          CorePopoverPlacement.top,
          CorePopoverPlacement.topStart,
          CorePopoverPlacement.topEnd,
          CorePopoverPlacement.bottom,
          CorePopoverPlacement.bottomStart,
          CorePopoverPlacement.bottomEnd,
        ]) {
          expect(p.flipX(), p, reason: '$p.flipX() should be itself');
        }
      });

      test('is an involution on horizontal placements', () {
        for (final p in [
          CorePopoverPlacement.left,
          CorePopoverPlacement.leftStart,
          CorePopoverPlacement.leftEnd,
          CorePopoverPlacement.right,
          CorePopoverPlacement.rightStart,
          CorePopoverPlacement.rightEnd,
        ]) {
          expect(p.flipX().flipX(), p);
        }
      });
    });

    group('axis predicates', () {
      test('isTop true only for top-family', () {
        for (final p in CorePopoverPlacement.values) {
          final expected = {
            CorePopoverPlacement.top,
            CorePopoverPlacement.topStart,
            CorePopoverPlacement.topEnd,
          }.contains(p);
          expect(p.isTop, expected);
        }
      });

      test('isBottom true only for bottom-family', () {
        for (final p in CorePopoverPlacement.values) {
          final expected = {
            CorePopoverPlacement.bottom,
            CorePopoverPlacement.bottomStart,
            CorePopoverPlacement.bottomEnd,
          }.contains(p);
          expect(p.isBottom, expected);
        }
      });

      test('isLeft true only for left-family', () {
        for (final p in CorePopoverPlacement.values) {
          final expected = {
            CorePopoverPlacement.left,
            CorePopoverPlacement.leftStart,
            CorePopoverPlacement.leftEnd,
          }.contains(p);
          expect(p.isLeft, expected);
        }
      });

      test('isRight true only for right-family', () {
        for (final p in CorePopoverPlacement.values) {
          final expected = {
            CorePopoverPlacement.right,
            CorePopoverPlacement.rightStart,
            CorePopoverPlacement.rightEnd,
          }.contains(p);
          expect(p.isRight, expected);
        }
      });

      test('exactly one axis predicate true per placement', () {
        for (final p in CorePopoverPlacement.values) {
          final count = [
            p.isTop,
            p.isBottom,
            p.isLeft,
            p.isRight,
          ].where((b) => b).length;
          expect(count, 1, reason: '$p should be on exactly one side');
        }
      });
    });
  });

  group('CorePopoverCollision', () {
    test('has 4 values', () {
      expect(CorePopoverCollision.values.length, 4);
    });
  });

  group('CorePopoverTrigger', () {
    test('has 4 values', () {
      expect(CorePopoverTrigger.values.length, 4);
    });
  });

  group('CorePopoverStyle — trigger-to-panel offset', () {
    test('a popover sits 4 off its trigger — the same as a Form popover', () {
      expect(CorePopoverStyle.defaultPlacementOffset, CoreSpace.space4);
      expect(CorePopoverStyle.defaultPlacementOffset, 4.0);
      expect(
        CorePopoverStyle.defaultPlacementOffset,
        CorePopoverStyle.defaultFormPopoverPlacementOffset,
      );
    });

    test('a composed popover that states no offset inherits the default', () {
      // DatePicker · ColorPicker · TimePicker · PhoneInput · Fab state no
      // `placementOffset` of their own, so they follow `Popover`; Select and
      // Autocomplete pin their own 4.
      expect(CoreDatePickerStyle.defaultPopoverStyle.placementOffset, isNull);
      expect(CoreColorPickerStyle.defaultPopoverStyle.placementOffset, isNull);
      expect(CoreTimePickerStyle.defaultPopoverStyle.placementOffset, isNull);
      expect(CorePhoneInputStyle.defaultPopoverStyle.placementOffset, isNull);
      expect(CoreFabStyle.defaultPopoverStyle.placementOffset, isNull);
      expect(CoreSelectStyle.defaultPopoverStyle.placementOffset, 4);
      expect(CoreAutocompleteStyle.defaultPopoverStyle.placementOffset, 4);
    });
  });

  group('CorePopoverStyle — Form popover defaults', () {
    test('defaultFormPopoverPlacementOffset is 4 (CoreSpace.space4)', () {
      expect(
        CorePopoverStyle.defaultFormPopoverPlacementOffset,
        CoreSpace.space4,
      );
      expect(CorePopoverStyle.defaultFormPopoverPlacementOffset, 4.0);
    });

    test('defaultViewportPadding is CoreEdgeInsets.all(CoreSpace.space8)', () {
      expect(
        CorePopoverStyle.defaultViewportPadding,
        const CoreEdgeInsets.all(CoreSpace.space8),
      );
    });

    test('defaultFormPopoverMaxHeight is 300', () {
      expect(CorePopoverStyle.defaultFormPopoverMaxHeight, 300);
    });

    test('defaultZIndex sources the shared CoreZIndex popover rung', () {
      expect(CorePopoverStyle.defaultZIndex, CoreZIndex.z60);
    });

    test('defaultCloseOnScroll is true', () {
      expect(CorePopoverStyle.defaultCloseOnScroll, isTrue);
    });

    test('defaultCollision is {flip, shift}', () {
      expect(
        CorePopoverStyle.defaultCollision,
        {CorePopoverCollision.flip, CorePopoverCollision.shift},
      );
    });

    test('defaultDropdownPlacement is bottomStart', () {
      expect(
        CorePopoverStyle.defaultDropdownPlacement,
        CorePopoverPlacement.bottomStart,
      );
    });
  });
}
