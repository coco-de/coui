// The control corner is the control height × 0.25 on every size (디자이너
// 결정 2026-10-08), a Menu row takes the copy’s 8 on every size, and a
// Command row is the designer's 8 on every size and presentation. These pin
// what the Web resolvers emit — the Core test pins the table, this pins
// that the resolvers read it rather than a size-independent constant.

import 'package:coui_web/coui_web.dart';
// Resolver-level assertions — the style files are not on the barrel.
import 'package:coui_web/src/components/form/item_picker/item_picker_style.dart';
import 'package:coui_web/src/components/form/text_area/text_area_style.dart';
import 'package:coui_web/src/components/form/text_field/text_field_style.dart';
import 'package:coui_web/src/components/menu/menu/menu_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

/// The height each size aligns to — from the contract, not from a style row.
const Map<CoreComponentSize, double> _kHeight = {
  CoreComponentSize.xs: CoreControlSize.heightXs,
  CoreComponentSize.sm: CoreControlSize.heightSm,
  CoreComponentSize.md: CoreControlSize.heightMd,
  CoreComponentSize.lg: CoreControlSize.heightLg,
  CoreComponentSize.xl: CoreControlSize.heightXl,
  CoreComponentSize.xl2: CoreControlSize.heightXl2,
};

/// The control corner for [size] — its height × 0.25.
int _corner(CoreComponentSize size) => (_kHeight[size]! * 0.25).toInt();

/// A row a `Select` hosts — 6 whatever the panel's size (concentric with the
/// 12 panel and its 6 inset).
const int _kHostedRow = 6;

/// A `Command` row — 8 in every presentation and size, the designer's list-row
/// decision. Not the hosted 6: a little rounder than the concentric corner.
const int _kCommandRow = 8;

/// The four-corner shorthand `CoreBorderRadius.toValue()` emits.
String _all(int n) => List.filled(4, 'var(--coui-radius-$n)').join(' ');

