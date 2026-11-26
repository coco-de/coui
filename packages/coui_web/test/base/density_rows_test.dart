// Which heights a density moves on Web — the same answer Flutter gives.
//
// A density moves a row of the control ladder: the height a component's size
// row states. A height the caller states is not a row of the ladder, so it
// stays as stated under any density — on Flutter the conversion applies the
// density to the size row only, and here only the size row goes out as the
// row variable a `[data-coui-density]` rule re-points.
import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/form/chip_input/chip_input_style.dart';
import 'package:coui_web/src/components/form/item_picker/item_picker_style.dart';
import 'package:coui_web/src/components/form/text_field/text_field_style.dart';
import 'package:coui_web/src/components/navigation/tabs/tab_pane_style.dart';
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

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

const _row40 = 'var(--coui-control-height-40)';
const _stated40 = '2.5rem';

void main() {
  group('the size row goes out as the row variable', () {
    testComponents('button', (tester) async {
      final r = resolveButton(
        _themedContext(tester),
        variant: .primary,
        size: .md,
        shape: .rectangle,
        expanded: false,
      );
      expect(r.root.className, contains('h-control40'));
      expect(r.root.inlineStyles?.properties['min-height'], isNull);
    });

    testComponents('menu item sm and lg rows', (tester) async {
      // `sm` is the default rung, so it is the row nobody names a size for.
      final sm = resolveMenuItem(_themedContext(tester), scopeClass: 'x');
      final lg = resolveMenuItem(
        _themedContext(tester),
        scopeClass: 'x',
        size: .lg,
      );
      expect(
        sm.root.inlineStyles?.properties['min-height'],
        'var(--coui-control-height-32)',
      );
      expect(
        lg.root.inlineStyles?.properties['min-height'],
        'var(--coui-control-height-48)',
      );
    });

    testComponents('command search input and item row', (tester) async {
      final r = resolveCommand(_themedContext(tester));
      expect(r.header.inlineStyles?.properties['height'], _row40);
      expect(r.itemEnabled.inlineStyles?.properties['min-height'], _row40);
    });
  });

  group('a row off the control ladder goes out as a length', () {
    // The md MenuItem row is 36 — between the sm and md rungs, so there is
    // no row variable for a density to re-point.
    testComponents('menu item md', (tester) async {
      final r = resolveMenuItem(
        _themedContext(tester),
        scopeClass: 'x',
        size: CoreMenuItemSize.md,
      );
      expect(r.root.inlineStyles?.properties['min-height'], '2.25rem');
    });
  });

  group("a caller's own height stays as stated", () {
    testComponents('button', (tester) async {
      final r = resolveButton(
        _themedContext(tester),
        variant: .primary,
        size: .md,
        shape: .rectangle,
        expanded: false,
        buttonStyle: const CoreButtonStyle(height: 40),
      );
      expect(r.root.inlineStyles?.properties['min-height'], _stated40);
      expect(r.root.className, isNot(contains('h-control')));
    });

    testComponents('menu item', (tester) async {
      final r = resolveMenuItem(
        _themedContext(tester),
        scopeClass: 'x',
        menuItemStyle: const CoreMenuItemStyle(minHeight: 40),
      );
      expect(r.root.inlineStyles?.properties['min-height'], _stated40);
    });

    testComponents('command search input and item row', (tester) async {
      final r = resolveCommand(
        _themedContext(tester),
        commandStyle: const CoreCommandStyle(
          searchInputHeight: 40,
          itemMinHeight: 40,
        ),
      );
      expect(r.header.inlineStyles?.properties['height'], _stated40);
      expect(r.itemEnabled.inlineStyles?.properties['min-height'], _stated40);
    });
  });

  group('a field with no Size axis goes out as the md row variable', () {
    // ChipInput's frame and ItemPicker's search sit beside an md text field
    // and state its rung, so a density moves all of them.
    testComponents('chip input', (tester) async {
      final r = resolveChipInput(_themedContext(tester), enabled: true);
      expect(r.root.inlineStyles?.properties['min-height'], _row40);
    });

    // The phone input sits on the lg row (the text field's default row since
    // #5831), so a density moves it from there.
    testComponents('phone input — the lg row', (tester) async {
      final r = resolvePhoneInput(
        _themedContext(tester),
        enabled: true,
        scopeId: 'x',
      );
      expect(
        r.root.inlineStyles?.properties['height'],
        controlHeightCss(CorePhoneInputStyle.defaultHeight),
      );
      expect(CorePhoneInputStyle.defaultHeight, CoreControlSize.heightLg);
    });

    testComponents('item picker search — the field draws its own md row', (
      tester,
    ) async {
      // No height is forwarded: the composed text field's own md row is the
      // search row, and the field already emits it as the row variable.
      final picker = resolveItemPicker(_themedContext(tester));
      expect(picker.searchFieldStyle.height, isNull);
      expect(picker.searchFieldStyle.minHeight, isNull);
      expect(
        CoreItemPickerStyle.defaultSearchHeight,
        CoreTextFieldStyle.defaultsBySize[CoreComponentSize.md]!.minHeight,
      );
      final field = resolveTextField(
        _themedContext(tester),
        size: .md,
        expands: false,
        hasError: false,
        enabled: true,
        scopeId: 'x',
        textFieldStyle: picker.searchFieldStyle,
      );
      expect(field.affixWrapper.inlineStyles?.properties['min-height'], _row40);
    });
  });

  group("a field's stated height stays as stated", () {
    testComponents('chip input', (tester) async {
      final r = resolveChipInput(
        _themedContext(tester),
        enabled: true,
        chipInputStyle: const CoreChipInputStyle(minHeight: 40),
      );
      expect(r.root.inlineStyles?.properties['min-height'], _stated40);
    });

    testComponents('phone input', (tester) async {
      final r = resolvePhoneInput(
        _themedContext(tester),
        enabled: true,
        scopeId: 'x',
        phoneInputStyle: const CorePhoneInputStyle(height: 40),
      );
      expect(r.root.inlineStyles?.properties['height'], _stated40);
    });

    testComponents('item picker search', (tester) async {
      final r = resolveItemPicker(
        _themedContext(tester),
        itemPickerStyle: const CoreItemPickerStyle(searchHeight: 44),
      );
      expect(r.searchFieldStyle.height, 44);
    });

    testComponents('item picker search still beats a height the field slot '
        'states', (tester) async {
      // The row is `searchHeight` on both platforms — Flutter's row box
      // holds the field whatever the slot says — so a slot height has to
      // lose to the row here too.
      final r = resolveItemPicker(
        _themedContext(tester),
        itemPickerStyle: const CoreItemPickerStyle(
          searchFieldStyle: CoreTextFieldStyle(height: 50),
        ),
      );
      expect(
        r.searchFieldStyle.height,
        CoreItemPickerStyle.defaultSearchHeight,
      );
    });
  });

  group('a row on its own ladder stays a length', () {
    testComponents('filter segment (the composed toggle group)', (
      tester,
    ) async {
      final r = resolveToggleGroup(_themedContext(tester), enabled: true);
      final height = r.itemUnselected.inlineStyles?.properties['height'];
      expect(height, '2.0rem');
      expect(height, isNot(contains('control-height')));
    });

    testComponents('tab pane bar', (tester) async {
      final r = resolveTabPane(
        _themedContext(tester),
        tabs: const [TabPaneTabState(focused: true, enabled: true)],
      );
      final height = r.bar.inlineStyles?.properties['height'];
      expect(height, '2.75rem');
      expect(height, isNot(contains('control-height')));
    });
  });
}
