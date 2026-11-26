// Pins what a Web StepItem row renders, read off the DOM: the glyph each
// status draws and the colour it hands the icon, the title / trailing
// classes, the row's own height and padding, and the one-line title. The
// Flutter twin (`coui_flutter/test/components/layout/step_item_test.dart`)
// pins the same table on the rendered widgets.

import 'package:coui_web/coui_web.dart' hide css, events;
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Every rendered element with [tag], in document order.
List<DomComponent> _tags(String tag) => find
    .tag(tag)
    .evaluate()
    .map((element) => element.component as DomComponent)
    .toList();

/// The row's root `<div>` — the first one, before the composed gaps.
DomComponent _root() => _tags('div').first;

/// The title `<span>` and, when drawn, the trailing `<span>` — not the
/// inner `<span>` each `Text` renders, which only inherits from them.
List<DomComponent> _texts() =>
    _tags('span').where((el) => el.classes != 'text-inherit').toList();

Icon _icon() => find.byType(Icon).evaluate().single.component as Icon;

List<String> _classes(DomComponent element) =>
    (element.classes ?? '').split(' ');

String _ink(CoreColorToken token) =>
    'text-${CoreColor.token(token).tailwindColor}';

void main() {
  group('StepItem status', () {
    final expected =
        <
          CoreStepStatus,
          ({
            IconName glyph,
            CoreColorToken icon,
            CoreColorToken title,
            CoreColorToken note,
          })
        >{
          CoreStepStatus.done: (
            glyph: LucideIcons.circleCheck,
            icon: CoreColors.success,
            title: CoreColors.onSurface,
            note: CoreColors.onSurfaceSubtle,
          ),
          CoreStepStatus.current: (
            glyph: LucideIcons.circleDot,
            icon: CoreColors.primary,
            title: CoreColors.onSurface,
            note: CoreColors.onSurfaceSubtle,
          ),
          CoreStepStatus.todo: (
            glyph: LucideIcons.circle,
            icon: CoreColors.onSurfaceSubtle,
            title: CoreColors.onSurfaceVariant,
            note: CoreColors.onSurfaceSubtle,
          ),
          CoreStepStatus.failed: (
            glyph: LucideIcons.circleX,
            icon: CoreColors.error,
            title: CoreColors.onSurface,
            note: CoreColors.onErrorContainer,
          ),
        };

    for (final MapEntry(key: status, value: want) in expected.entries) {
      testComponents('${status.name} draws its glyph and colours', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          StepItem(title: 'Build', status: status, trailing: '12s'),
        );

        expect(_icon().icon, want.glyph);
        expect(_icon().iconStyle?.color, CoreColor.token(want.icon));
        expect(_icon().iconStyle?.size, 16);

        final [title, note] = _texts();
        expect(
          _classes(title),
          containsAll(['text-label-large', _ink(want.title)]),
        );
        expect(
          _classes(note),
          containsAll(['text-label-small', _ink(want.note)]),
        );
      });
    }
  });

  group('StepItem layout', () {
    testComponents('a full-width centred row, 32 high, 6 above and below', (
      tester,
    ) async {
      pumpWithTheme(tester, const StepItem(title: 'Build'));

      expect(
        _classes(_root()),
        containsAll(['flex', 'items-center', 'w-full']),
      );
      final styles = _root().styles?.properties ?? const {};
      expect(styles['min-height'], '2.0rem');
      expect(
        styles['padding'],
        '${spaceCss(CoreSpace.space6)} ${spaceCss(0)} '
        '${spaceCss(CoreSpace.space6)} ${spaceCss(0)}',
      );
    });

    testComponents('the title takes the space left on one line', (
      tester,
    ) async {
      pumpWithTheme(tester, const StepItem(title: 'Build', trailing: '12s'));

      final [title, note] = _texts();
      expect(_classes(title), containsAll(['flex-1', 'min-w-0', 'truncate']));
      expect(_classes(note), containsAll(['shrink-0', 'whitespace-nowrap']));
    });

    testComponents('glyph, gap, title — and the note only when stated', (
      tester,
    ) async {
      pumpWithTheme(tester, const StepItem(title: 'Build'));
      expect(_texts(), hasLength(1));
      expect(find.byType(Gap), findsNComponents(1));
    });

    testComponents('no physical left / right, so dir=rtl mirrors the row', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const StepItem(title: 'Build', trailing: '12s'),
      );

      // The title leads and the note ends the row by source order alone:
      // the browser flips a flex row under `dir="rtl"`, which only holds
      // while nothing in the row names a physical side.
      final physical = RegExp(
        r'(^|-)(ml|mr|pl|pr|l|r|left|right)(-|$)|row-reverse|text-(left|right)',
      );
      final physicalProperty = RegExp(r'(^|-)(left|right)(-|$)');
      for (final element in [_root(), ..._texts()]) {
        expect(
          _classes(element).where(physical.hasMatch),
          isEmpty,
          reason: '${element.classes}',
        );
        expect(
          (element.styles?.properties.keys ?? const <String>[]).where(
            physicalProperty.hasMatch,
          ),
          isEmpty,
          reason: '${element.styles?.properties}',
        );
      }
      final [title, note] = _texts();
      expect(_classes(title), contains('flex-1'));
      expect(_classes(note), contains('shrink-0'));
    });

    testComponents('a row on its own states no role', (tester) async {
      pumpWithTheme(tester, const StepItem(title: 'Build'));
      expect(_root().attributes?['role'], isNull);
    });
  });

  group('StepItem overrides', () {
    testComponents('a theme status row recolours that status only', (
      tester,
    ) async {
      const data = ThemeData(
        coreComponentTheme: CoreComponentTheme(
          stepItem: CoreStepItemTheme(
            statusStyles: {
              CoreStepStatus.failed: CoreStepItemStyle(
                iconStyle: CoreIconStyle(
                  color: CoreColor.token(CoreColors.warning),
                ),
              ),
            },
          ),
        ),
      );
      tester.pumpComponent(
        const Theme(
          data: data,
          child: StepItem(title: 'Deploy', status: CoreStepStatus.failed),
        ),
      );
      expect(
        _icon().iconStyle?.color,
        const CoreColor.token(CoreColors.warning),
      );
    });

    testComponents('a theme status row leaves the other statuses alone', (
      tester,
    ) async {
      const data = ThemeData(
        coreComponentTheme: CoreComponentTheme(
          stepItem: CoreStepItemTheme(
            statusStyles: {
              CoreStepStatus.failed: CoreStepItemStyle(
                iconStyle: CoreIconStyle(
                  color: CoreColor.token(CoreColors.warning),
                ),
              ),
            },
          ),
        ),
      );
      tester.pumpComponent(
        const Theme(
          data: data,
          child: StepItem(title: 'Deploy', status: CoreStepStatus.done),
        ),
      );
      expect(
        _icon().iconStyle?.color,
        const CoreColor.token(CoreColors.success),
      );
    });

    testComponents('withStyle patches a colour and keeps the role', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const StepItem(title: 'Build').withStyle(
          const CoreStepItemStyle(
            titleStyle: CoreTextStyle(
              color: CoreColor.token(CoreColors.error),
            ),
            minHeight: 40,
          ),
        ),
      );

      expect(
        _classes(_texts().single),
        containsAll(['text-label-large', _ink(CoreColors.error)]),
      );
      expect(_root().styles?.properties['min-height'], '2.5rem');
    });
  });
}
