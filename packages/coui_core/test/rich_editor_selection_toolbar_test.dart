// The toolbar a `RichEditor` floats over selected text — what both platforms
// read from Core: its buttons, the rule that says when it shows, and its
// panel and distance defaults.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('selection toolbar buttons', () {
    test('the default toolbar without the image button', () {
      expect(CoreRichEditorFormat.selectionToolbar, const [
        [CoreRichEditorFormat.blockType],
        [
          CoreRichEditorFormat.bold,
          CoreRichEditorFormat.italic,
          CoreRichEditorFormat.strikethrough,
          CoreRichEditorFormat.code,
          CoreRichEditorFormat.link,
        ],
        [
          CoreRichEditorFormat.bulletedList,
          CoreRichEditorFormat.numberedList,
          CoreRichEditorFormat.taskList,
        ],
        [CoreRichEditorFormat.quote],
      ]);
      // Exactly what the toolbar in the box shows while the editor takes no
      // images — the two are one set of buttons.
      expect(
        CoreRichEditorFormat.selectionToolbar,
        CoreRichEditorFormat.visibleToolbar(
          CoreRichEditorFormat.defaultToolbar,
          images: false,
        ),
      );
      expect(
        CoreRichEditorFormat.selectionToolbar.expand((group) => group),
        isNot(contains(CoreRichEditorFormat.image)),
      );
    });
  });

  group('when the selection toolbar shows', () {
    bool shows({
      bool showSelectionToolbar = true,
      bool enabled = true,
      bool readOnly = false,
      bool hasSelectedText = true,
      bool selecting = false,
      bool dismissed = false,
      bool focused = true,
    }) => CoreRichEditorContract.showsSelectionToolbar(
      showSelectionToolbar: showSelectionToolbar,
      enabled: enabled,
      readOnly: readOnly,
      hasSelectedText: hasSelectedText,
      selecting: selecting,
      dismissed: dismissed,
      focused: focused,
    );

    test('on by default', () {
      expect(CoreRichEditorContract.defaultShowSelectionToolbar, isTrue);
    });

    test('over selected text in a focused editor that takes input', () {
      expect(shows(), isTrue);
    });

    test('never when the editor was told not to', () {
      expect(shows(showSelectionToolbar: false), isFalse);
    });

    test('never in a disabled or a read-only editor', () {
      expect(shows(enabled: false), isFalse);
      expect(shows(readOnly: true), isFalse);
    });

    test('not over a caret', () {
      expect(shows(hasSelectedText: false), isFalse);
    });

    test('not while the pointer that selects is still down', () {
      expect(shows(selecting: true), isFalse);
    });

    test('not on the selection Escape closed it on', () {
      expect(shows(dismissed: true), isFalse);
    });

    test('not once the focus has left the editor', () {
      expect(shows(focused: false), isFalse);
    });
  });

  group('selection toolbar folding — too narrow for its buttons', () {
    test('folds the quote, then the lists, then the inline formats from the '
        'link back; the block-type menu never', () {
      expect(CoreRichEditorFormat.selectionToolbarFoldOrder, const [
        [CoreRichEditorFormat.quote],
        [
          CoreRichEditorFormat.bulletedList,
          CoreRichEditorFormat.numberedList,
          CoreRichEditorFormat.taskList,
        ],
        [CoreRichEditorFormat.link],
        [CoreRichEditorFormat.code],
        [CoreRichEditorFormat.strikethrough],
        [CoreRichEditorFormat.italic],
        [CoreRichEditorFormat.bold],
      ]);
      // Every button but the block-type menu folds, each exactly once.
      final units = CoreRichEditorFormat.selectionToolbarFoldOrder
          .expand((unit) => unit)
          .toList();
      final buttons = CoreRichEditorFormat.selectionToolbar
          .expand((group) => group)
          .where((format) => format != CoreRichEditorFormat.blockType)
          .toList();
      expect(units..sort((a, b) => a.index - b.index), buttons);
      expect(units.toSet(), hasLength(units.length));
    });

    test('the folded formats read in toolbar order', () {
      expect(CoreRichEditorFormat.selectionToolbarFolded(0), isEmpty);
      expect(CoreRichEditorFormat.selectionToolbarFolded(1), const [
        CoreRichEditorFormat.quote,
      ]);
      expect(CoreRichEditorFormat.selectionToolbarFolded(3), const [
        CoreRichEditorFormat.link,
        CoreRichEditorFormat.bulletedList,
        CoreRichEditorFormat.numberedList,
        CoreRichEditorFormat.taskList,
        CoreRichEditorFormat.quote,
      ]);
      expect(
        CoreRichEditorFormat.selectionToolbarFolded(7),
        CoreRichEditorFormat.selectionToolbar
            .expand((group) => group)
            .where((format) => format != CoreRichEditorFormat.blockType),
      );
    });

    int steps(double available, {List<double> units = const [50, 100, 34]}) =>
        CoreRichEditorContract.selectionToolbarFoldSteps(
          available: available,
          pinnedWidth: 80,
          moreWidth: 50,
          unitWidths: units,
        );

    test('nothing folds while everything fits, or into an unbounded width', () {
      expect(steps(264), 0);
      expect(steps(1000), 0);
      expect(steps(double.infinity), 0);
    });

    test('folds the fewest units that make room for the more button too', () {
      // 80 + 50 + 100 + 34 = 264 does not fit; folding the first (50) leaves
      // 80 + 100 + 34 + the 50 more button = 264 — still not — so the lists
      // go too: 80 + 34 + 50 = 164.
      expect(steps(263), 2);
      expect(steps(164), 2);
      expect(steps(163), 3);
    });

    test('everything folds when even the more button alone does not fit', () {
      expect(steps(10), 3);
    });
  });

  group('selection toolbar keyboard delay', () {
    test(
      'is the moderate motion alias, a behaviour shared by both platforms',
      () {
        expect(
          CoreRichEditorContract.selectionToolbarKeyboardDelay,
          const Duration(milliseconds: CoreDuration.moderate),
        );
      },
    );
  });

  group('selection toolbar style', () {
    test('the panel states a 10 corner and a 4 inset with 12 at the start', () {
      const panel = CoreRichEditorStyle.defaultSelectionToolbarPanelStyle;
      expect(
        panel.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius10),
      );
      final padding = panel.padding!;
      expect(padding.isDirectional, isTrue);
      expect(padding.start, CoreSpace.space12);
      expect(padding.end, CoreSpace.space4);
      expect(padding.top, CoreSpace.space4);
      expect(padding.bottom, CoreSpace.space4);
      // The 12 is the one the toolbar in the box opens with.
      expect(padding.start, CoreRichEditorStyle.defaultToolbarPadding.start);
      // Nothing else: the fill, the line and the cast are the `Popup`'s own.
      expect(panel.backgroundColor, isNull);
      expect(panel.borderColor, isNull);
      expect(panel.borderWidth, isNull);
      expect(panel.boxShadow, isNull);
      expect(
        CorePopupStyle.defaultBackgroundColor,
        const CoreColor.token(CoreColors.surfaceBright),
      );
      expect(
        CorePopupStyle.defaultBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(CorePopupStyle.defaultBorderWidth, CoreStrokeWidth.stroke1);
      expect(CorePopupStyle.defaultBoxShadow, CoreShadow.lg);
    });

    test('it sits 8 from the selection', () {
      expect(
        CoreRichEditorStyle.defaultSelectionToolbarOffset,
        CoreSpace.space8,
      );
    });

    test('the two fields merge and take part in equality', () {
      const panel = CorePopupStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
      );
      const a = CoreRichEditorStyle(selectionToolbarPanelStyle: panel);
      const b = CoreRichEditorStyle(selectionToolbarOffset: CoreSpace.space16);
      final merged = a.merge(b);
      expect(merged.selectionToolbarPanelStyle, panel);
      expect(merged.selectionToolbarOffset, CoreSpace.space16);
      expect(a, isNot(const CoreRichEditorStyle()));
      expect(b, isNot(const CoreRichEditorStyle()));
      expect(a.hashCode, isNot(const CoreRichEditorStyle().hashCode));
      expect(b.hashCode, isNot(const CoreRichEditorStyle().hashCode));
      // A panel that states one thing keeps the default's other when the
      // default is merged under it.
      final resolved = CoreRichEditorStyle.defaultSelectionToolbarPanelStyle
          .merge(panel);
      expect(resolved.borderRadius, panel.borderRadius);
      expect(
        resolved.padding,
        CoreRichEditorStyle.defaultSelectionToolbarPanelStyle.padding,
      );
    });
  });
}
