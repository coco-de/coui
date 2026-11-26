import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: Theme(data: const ThemeData(), child: child),
  ),
);

/// One generous frame — enough for the popover's open / close motion.
const _kFrame = Duration(seconds: 1);

const _kItems = [
  CoreSelectItem<String>(value: 'apple', label: 'Apple'),
  CoreSelectItem<String>(value: 'banana', label: 'Banana'),
  CoreSelectItem<String>(value: 'cherry', label: 'Cherry'),
];

/// Resolves the trigger's field chrome the way `Select` hands it to the
/// composed `TextField`: `resolveSelect` settles the slot, the field's
/// resolver paints it. Read from the resolvers rather than fished out of
/// the tree — the field composes an inner buffer with its own box.
Future<({ResolvedTextField field, ThemeData theme})> _resolveTrigger(
  WidgetTester tester, {
  required bool hasError,
  required bool enabled,
  CoreSelectSize size = CoreSelectSize.md,
}) async {
  late ResolvedTextField field;
  late ThemeData theme;
  await tester.pumpWidget(
    _buildApp(
      Builder(
        builder: (context) {
          theme = Theme.of(context);
          final select = resolveSelect(
            context,
            size: size,
            enabled: enabled,
            variant: hasError
                ? CoreSelectVariant.error
                : CoreSelectVariant.defaultVariant,
          );
          field = resolveTextField(
            context,
            hasError: hasError,
            enabled: enabled,
            size: size.toComponentSize(),
            variant: hasError
                ? CoreTextFieldVariant.error
                : CoreTextFieldVariant.defaultVariant,
            textFieldStyle: select.triggerStyle,
          );
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return (field: field, theme: theme);
}

Color _token(ThemeData theme, CoreColorToken name) =>
    theme.colorScheme.resolve(CoreColor.token(name)).toValue();

void main() {
  group('CoreSelectItem', () {
    test('stores value and label', () {
      const item = CoreSelectItem<String>(value: 'apple', label: 'Apple');

      expect(item.value, equals('apple'));
      expect(item.label, equals('Apple'));
      expect(item.enabled, isTrue);
    });
  });

  group('Select widget', () {
    testWidgets('changing scroll policy while open takes effect', (
      tester,
    ) async {
      final scroll = ScrollController();
      final closes = ValueNotifier(false);
      addTearDown(scroll.dispose);
      addTearDown(closes.dispose);
      await tester.pumpWidget(
        _buildApp(
          ListView(
            controller: scroll,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: closes,
                builder: (_, value, _) =>
                    Select<String>(items: _kItems, closeOnScroll: value),
              ),
              const SizedBox(height: 1200),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(Select<String>));
      await tester.pump(_kFrame);
      closes.value = true;
      await tester.pump();
      scroll.jumpTo(20);
      await tester.pump();
      await tester.pump(_kFrame);
      expect(find.text('Cherry'), findsNothing);
    });
    testWidgets('scrolling menu options keeps the menu open', (tester) async {
      final items = List.generate(
        30,
        (i) => CoreSelectItem(value: i, label: 'Item $i'),
      );
      await tester.pumpWidget(_buildApp(Select<int>(items: items)));
      await tester.tap(find.byType(Select<int>));
      await tester.pump(_kFrame);
      final menuScroll = tester.state<ScrollableState>(
        find
            .ancestor(
              of: find.text('Item 3'),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.drag(find.text('Item 3'), const Offset(0, -120));
      await tester.pump(_kFrame);
      expect(menuScroll.position.pixels, greaterThan(0));
      expect(find.text('Item 10'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    testWidgets('default closes on ancestor scroll but not sibling scroll', (
      tester,
    ) async {
      final outer = ScrollController();
      final sibling = ScrollController();
      addTearDown(outer.dispose);
      addTearDown(sibling.dispose);
      await tester.pumpWidget(
        _buildApp(
          Row(
            children: [
              Expanded(
                child: ListView(
                  controller: outer,
                  children: const [
                    Select<String>(items: _kItems),
                    SizedBox(height: 1200),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: sibling,
                  children: const [
                    SizedBox(height: 1200),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(Select<String>));
      await tester.pump(_kFrame);
      sibling.jumpTo(80);
      await tester.pump(_kFrame);
      expect(find.text('Cherry'), findsOneWidget);
      outer.jumpTo(80);
      await tester.pump();
      await tester.pump(_kFrame);
      expect(find.text('Cherry'), findsNothing);
    });
    for (final closeOnScroll in [true, false]) {
      testWidgets('ancestor scrolling with closeOnScroll $closeOnScroll', (
        tester,
      ) async {
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        await tester.pumpWidget(
          _buildApp(
            ListView(
              key: const ValueKey('outer-scroll'),
              controller: scroll,
              children: [
                Select<String>(items: _kItems, closeOnScroll: closeOnScroll),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        );
        await tester.tap(find.byType(Select<String>));
        await tester.pump(_kFrame);
        expect(find.text('Cherry'), findsOneWidget);
        scroll.jumpTo(80);
        await tester.pump(_kFrame);
        expect(
          find.text('Cherry'),
          closeOnScroll ? findsNothing : findsOneWidget,
        );
      });
    }
    for (final scale in [1.0, 2.0]) {
      testWidgets('content-width currency panel at text scale $scale', (
        tester,
      ) async {
        String? selected;
        await tester.pumpWidget(
          _buildApp(
            MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Center(
                child: SizedBox(
                  width: 85,
                  child: Select<String>(
                    value: 'USD',
                    items: const [
                      CoreSelectItem(value: 'USD', label: 'USD'),
                      CoreSelectItem(value: 'KRW', label: 'KRW'),
                    ],
                    popoverWidthConstraint: CorePopoverConstraint.anchorMinSize,
                    onChanged: (value) => selected = value,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(Select<String>));
        await tester.pump(_kFrame);
        final label = tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.text('KRW'),
            matching: find.byType(RichText),
          ),
        );
        final painter = TextPainter(
          text: label.text,
          textDirection: TextDirection.ltr,
          textScaler: label.textScaler,
        )..layout(maxWidth: label.size.width);
        expect(painter.computeLineMetrics(), hasLength(1));
        painter.dispose();
        await tester.tap(find.text('KRW'));
        await tester.pump(_kFrame);
        expect(selected, 'KRW');
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets(
      'content-width panel preserves selection and keyboard semantics',
      (
        tester,
      ) async {
        final changes = <String>[];
        const initial = Select<String>(items: _kItems, value: 'apple');
        expect(
          initial.popoverWidthConstraint,
          CorePopoverConstraint.anchorFixedSize,
        );
        final expanded = initial
            .copyWith(
              popoverWidthConstraint: CorePopoverConstraint.anchorMinSize,
              onChanged: changes.add,
            )
            .withStyle(const CoreSelectStyle());
        await tester.pumpWidget(_buildApp(expanded));
        final semantics = tester.ensureSemantics();
        await tester.tap(find.byType(Select<String>));
        await tester.pump(_kFrame);
        expect(
          find.byWidgetPredicate(
            (widget) => widget is CoUISemantics && widget.selected == true,
          ),
          findsOneWidget,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump(_kFrame);
        expect(changes, ['banana']);
        semantics.dispose();
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'custom suffix opens the same panel and preserves keyboard selection',
      (tester) async {
        final changes = <String>[];
        final select = Select<String>(
          items: _kItems,
          value: 'apple',
          suffix: const Text('Change'),
          onChanged: changes.add,
        ).withStyle(const CoreSelectStyle());
        await tester.pumpWidget(_buildApp(select));
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Icon && widget.icon == LucideIcons.chevronDown,
          ),
          findsNothing,
        );
        await tester.tap(find.text('Change'));
        await tester.pump(_kFrame);
        expect(find.text('Cherry'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump(_kFrame);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
        await tester.pump(_kFrame);
        expect(changes, ['banana']);
      },
    );
    testWidgets('disabled custom suffix cannot open or select', (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(
        _buildApp(
          Select<String>(
            items: _kItems,
            suffix: const Text('Change'),
            enabled: false,
            onChanged: changes.add,
          ),
        ),
      );
      await tester.tap(find.text('Change'), warnIfMissed: false);
      await tester.pump(_kFrame);
      expect(find.text('Banana'), findsNothing);
      expect(changes, isEmpty);
    });
    testWidgets('omitting suffix preserves the default chevron', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const Select<String>(items: _kItems)));
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Icon && widget.icon == LucideIcons.chevronDown,
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders with placeholder when no value', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Select<String>(
            placeholder: 'Select an option',
            items: _kItems,
          ),
        ),
      );

      expect(find.byType(Select<String>), findsOneWidget);
      expect(find.text('Select an option'), findsOneWidget);
    });

    testWidgets('accepts key parameter', (tester) async {
      const testKey = material.Key('test-select');

      await tester.pumpWidget(
        _buildApp(
          const Select<String>(
            key: testKey,
            placeholder: 'Select',
            items: _kItems,
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('shows the selected item label when value is set', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Select<String>(
            onChanged: (_) {},
            placeholder: 'Select an option',
            value: 'apple',
            items: _kItems,
          ),
        ),
      );

      expect(find.text('Apple'), findsOneWidget);
    });

    // A loose parent (a `Center`, a docs pane) is where the two sizings
    // part: `intrinsic` hugs the placeholder, `expand` lets the field take
    // the parent's width — the width the web trigger takes as `w-full`.
    testWidgets('fills the available width — a field trigger, not a hugging '
        'box', (tester) async {
      const parentWidth = 300.0;
      await tester.pumpWidget(
        _buildApp(
          material.Align(
            alignment: Alignment.topLeft,
            child: material.ConstrainedBox(
              constraints: const material.BoxConstraints(
                maxWidth: parentWidth,
              ),
              child: Select<String>(
                onChanged: (_) {},
                placeholder: 'Pick',
                items: _kItems,
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(Select<String>)).width, parentWidth);
    });

    testWidgets('a stated popoverStyle can hand the trigger back to its own '
        'width', (tester) async {
      const parentWidth = 300.0;
      await tester.pumpWidget(
        _buildApp(
          material.Align(
            alignment: Alignment.topLeft,
            child: material.ConstrainedBox(
              constraints: const material.BoxConstraints(
                maxWidth: parentWidth,
              ),
              child: Select<String>(
                onChanged: (_) {},
                placeholder: 'Pick',
                items: _kItems,
                selectStyle: const CoreSelectStyle(
                  popoverStyle: CorePopoverStyle(triggerSizing: .intrinsic),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(Select<String>)).width,
        lessThan(parentWidth),
      );
    });

    // A `Row` leaves the horizontal axis unbounded, and a field that fills
    // has nothing to fill there: the trigger takes its natural width instead
    // of throwing, and the parent can still state one (`Expanded`).
    testWidgets('in a Row the trigger hugs instead of throwing, and an '
        'Expanded one fills', (tester) async {
      Widget select() => Select<String>(
        onChanged: (_) {},
        placeholder: 'Pick',
        items: _kItems,
      );

      await tester.pumpWidget(_buildApp(material.Row(children: [select()])));
      expect(tester.takeException(), isNull);
      final row = tester.getSize(find.byType(material.Row).first).width;
      expect(tester.getSize(find.byType(Select<String>)).width, lessThan(row));

      await tester.pumpWidget(
        _buildApp(material.Row(children: [material.Expanded(child: select())])),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(Select<String>)).width, row);
    });

    // The hugging is a render box, not a `LayoutBuilder`: a `LayoutBuilder`
    // throws when an ancestor asks for intrinsic dimensions.
    testWidgets('answers an ancestor IntrinsicWidth', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          material.Align(
            alignment: Alignment.topLeft,
            child: material.IntrinsicWidth(
              child: material.Column(
                children: [
                  Select<String>(
                    onChanged: (_) {},
                    placeholder: 'Pick',
                    items: _kItems,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(Select<String>), findsOneWidget);
    });
  });

  group('the trigger is a field with two divergences', () {
    testWidgets('its value is 14px body-medium on every rung', (tester) async {
      for (final size in CoreSelectSize.values) {
        final r = await _resolveTrigger(
          tester,
          hasError: false,
          enabled: true,
          size: size,
        );
        final value = r.field.valueTextStyle.resolve(const {});
        expect(
          value.fontSize,
          r.theme.typography.bodyMedium.fontSize,
          reason: '${size.name} — the select does not step its type down',
        );
      }
    });

    testWidgets('hover is a border step, not a wash', (tester) async {
      final r = await _resolveTrigger(tester, hasError: false, enabled: true);
      final rest = r.field.decoration.resolve(const {});
      final hover = r.field.decoration.resolve(const {WidgetState.hovered});
      expect(
        rest.border!.top.color,
        _token(r.theme, CoreColors.outlineVariant),
      );
      expect(hover.border!.top.color, _token(r.theme, CoreColors.outline));
      expect(hover.color, rest.color, reason: 'hover paints no fill');
    });

    testWidgets('focus is the ring and the primary border, no wash', (
      tester,
    ) async {
      final r = await _resolveTrigger(tester, hasError: false, enabled: true);
      final rest = r.field.decoration.resolve(const {});
      final focus = r.field.decoration.resolve(const {WidgetState.focused});
      expect(focus.border!.top.color, _token(r.theme, CoreColors.primary));
      expect(focus.color, rest.color, reason: 'focus paints no fill');
    });

    testWidgets('pressed is the one state that washes — 12%', (tester) async {
      final r = await _resolveTrigger(tester, hasError: false, enabled: true);
      final rest = r.field.decoration.resolve(const {});
      final pressed = r.field.decoration.resolve(const {
        WidgetState.hovered,
        WidgetState.pressed,
      });
      final fg = _token(r.theme, CoreColors.onSurface);
      expect(
        pressed.color,
        Color.alphaBlend(
          fg.withValues(alpha: CoreOpacity.pressed),
          rest.color!,
        ),
      );
      expect(pressed.border!.top.color, _token(r.theme, CoreColors.outline));
    });

    testWidgets('error outranks hover — the border stays error', (
      tester,
    ) async {
      final r = await _resolveTrigger(tester, hasError: true, enabled: true);
      final rest = r.field.decoration.resolve(const {});
      final hover = r.field.decoration.resolve(const {WidgetState.hovered});
      final focus = r.field.decoration.resolve(const {WidgetState.focused});
      final error = _token(r.theme, CoreColors.error);
      expect(rest.border!.top.color, error);
      expect(hover.border!.top.color, error);
      expect(focus.border!.top.color, error);
    });

    testWidgets('disabled outranks error — the disabled trio paints', (
      tester,
    ) async {
      final r = await _resolveTrigger(tester, hasError: true, enabled: false);
      final disabled = r.field.decoration.resolve(const {WidgetState.disabled});
      expect(
        disabled.border!.top.color,
        _token(r.theme, CoreColors.disabledOutline),
      );
      expect(disabled.color, _token(r.theme, CoreColors.disabledContainer));
      final pressed = r.field.decoration.resolve(const {
        WidgetState.disabled,
        WidgetState.pressed,
      });
      expect(pressed.color, disabled.color, reason: 'no wash while disabled');
    });
  });

  group("disabled — the field's own tone (#5747)", () {
    testWidgets('placeholder and value take disabledContent', (tester) async {
      final r = await _resolveTrigger(tester, hasError: false, enabled: false);
      final disabledContent = _token(r.theme, CoreColors.disabledContent);
      expect(r.field.placeholderTextStyle.color, disabledContent);
      expect(
        r.field.valueTextStyle.resolve(const {WidgetState.disabled}).color,
        disabledContent,
      );
    });

    testWidgets('the chevron is left untinted while disabled', (tester) async {
      late ResolvedSelect enabled;
      late ResolvedSelect disabled;
      await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (context) {
              enabled = resolveSelect(context);
              disabled = resolveSelect(context, enabled: false);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(
        enabled.chevronIconStyle.color,
        CoreSelectStyle.defaultPlaceholderColor,
      );
      expect(disabled.chevronIconStyle.color, isNull);
    });
  });

  group('keyboard — closed, the arrows and the letters move the value', () {
    Future<void> pumpFocused(
      WidgetTester tester, {
      required void Function(String) onChanged,
      String? value,
    }) async {
      await tester.pumpWidget(
        _buildApp(
          Select<String>(
            onChanged: onChanged,
            value: value,
            placeholder: 'Pick',
            items: _kItems,
          ),
        ),
      );
      // A tap opens the panel; Escape closes it and leaves focus on the
      // trigger, which is the closed-and-focused pose these tests start
      // from. Fixed pumps rather than `pumpAndSettle` — the overlay keeps
      // a ticker alive, so "settled" never arrives.
      await tester.tap(find.byType(TextField));
      await tester.pump(_kFrame);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(_kFrame);
    }

    testWidgets('Down selects the next value without opening', (tester) async {
      final changes = <String>[];
      await pumpFocused(tester, onChanged: changes.add, value: 'apple');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump(_kFrame);
      expect(changes, ['banana']);
      expect(find.text('Cherry'), findsNothing, reason: 'the panel stays shut');
    });

    testWidgets('Home / End jump to the first / last value', (tester) async {
      final changes = <String>[];
      await pumpFocused(tester, onChanged: changes.add, value: 'banana');
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump(_kFrame);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump(_kFrame);
      expect(changes, ['cherry', 'apple']);
    });

    testWidgets('a letter moves to the next label starting with it — '
        'typeahead, not a filter', (tester) async {
      final changes = <String>[];
      await pumpFocused(tester, onChanged: changes.add, value: 'apple');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.pump(_kFrame);
      expect(changes, ['cherry']);
      // A second letter inside the typeahead window extends the prefix
      // (`cb` matches nothing, so the value stays) — the letters spell a
      // word, they do not each jump. The window runs on the wall clock,
      // so the test cannot outwait it; the wrap-around below is the
      // "every row is still there" proof instead.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.pump(_kFrame);
      expect(changes, ['cherry']);
    });

    testWidgets('typeahead wraps — nothing was filtered out', (tester) async {
      final changes = <String>[];
      await pumpFocused(tester, onChanged: changes.add, value: 'cherry');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump(_kFrame);
      expect(changes, ['apple']);
    });

    testWidgets('Escape leaves the value alone', (tester) async {
      final changes = <String>[];
      await pumpFocused(tester, onChanged: changes.add, value: 'apple');
      expect(changes, isEmpty);
      expect(find.text('Apple'), findsOneWidget);
    });
  });
}
