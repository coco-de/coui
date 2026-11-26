import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/form/select/select.dart';
import 'package:coui_web/src/components/form/select/select_style.dart';
import 'package:coui_web/src/components/form/text_field/text_field_style.dart';
import 'package:coui_web/src/components/overlay/popover/popover.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const List<CoreSelectItem<String>> _kItems = [
  CoreSelectItem(value: 'apple', label: 'Apple'),
  CoreSelectItem(value: 'banana', label: 'Banana'),
];

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

/// The class list as a set of whole classes, so `border-outline` and
/// `border-outline-variant` stay distinguishable.
Set<String> _classesOf(String? classes) =>
    (classes ?? '').split(RegExp(r'\s+')).where((c) => c.isNotEmpty).toSet();

DomComponent _input() =>
    find.tag('input').evaluate().single.component as DomComponent;

/// The field chrome the select hands its trigger, painted by the field's
/// own resolver — the composition the widget performs, read as data.
ResolvedTextField _trigger(
  BuildContext context, {
  required bool hasError,
  required bool enabled,
}) {
  final select = resolveSelect(
    context,
    variant: hasError
        ? CoreSelectVariant.error
        : CoreSelectVariant.defaultVariant,
  );
  return resolveTextField(
    context,
    scopeId: 'tf',
    size: CoreComponentSize.md,
    expands: false,
    hasError: hasError,
    enabled: enabled,
    variant: hasError
        ? CoreTextFieldVariant.error
        : CoreTextFieldVariant.defaultVariant,
    textFieldStyle: select.triggerStyle,
  );
}

/// The framed box — the affix wrapper that draws the field's fill and
/// boundary and answers a press the `<input>` does not cover.
DomComponent _box() => find
    .tag('div')
    .evaluate()
    .map((e) => e.component)
    .whereType<DomComponent>()
    .singleWhere(
      (e) =>
          _classesOf(e.classes).containsAll(['flex', 'border']) &&
          _classesOf(e.classes).any((c) => c.startsWith('bg-')),
    );

/// A press on the box beside the `<input>` — the padding, the chevron, a
/// custom suffix. Null when the box answers none (a disabled field).
void Function(Object)? _boxClick() =>
    _box().events?['click'] as void Function(Object)?;