/// The rung a uniform `var(--coui-radius-N)` shorthand names.
int _rung(String? css) {
  final rungs = RegExp(
    r'var\(--coui-radius-(\d+)\)',
  ).allMatches(css!).map((m) => int.parse(m.group(1)!)).toSet();
  expect(rungs, hasLength(1), reason: '$css is not one corner');
  return rungs.single;
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

ResolvedTextField _field(
  BuildContext context,
  CoreComponentSize size, {
  CoreTextFieldStyle? style,
}) => resolveTextField(
  context,
  size: size,
  expands: false,
  hasError: false,
  enabled: true,
  scopeId: 'field',
  textFieldStyle: style,
);

ResolvedTextArea _area(
  BuildContext context,
  CoreComponentSize size, {
  CoreTextAreaStyle? style,
}) => resolveTextArea(
  context,
  size: size,
  expandableHeight: false,
  expandableWidth: false,
  hasError: false,
  obscureText: false,
  obscuringCharacter: '•',
  textAreaStyle: style,
);

String? _menuItemRadius(
  BuildContext context, {
  required CoreMenuItemSize size,
  CoreMenuItemStyle? style,
}) => resolveMenuItem(
  context,
  scopeClass: 'row',
  size: size,
  menuItemStyle: style,
).root.inlineStyles?.properties['border-radius'];

void main() {
  group('TextField (Web)', () {
    testComponents('every size emits its height × 0.25', (tester) async {
      final context = _themedContext(tester);
      for (final size in CoreComponentSize.values) {
        final field = _field(context, size);
        expect(
          field.input.inlineStyles!.properties['border-radius'],
          _all(_corner(size)),
          reason: '$size',
        );
        expect(
          field.affixWrapper.inlineStyles!.properties['border-radius'],
          _all(_corner(size)),
          reason: '$size — framed, the wrapper is the box',
        );
      }
    });

    testComponents('affordances are no rounder than the field', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final size in CoreComponentSize.values) {
        final field = _field(context, size);
        // The affordance is a size-less (`md`) plain Button — resolved the
        // way `TextField` composes it.
        final button = resolveButton(
          context,
          variant: CoreButtonVariant.plain,
          size: CoreComponentSize.md,
          shape: CoreButtonShape.rectangle,
          expanded: false,
          buttonStyle: field.featureButtonStyle,
        );
        expect(
          _rung(button.root.inlineStyles!.properties['border-radius']),
          lessThanOrEqualTo(
            _rung(field.input.inlineStyles!.properties['border-radius']),
          ),
          reason: '$size',
        );
      }
    });

    testComponents('a caller override still wins over the size row', (
      tester,
    ) async {
      final context = _themedContext(tester);
      expect(
        _field(
          context,
          CoreComponentSize.xl,
          style: const CoreTextFieldStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
          ),
        ).input.inlineStyles!.properties['border-radius'],
        _all(4),
      );
    });
  });

  group('TextArea (Web)', () {
    testComponents('every size takes the TextField corner of that size', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final size in CoreComponentSize.values) {
        final area = _area(context, size);
        expect(
          area.textarea.inlineStyles!.properties['border-radius'],
          _all(_corner(size)),
          reason: '$size',
        );
        expect(
          area.focusOutlineStyle.borderRadius,
          CoreBorderRadius.all(_corner(size).toDouble()),
          reason: '$size — the ring is handed the box corner',
        );
      }
    });

    testComponents('a caller override still wins over the size row', (
      tester,
    ) async {
      final context = _themedContext(tester);
      expect(
        _area(
          context,
          CoreComponentSize.xl,
          style: const CoreTextAreaStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
          ),
        ).textarea.inlineStyles!.properties['border-radius'],
        _all(4),
      );
    });
  });

  group('MenuItem (Web)', () {
    testComponents('a standalone row emits its own corner — 8 · 8 · 12', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const corners = {
        CoreMenuItemSize.sm: 8,
        CoreMenuItemSize.md: 8,
        CoreMenuItemSize.lg: 12,
      };
      for (final size in CoreMenuItemSize.values) {
        expect(
          _menuItemRadius(context, size: size),
          _all(corners[size]!),
          reason: '$size',
        );
      }
    });

    testComponents('a row a Menu hosts is the copy’s 8 on every size', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final size in CoreMenuItemSize.values) {
        for (final vertical in [true, false]) {
          final menu = resolveMenu(context, vertical: vertical, size: size);
          expect(
            _menuItemRadius(context, size: size, style: menu.itemStyle),
            _all(8),
            reason: '$size, vertical: $vertical',
          );
        }
      }
    });

    testComponents('a caller override still wins over the size row', (
      tester,
    ) async {
      final context = _themedContext(tester);
      expect(
        _menuItemRadius(
          context,
          size: CoreMenuItemSize.lg,
          style: const CoreMenuItemStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
          ),
        ),
        _all(4),
      );
    });
  });

  group('Select (Web)', () {
    testComponents('options are 6 on every size', (tester) async {
      final context = _themedContext(tester);
      for (final size in CoreSelectSize.values) {
        final select = resolveSelect(context, size: size);
        expect(
          _menuItemRadius(
            context,
            size: size.toMenuItemSize(),
            style: select.optionStyle,
          ),
          _all(_kHostedRow),
          reason: '$size',
        );
      }
    });
  });

  group('ItemPicker (Web)', () {
    testComponents('the search field is the bare variant and states no '
        'corner of its own', (tester) async {
      final picker = resolveItemPicker(_themedContext(tester));
      expect(picker.searchFieldStyle.borderRadius, isNull);
    });

    testComponents(
      'a caller search-field height cannot beat the row height — the '
      'Flutter twin sizes the row with searchHeight',
      (tester) async {
        final picker = resolveItemPicker(
          _themedContext(tester),
          itemPickerStyle: const CoreItemPickerStyle(
            searchFieldStyle: CoreTextFieldStyle(
              height: CoreSize.size64,
              borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
            ),
          ),
        );
        expect(
          picker.searchFieldStyle.height,
          CoreItemPickerStyle.defaultSearchHeight,
        );
        expect(
          picker.searchFieldStyle.borderRadius,
          const CoreBorderRadius.all(CoreRadius.radius4),
          reason: 'the rest of the caller slot still wins over the default',
        );
      },
    );
  });

  group('Command (Web)', () {
    testComponents('inline and dialog lists inset their rows 8', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final presentation in [
        CoreCommandPresentation.inline,
        CoreCommandPresentation.dialog,
      ]) {
        final command = resolveCommand(context, presentation: presentation);
        expect(
          command.list.inlineStyles!.properties['padding'],
          const CoreEdgeInsets.all(CoreSpace.space8).toValue(),
          reason: '$presentation',
        );
      }
    });

    testComponents(
      'the shortcut and the footer hint are the bodyXs role, the heading is '
      "labelXs at the role's own weight (Medium 500)",
      (tester) async {
        final context = _themedContext(tester);
        final command = resolveCommand(context);
        expect(command.shortcut.className, contains('body-xs'));
        expect(command.shortcut.className, isNot(contains('mono')));
        expect(command.footerLabel.className, contains('text-body-xs'));
        expect(command.heading.className, contains('label-xs'));
        // Core's heading default names the role only, so the weight is the
        // role's: the `text-label-xs` class reads
        // `--coui-text-label-xs-weight` and nothing is inlined over it.
        expect(CoreCommandStyle.defaultHeadingStyle.fontWeight, isNull);
        expect(command.heading.inlineStyles?.properties['font-weight'], isNull);
        expect(
          command.heading.inlineStyles?.properties['letter-spacing'],
          isNull,
        );
        expect(CoreTypography.coui.labelXs.fontWeight, CoreFontWeight.medium);
        expect(
          ThemeConfig.defaults().cssVariables,
          contains('--coui-text-label-xs-weight:${CoreFontWeight.medium};'),
        );
      },
    );

    testComponents(
      'rows are 8 in every presentation and size, not the hosted 6',
      (
        tester,
      ) async {
        final context = _themedContext(tester);
        for (final presentation in CoreCommandPresentation.values) {
          for (final size in CoreCommandSize.values) {
            final command = resolveCommand(
              context,
              presentation: presentation,
              size: size,
            );
            for (final row in [
              command.itemEnabled,
              command.itemActive,
              command.itemDisabled,
            ]) {
              expect(
                row.inlineStyles!.properties['border-radius'],
                _all(_kCommandRow),
                reason: '$presentation $size',
              );
            }
          }
        }
      },
    );
  });
}