void main() {
  group('Select', () {
    for (final value in [true, false]) {
      testComponents('forwards closeOnScroll $value', (tester) {
        final select = const Select<String>(
          items: _kItems,
        ).copyWith(closeOnScroll: value);
        pumpWithTheme(tester, select);
        final popover =
            find.byType(Popover).evaluate().single.component as Popover;
        expect(popover.closeOnScroll, value);
        expect(popover.copyWith().closeOnScroll, value);
      });
    }
    test('default Select and Popover scroll policies remain explicit', () {
      expect(const Select<String>(items: _kItems).closeOnScroll, isTrue);
      expect(
        const Popover(
          trigger: Component.text('A'),
          content: Component.text('B'),
        ).closeOnScroll,
        isFalse,
      );
    });
    testComponents(
      'panel width policy is forwarded without changing the default',
      (
        tester,
      ) {
        const original = Select<String>(items: _kItems);
        expect(
          original.popoverWidthConstraint,
          CorePopoverConstraint.anchorFixedSize,
        );
        final expanded = original
            .copyWith(
              popoverWidthConstraint: CorePopoverConstraint.anchorMinSize,
            )
            .withStyle(const CoreSelectStyle());
        expect(
          expanded.popoverWidthConstraint,
          CorePopoverConstraint.anchorMinSize,
        );
        pumpWithTheme(tester, expanded);
        final popover =
            find.byType(Popover).evaluate().single.component as Popover;
        expect(popover.widthConstraint, CorePopoverConstraint.anchorMinSize);
        expect(_input().attributes?['role'], 'combobox');
        expect(_input().attributes?['aria-expanded'], 'false');
      },
    );
    testComponents(
      'custom suffix retains combobox semantics and readonly trigger',
      (tester) async {
        pumpWithTheme(
          tester,
          const Select<String>(
            items: _kItems,
            value: 'apple',
            suffix: Component.text('Change'),
          ).withStyle(const CoreSelectStyle()),
        );
        expect(find.text('Change'), findsOneComponent);
        expect(_input().attributes?['role'], 'combobox');
        expect(_input().attributes?['aria-expanded'], 'false');
        expect(_input().attributes?['readonly'], isNotNull);
        expect(_input().attributes?['value'], 'Apple');
        _boxClick()!(Object());
        await tester.pump();
        expect(_input().attributes?['aria-expanded'], 'true');
      },
    );
    testComponents('custom suffix preserves disabled trigger semantics', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Select<String>(
          items: _kItems,
          suffix: Component.text('Change'),
          enabled: false,
        ),
      );
      expect(find.text('Change'), findsOneComponent);
      expect(_input().attributes?['disabled'], isNotNull);
      expect(_boxClick(), isNull);
      await tester.pump();
      expect(_input().attributes?['aria-expanded'], 'false');
    });

    // The trigger is a `TextField`, so the placeholder and the selected
    // label live on the `<input>` — an attribute and a value, not text
    // nodes. That is the point of the change: a select reads as a field,
    // and a field's content is its input's.
    testComponents('the placeholder rides on the trigger input', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Select<String>(items: _kItems, placeholder: 'Pick a fruit'),
      );

      expect(find.tag('input'), findsOneComponent);
      expect(_input().attributes?['placeholder'], 'Pick a fruit');
    });

    // The select is a field, so its scope and trigger wrapper fill the
    // parent. Left at `inline-block` / `inline-flex` they shrink to the
    // `<input>`'s own default width, and a wider parent never reaches the
    // field.
    testComponents('the scope and the trigger wrapper fill the parent', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Select<String>(items: _kItems, placeholder: 'Pick'),
      );

      final divs = find
          .tag('div')
          .evaluate()
          .map((e) => e.component as DomComponent)
          .toList();
      final scope = divs.singleWhere(
        (d) => _classesOf(d.classes).contains('relative'),
      );
      final trigger = divs.singleWhere(
        (d) => (d.id ?? '').startsWith('co-popover-trigger'),
      );

      expect(_classesOf(scope.classes), containsAll(['relative', 'w-full']));
      expect(_classesOf(scope.classes), isNot(contains('inline-block')));
      expect(_classesOf(trigger.classes), containsAll(['flex', 'w-full']));
      expect(_classesOf(trigger.classes), isNot(contains('inline-flex')));
    });

    testComponents('the trigger states combobox, its listbox and that it '
        'does not filter', (tester) async {
      pumpWithTheme(
        tester,
        const Select<String>(items: _kItems, value: 'banana', label: 'Fruit'),
      );

      final attrs = _input().attributes!;
      expect(attrs['role'], 'combobox');
      expect(attrs['aria-haspopup'], 'listbox');
      expect(attrs['aria-autocomplete'], 'none');
      expect(attrs['aria-expanded'], 'false');
      expect(attrs['aria-controls'], endsWith('-listbox'));
      expect(attrs.containsKey('aria-activedescendant'), isFalse);
    });

    testComponents('hover is a border step on the trigger, and error '
        'outranks it', (tester) async {
      pumpWithTheme(
        tester,
        const Select<String>(items: _kItems, placeholder: 'Pick'),
      );
      // Whole-class comparison: `border-outline` is a prefix of
      // `border-outline-variant`, so a substring check cannot tell the
      // control edge from the hairline tone. The box is the wrapper, and it
      // takes focus through `focus-within:`, so its hover step leaves a
      // focused field alone.
      const hover = '[&:hover:not(:focus-within)]:border-outline';
      expect(_classesOf(_box().classes), contains(hover));
      expect(_classesOf(_box().classes), contains('border-outline-variant'));
      expect(_classesOf(_box().classes), isNot(contains('border-outline')));

      pumpWithTheme(
        tester,
        const Select<String>(
          items: _kItems,
          placeholder: 'Pick',
          errorText: 'Required',
        ),
      );
      expect(_classesOf(_box().classes), contains('border-error'));
      expect(
        _classesOf(_box().classes),
        contains('[&:hover:not(:focus-within)]:border-error'),
      );
      expect(_classesOf(_box().classes), isNot(contains(hover)));
    });

    testComponents('disabled outranks error — the disabled trio is stated '
        'and the pointer is kept off', (tester) async {
      pumpWithTheme(
        tester,
        const Select<String>(
          items: _kItems,
          placeholder: 'Pick',
          errorText: 'Required',
          enabled: false,
        ),
      );
      final classes = _input().classes!;
      // A `<div>` has no `:disabled`, so the box states the disabled edge at
      // build time; the input keeps the pointer off.
      expect(_classesOf(_box().classes), contains('border-disabled-outline'));
      expect(classes, contains('disabled:pointer-events-none'));
      expect(_input().attributes?['disabled'], isNotNull);
      // The box is what the disabled fill covers; the `<input>` inside it
      // paints none, so the fill is one even rectangle and not a strip
      // across the input's rows.
      expect(
        _classesOf(classes),
        isNot(contains('disabled:bg-disabled-container')),
      );
      expect(_classesOf(classes), contains('bg-transparent'));
      expect(_classesOf(_box().classes), contains('bg-disabled-container'));
    });

    testComponents('a disabled select hands the placeholder and value to the '
        "field's disabled tone (#5747)", (tester) async {
      pumpWithTheme(
        tester,
        const Select<String>(
          items: _kItems,
          placeholder: 'Pick',
          enabled: false,
        ),
      );
      final classes = _classesOf(_input().classes);
      expect(classes, contains('disabled:placeholder:text-disabled-content'));
      expect(classes, contains('disabled:text-disabled-content'));

      final context = _themedContext(tester);
      final disabled = resolveSelect(context, enabled: false);
      expect(disabled.triggerStyle.placeholderStyle?.color, isNull);
      expect(disabled.triggerStyle.valueStyle?.color, isNull);
      expect(disabled.chevronIconStyle.color, isNull);
      final enabled = resolveSelect(context);
      expect(
        enabled.chevronIconStyle.color,
        CoreSelectStyle.defaultPlaceholderColor,
      );
    });

    testComponents('the wash is pressed-only — no hover or focus rule', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final trigger = resolveSelect(context).triggerStyle;
      final css = resolveTextFieldRules(
        context,
        scopeId: 'tf',
        stateLayerId: 'sel',
        hasError: false,
        enabled: true,
        textFieldStyle: trigger,
      ).css;
      expect(css, contains('#sel:active{background-color:'));
      expect(css, contains('12%'));
      expect(css, isNot(contains(':hover')));
      expect(css, isNot(contains(':focus-within')));
    });

    testComponents('by default the trigger adds no active boundary — focus '
        'and error speak in colour at the resting 1 (#5747)', (tester) async {
      final context = _themedContext(tester);
      List<String> markers(String? classes) => _classesOf(
        classes,
      ).where((c) => c.startsWith('coui-active-boundary')).toList();

      for (final hasError in [false, true]) {
        final field = _trigger(context, hasError: hasError, enabled: true);
        expect(markers(field.affixWrapper.className), isEmpty);
        expect(markers(field.input.className), isEmpty);
        expect(
          field.affixWrapper.inlineStyles?.properties[kActiveBoundaryVar],
          isNull,
        );
      }

      pumpWithTheme(
        tester,
        const Select<String>(items: _kItems, placeholder: 'Pick'),
      );
      final boxes = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .where((d) => markers(d.classes).isNotEmpty)
          .toList();
      expect(boxes, isEmpty);
    });

    testComponents(
      'the trigger value is 14px body-medium at the role line height on '
      'every rung — the '
      "field's own default now, not a Select-specific override "
      '(2026-09-11 재검토)',
      (tester) async {
        final context = _themedContext(tester);
        for (final size in CoreSelectSize.values) {
          final select = resolveSelect(context, size: size);
          // Select states nothing for this any more — the field's own
          // `sm`/`md`/`lg` rungs already read at 14px body-medium at the
          // role's own line height themselves
          // (`CoreTextFieldStyle.defaultsBySize`).
          expect(select.triggerStyle.baseTextStyle, isNull, reason: size.name);
          final fieldBase = CoreTextFieldStyle
              .defaultsBySize[size.toComponentSize()]!
              .baseTextStyle!;
          // The role is kept as it is — no line height laid over it.
          expect(fieldBase.token, CoreTextStyles.bodyMedium, reason: size.name);
          expect(fieldBase.lineHeight, isNull, reason: size.name);
          expect(fieldBase.fontSize, isNull, reason: size.name);
        }
        final field = _trigger(context, hasError: false, enabled: true);
        expect(
          _classesOf(field.affixWrapper.className),
          contains('[&:hover:not(:focus-within)]:border-outline'),
        );
        expect(field.input.className, contains('text-body-medium'));
        expect(
          field.input.inlineStyles?.properties.containsKey('line-height'),
          isFalse,
        );
      },
    );

    test('accepts custom id', () {
      const select = Select<String>(items: _kItems, id: 'select-1');
      expect(select.id, equals('select-1'));
    });

    test('copyWith preserves properties', () {
      const original = Select<String>(
        items: _kItems,
        value: 'apple',
        enabled: false,
        id: 'select-orig',
      );

      final copy = original.copyWith(id: 'select-new');

      expect(copy.id, equals('select-new'));
      expect(copy.value, equals('apple'));
      expect(copy.enabled, isFalse);
    });

    test('implements CoreSelectContract', () {
      const select = Select<String>(
        items: [
          CoreSelectItem(value: 'a', label: 'A'),
          CoreSelectItem(value: 'b', label: 'B', enabled: false),
        ],
        value: 'a',
      );

      expect(select.value, equals('a'));
      expect(select.items.last.enabled, isFalse);
    });
  });
}
