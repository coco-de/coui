import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart' show TextCapitalization;
import 'package:flutter_test/flutter_test.dart';

// Widget test constants.
const _kInitialText = 'initial';
const _kHintText = 'Enter text here';
const _kPlaceholderText = 'Placeholder text';
const _kTypedText = 'typed text';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  _affixTextTests();
  _valueRoleTests();

  group('TextField selection color', () {
    for (final dark in [false, true]) {
      for (final (name, color, expectedAlpha) in [
        ('default', null, 0.2),
        ('transparent', CoreColor.transparent, 0.0),
        ('half-alpha', const CoreColor(0x80FF0000), 26 / 255),
      ]) {
        testWidgets('$name preserves source alpha, dark=$dark', (tester) async {
          await tester.pumpWidget(
            material.MaterialApp(
              home: Theme(
                data: dark ? const ThemeData.dark() : const ThemeData(),
                child: material.Scaffold(
                  body: TextField(
                    textFieldStyle: CoreTextFieldStyle(selectionColor: color),
                  ),
                ),
              ),
            ),
          );
          await tester.showKeyboard(find.byType(TextField));
          await tester.pump();
          final editable = tester.widget<material.EditableText>(
            find.byType(material.EditableText),
          );
          expect(editable.selectionColor!.a, closeTo(expectedAlpha, 0.001));
        });
      }
    }
  });

  group('TextField widget', () {
    testWidgets('optional caret height scales while input remains editable', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      Widget build(double scale, CoreTextFieldStyle? style) =>
          material.MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Theme(
                data: const ThemeData(),
                child: material.Scaffold(
                  body: TextField(
                    controller: controller,
                    textFieldStyle: style,
                  ),
                ),
              ),
            ),
          );
      await tester.pumpWidget(build(1, null));
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).cursorHeight,
        isNull,
      );
      await tester.pumpWidget(
        build(2, const CoreTextFieldStyle(cursorHeight: 28)),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).cursorHeight,
        56,
      );
      await tester.enterText(find.byType(EditableText), '123');
      expect(controller.text, '123');
      final editableState = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(
        editableState.renderEditable.cursorHeight,
        56,
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).selectionEnabled,
        isTrue,
      );
    });
    group('rendering', () {
      testWidgets('renders with no arguments', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextField(controller: TextEditingController()),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('renders with key parameter', (tester) async {
        const testKey = Key('text-field-test');
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextField(
                key: testKey,
                controller: TextEditingController(),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byKey(testKey), findsOneWidget);
      });

      testWidgets('renders with initialValue', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextField(
                initialValue: _kInitialText,
                controller: TextEditingController(),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('renders with placeholder', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextField(
                placeholder: const Text(_kPlaceholderText),
                controller: TextEditingController(),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.text(_kPlaceholderText), findsOneWidget);
      });

      testWidgets('affixColor override reaches the prefix IconTheme', (
        tester,
      ) async {
        const overrideColor = Color(0xFF123456);
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextField(
                controller: TextEditingController(),
                prefix: const material.Icon(material.Icons.search),
                textFieldStyle: const CoreTextFieldStyle(
                  affixColor: CoreColor(0xFF123456),
                ),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final iconTheme = tester.widget<IconTheme>(
          find
              .ancestor(
                of: find.byIcon(material.Icons.search),
                matching: find.byType(IconTheme),
              )
              .first,
        );
        expect(iconTheme.data.color, equals(overrideColor));
      });

      testWidgets('labelDisabledColor override reaches the disabled label', (
        tester,
      ) async {
        const overrideColor = Color(0xFF654321);
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextField(
                controller: TextEditingController(),
                label: 'Email',
                enabled: false,
                textFieldStyle: const CoreTextFieldStyle(
                  labelDisabledColor: CoreColor(0xFF654321),
                ),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final labelDefaultTextStyle = tester.widget<DefaultTextStyle>(
          find
              .ancestor(
                of: find.text('Email'),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        );
        expect(labelDefaultTextStyle.style.color, equals(overrideColor));
      });

      testWidgets('renders disabled TextField', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextField(
                enabled: false,
                controller: TextEditingController(),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('renders readOnly TextField', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextField(
                readOnly: true,
                controller: TextEditingController(),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('renders obscured TextField', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextField(
                obscureText: true,
                controller: TextEditingController(),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('renders with controller', (tester) async {
        final controller = TextEditingController(text: _kInitialText);
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextField(controller: controller),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
        controller.dispose();
      });

      testWidgets('renders with hintText for autofill', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextField(
                controller: TextEditingController(),
                hintText: _kHintText,
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
      });
    });

    group('callbacks', () {
      testWidgets('onChanged is called when text changes', (tester) async {
        String? changedValue;
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextField(
                onChanged: (value) {
                  changedValue = value;
                },
                controller: TextEditingController(),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(TextField));
        final _ = await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), _kTypedText);
        await tester.pump();
        expect(changedValue, equals(_kTypedText));
      });

      testWidgets('onTap is called when tapped', (tester) async {
        var tapCount = 0;
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextField(
                onTap: () {
                  tapCount += 1;
                },
                controller: TextEditingController(),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(TextField));
        final _ = await tester.pumpAndSettle();
        expect(tapCount, greaterThan(0));
      });
    });

    group('constructor defaults', () {
      test('default values are correctly set', () {
        final field = TextField(controller: TextEditingController());
        // Null, not `true`. `EditableText` turns autocorrect off for a
        // username or password autofill hint, and it only does that when
        // it receives null — a stated `true` replaced that inference for
        // every field in the kit. What null means here is "the platform
        // decides", which is the default worth having.
        expect(field.autocorrect, isNull);
        expect(field.autofocus, isFalse);
        expect(field.enabled, isTrue);
        expect(field.expands, isFalse);
        expect(field.obscureText, isFalse);
        expect(field.obscuringCharacter, equals('•'));
        expect(field.readOnly, isFalse);
        expect(field.textCapitalization, equals(TextCapitalization.none));
        expect(field.features, isEmpty);
      });

      test('maxLines defaults to 1', () {
        final field = TextField(controller: TextEditingController());
        expect(field.maxLines, equals(1));
      });

      test('clipBehavior defaults to hardEdge', () {
        final field = TextField(controller: TextEditingController());
        expect(field.clipBehavior, equals(Clip.hardEdge));
      });
    });

    group('selection gestures', () {
      testWidgets('drag across text extends a range selection', (
        tester,
      ) async {
        final controller = TextEditingController(text: 'hello world');
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(body: TextField(controller: controller)),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final editable = find.byType(EditableText);
        final start = tester.getTopLeft(editable) + const Offset(6, 8);
        final end = tester.getTopRight(editable) + const Offset(-6, 8);
        // Mouse drag = desktop / web click-drag selection (the reported
        // scenario). A touch drag scrolls instead on mobile platforms.
        final gesture = await tester.startGesture(
          start,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump(const Duration(milliseconds: 200));
        await gesture.moveTo(end);
        await tester.pump();
        await gesture.up();
        final _ = await tester.pumpAndSettle();

        // A drag selects a non-collapsed range rather than just moving
        // the caret — raw EditableText did neither before the gesture
        // builder was wired.
        expect(controller.selection.isCollapsed, isFalse);
      });

      testWidgets('double-tap selects the word under the pointer', (
        tester,
      ) async {
        final controller = TextEditingController(text: 'hello world');
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(body: TextField(controller: controller)),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final editable = find.byType(EditableText);
        final firstWord = tester.getTopLeft(editable) + const Offset(10, 8);
        await tester.tapAt(firstWord);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tapAt(firstWord);
        final _ = await tester.pumpAndSettle();

        final selected = controller.selection.textInside(controller.text);
        expect(selected, equals('hello'));
      });

      testWidgets('a disabled field selects nothing on drag', (tester) async {
        final controller = TextEditingController(text: 'hello world');
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextField(controller: controller, enabled: false),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final editable = find.byType(EditableText);
        final gesture = await tester.startGesture(
          tester.getTopLeft(editable) + const Offset(6, 8),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump(const Duration(milliseconds: 200));
        await gesture.moveTo(
          tester.getTopRight(editable) + const Offset(-6, 8),
        );
        await tester.pump();
        await gesture.up();
        final _ = await tester.pumpAndSettle();

        expect(controller.selection.isCollapsed, isTrue);
      });
    });
  });

  // The field's focus ring is the one `FocusOutline` the widget composes
  // around the input, and `resolveTextField` is the only thing that fills
  // its slot. The resolver merges the caller's `focusOutlineStyle` onto
  // the design default and then restates two fields with `copyWith` —
  // `borderRadius` and `borderColor`. Both arguments used to be locals
  // that can never be null (`focusRingColor` is a non-nullable variant
  // field, `borderRadius` is `merged.borderRadius ?? default`), and
  // `CoreFocusOutlineStyle.copyWith` writes any non-null argument through,
  // so the two values the merge had just carried in were overwritten every
  // time. The slot declared both fields and reached the paint with
  // neither.
  //
  // These read the resolver output rather than fishing a `FocusOutline`
  // out of the tree: `TextField` composes a chromeless inner buffer that
  // carries its own `FocusOutline`, so `find.byType` cannot say which ring
  // answered.
  // `resolveTextField` has always computed `resolvedHeight` /
  // `resolvedMinHeight` / `resolvedMaxHeight` (`text_field_style.dart`),
  // but the widget never read them — the `ConstrainedBox` its own
  // doc-comment ASCII tree already described was missing from `build()`.
  // Web wired the equivalent CSS `height`/`min-height`/`max-height`
  // through, so an explicit override reached Web and was silently dropped
  // on Flutter. These read the actual rendered box size, not the resolver
  // output, because the bug was specifically in the widget never applying
  // what the resolver already handed it.
  group('TextField height constraints (#5022)', () {
    testWidgets('an explicit height override fixes the rendered box height', (
      tester,
    ) async {
      const testKey = Key('text-field-height-override');
      await tester.pumpWidget(
        _buildApp(
          material.Scaffold(
            body: TextField(
              key: testKey,
              controller: TextEditingController(),
              textFieldStyle: const CoreTextFieldStyle(height: 64),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(testKey)).height, 64);
    });

    testWidgets('minHeight raises a shorter intrinsic field to the floor', (
      tester,
    ) async {
      const testKey = Key('text-field-min-height');
      await tester.pumpWidget(
        _buildApp(
          material.Scaffold(
            body: TextField(
              key: testKey,
              controller: TextEditingController(),
              textFieldStyle: const CoreTextFieldStyle(minHeight: 80),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(testKey)).height,
        greaterThanOrEqualTo(80),
      );
    });

    testWidgets('maxHeight clamps a fixed height override', (tester) async {
      const testKey = Key('text-field-max-height');
      await tester.pumpWidget(
        _buildApp(
          material.Scaffold(
            body: TextField(
              key: testKey,
              controller: TextEditingController(),
              textFieldStyle: const CoreTextFieldStyle(
                height: 100,
                maxHeight: 48,
              ),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(testKey)).height, 48);
    });

    group('the box is floored at the control height', () {
      // `CoreTextFieldStyle.boxMinHeight`: the size row's control height
      // (the height a `Button` of the same size has) is a MINIMUM — at
      // `md` and up it is what the box measures; at `xs` / `sm` padding +
      // line box are taller and win. Never a fixed height: under large
      // text the box grows instead of the text painting through it.
      Future<double> heightOf(
        WidgetTester tester, {
        CoreComponentSize size = CoreComponentSize.md,
        CoreTextFieldStyle? style,
        double textScale = 1,
        ThemeData theme = const ThemeData(),
      }) async {
        const testKey = Key('text-field-floor');
        await tester.pumpWidget(
          material.MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
              child: Theme(
                data: theme,
                child: material.Scaffold(
                  body: TextField(
                    key: testKey,
                    controller: TextEditingController(text: 'Hg'),
                    size: size,
                    textFieldStyle: style,
                  ),
                ),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        return tester.getSize(find.byKey(testKey)).height;
      }

      const control = {
        CoreComponentSize.xs: CoreControlSize.heightXs,
        CoreComponentSize.sm: CoreControlSize.heightSm,
        CoreComponentSize.md: CoreControlSize.heightMd,
        CoreComponentSize.lg: CoreControlSize.heightLg,
        CoreComponentSize.xl: CoreControlSize.heightXl,
        CoreComponentSize.xl2: CoreControlSize.heightXl2,
      };

      testWidgets('md and up measure exactly the control height', (
        tester,
      ) async {
        for (final size in [
          CoreComponentSize.md,
          CoreComponentSize.lg,
          CoreComponentSize.xl,
          CoreComponentSize.xl2,
        ]) {
          expect(
            await heightOf(tester, size: size),
            control[size],
            reason: size.name,
          );
        }
      });

      testWidgets('xs and sm sit on their rung too', (tester) async {
        // The row's vertical padding no longer sizes a one-line field: the
        // line is centred in the row (#5762, 2026-11-04 결정).
        for (final size in [CoreComponentSize.xs, CoreComponentSize.sm]) {
          expect(
            await heightOf(tester, size: size),
            control[size],
            reason: size.name,
          );
        }
      });

      testWidgets('the floor scales with density, like a Button', (
        tester,
      ) async {
        final phone = const AdaptiveScaling(1.25).scale(const ThemeData());
        expect(
          await heightOf(tester, theme: phone),
          CoreControlSize.heightMd * phone.scaling,
        );
      });

      testWidgets('large text grows the box past the floor', (tester) async {
        expect(
          await heightOf(tester, textScale: 2),
          greaterThan(CoreControlSize.heightMd),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('a fixed height decides the box, even below the floor', (
        tester,
      ) async {
        expect(
          await heightOf(tester, style: const CoreTextFieldStyle(height: 36)),
          36,
        );
      });

      testWidgets('a stated minHeight replaces the floor; 0 removes it', (
        tester,
      ) async {
        final intrinsic = await heightOf(
          tester,
          style: const CoreTextFieldStyle(minHeight: 0),
        );
        expect(intrinsic, lessThan(CoreControlSize.heightMd));
        expect(
          await heightOf(
            tester,
            style: const CoreTextFieldStyle(minHeight: 30),
          ),
          intrinsic,
        );
      });

      testWidgets('a caller minHeight still clamps a fixed height', (
        tester,
      ) async {
        expect(
          await heightOf(
            tester,
            style: const CoreTextFieldStyle(height: 36, minHeight: 44),
          ),
          44,
        );
      });

      testWidgets('a caller maxHeight above the floor leaves it alone', (
        tester,
      ) async {
        expect(
          await heightOf(
            tester,
            style: const CoreTextFieldStyle(maxHeight: 120),
          ),
          CoreControlSize.heightMd,
        );
      });

      testWidgets('a caller maxHeight below the floor caps it', (
        tester,
      ) async {
        expect(
          await heightOf(
            tester,
            style: const CoreTextFieldStyle(maxHeight: 38),
          ),
          38,
        );
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('TextField focus ring — the caller slot reaches it (#4120)', () {
    // A raw colour, deliberately neither the default variant tone
    // (`primary`) nor `CoreFocusOutlineStyle.defaultBorderColor` — so a
    // ring that fell back to either of those is visibly not this one.
    const rawGreen = CoreColor(0xFF00FF00);

    // Far off the 4px field default, so a radius that got dropped for the
    // component default is a number nobody can mistake for rounding.
    const bigRadius = CoreBorderRadius.all(CoreRadius.radius64);

    Future<ResolvedTextField> resolveIn(
      WidgetTester tester, {
      required bool hasError,
      CoreTextFieldStyle? style,
    }) async {
      late ResolvedTextField resolved;
      await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (context) {
              resolved = resolveTextField(
                context,
                hasError: hasError,
                enabled: true,
                size: CoreComponentSize.md,
                textFieldStyle: style,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return resolved;
    }

    testWidgets('an explicit slot borderColor wins over the variant tone', (
      tester,
    ) async {
      final resolved = await resolveIn(
        tester,
        hasError: false,
        style: const CoreTextFieldStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(borderColor: rawGreen),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(
        resolved.focusOutlineStyle.borderColor,
        rawGreen,
        reason:
            'the slot exposes borderColor, so a colour written there has '
            'to reach the ring — the variant tone is the fallback under '
            'it, not the winner over it',
      );
    });

    testWidgets('an explicit slot borderColor wins over the error tone too', (
      tester,
    ) async {
      final resolved = await resolveIn(
        tester,
        hasError: true,
        style: const CoreTextFieldStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(borderColor: rawGreen),
        ),
      );
      final _ = await tester.pumpAndSettle();

      // The error tone is a fallback, and a fallback that beats an
      // explicit value is not a fallback.
      expect(resolved.focusOutlineStyle.borderColor, rawGreen);
    });

    testWidgets('an explicit slot borderRadius wins over the field radius', (
      tester,
    ) async {
      final resolved = await resolveIn(
        tester,
        hasError: false,
        style: const CoreTextFieldStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(borderRadius: bigRadius),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(
        resolved.focusOutlineStyle.borderRadius,
        bigRadius,
        reason:
            'the caller radius has to reach the ring un-bent — the field '
            'corner is what it defers to, not what overrides it',
      );
    });

    // This one passes before the fix as well, and that is the point: it
    // fails for the *wrong* fix. Reading the merged slot back
    // (`slot.borderColor ?? focusBorderColor ?? vs.focusRingColor`) looks
    // equivalent, but `defaultFocusOutlineStyle` already states a
    // non-null `borderColor`, so the merged value is never null and the
    // variant tone becomes unreachable — the error ring silently goes
    // back to the default colour. The guard has to read the *pre-merge*
    // `merged.focusOutlineStyle?.borderColor`.
    testWidgets('with no slot colour, an invalid field still rings error', (
      tester,
    ) async {
      final resolved = await resolveIn(tester, hasError: true);
      final _ = await tester.pumpAndSettle();

      expect(
        resolved.focusOutlineStyle.borderColor,
        const CoreColor.token(CoreColors.error),
        reason:
            'the error variant tone is the fallback the ring lands on '
            'when the caller states no colour — a guard that reads the '
            'post-merge slot never reaches it',
      );
    });

    testWidgets('focusBorderColor still reaches the ring under an empty slot', (
      tester,
    ) async {
      final resolved = await resolveIn(
        tester,
        hasError: false,
        // A slot that states geometry but no colour: the middle rung of
        // the chain has to stay reachable through it.
        style: const CoreTextFieldStyle(
          focusBorderColor: rawGreen,
          focusOutlineStyle: CoreFocusOutlineStyle(borderWidth: 3),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(resolved.focusOutlineStyle.borderColor, rawGreen);
      expect(resolved.focusOutlineStyle.borderWidth, 3);
    });
  });

  group('TextField onCaretChanged', () {
    // The Flutter half of a capability the Web twin exposes under the same
    // name: a composing parent (Autocomplete completing the word under the
    // caret) needs to know where an edit landed, not just what the text is.

    testWidgets('reports the caret offset when the text changes', (
      tester,
    ) async {
      final carets = <int>[];
      await tester.pumpWidget(
        _buildApp(TextField(onCaretChanged: carets.add)),
      );
      final _ = await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Apple');
      await tester.pump();

      expect(carets.last, equals('Apple'.length));
    });

    testWidgets('fires before onChanged so the pair agrees', (tester) async {
      // A listener keeping both must never see a caret that belongs to the
      // previous value.
      final order = <String>[];
      await tester.pumpWidget(
        _buildApp(
          TextField(
            onChanged: (_) => order.add('changed'),
            onCaretChanged: (_) => order.add('caret'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Apple');
      await tester.pump();

      expect(order, equals(['caret', 'changed']));
    });
  });

  // The state-layer wash was measured against WCAG 2.4.13's 3:1 non-text
  // contrast floor and dropped from the boxed variants (Δcontrast
  // 1.06–1.17 in every mode — well short of the floor) — hover/focus now
  // ride the border alone. `plain` has no border to step, so it keeps its
  // ramp. This group pins the composited result, the same way
  // `text_field_state_change_perceptibility_test.dart` pins the tokens.
  group('TextField state-layer wash — dropped on boxed variants, kept on '
      'plain', () {
    Future<ResolvedTextField> resolveIn(
      WidgetTester tester, {
      required bool hasError,
      bool enabled = true,
      CoreTextFieldVariant? variant,
      CoreTextFieldStyle? style,
    }) async {
      late ResolvedTextField resolved;
      await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (context) {
              resolved = resolveTextField(
                context,
                hasError: hasError,
                enabled: enabled,
                size: CoreComponentSize.md,
                variant: variant,
                textFieldStyle: style,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return resolved;
    }

    testWidgets('the default variant paints the same fill hovered as '
        'resting', (tester) async {
      final resolved = await resolveIn(tester, hasError: false);
      final _ = await tester.pumpAndSettle();

      final resting = resolved.decoration.resolve({});

      for (final state in const [
        WidgetState.hovered,
        WidgetState.focused,
        WidgetState.pressed,
      ]) {
        expect(
          resolved.decoration.resolve({state}).color,
          resting.color,
          reason:
              '${state.name} rides the border alone now — a wash on top of '
              'it would double the signal and dim the value text and '
              'placeholder sitting on the same fill',
        );
      }
      // The state is still there — on the border.
      expect(
        resolved.decoration.resolve({WidgetState.hovered}).border,
        isNot(resting.border),
      );
    });

    testWidgets('the error variant paints the same fill in every '
        'interaction state', (tester) async {
      final resolved = await resolveIn(tester, hasError: true);
      final _ = await tester.pumpAndSettle();

      final resting = resolved.decoration.resolve({});
      for (final state in const [
        WidgetState.hovered,
        WidgetState.focused,
        WidgetState.pressed,
      ]) {
        expect(
          resolved.decoration.resolve({state}).color,
          resting.color,
          reason: state.name,
        );
      }
    });

    testWidgets('plain still washes once a caller states an opaque fill', (
      tester,
    ) async {
      // Plain's own default fill is transparent, and the resolver gates
      // the wash on `bgColor.a > 0` — so this test states an override,
      // the same way a real composition (Select's trigger) would.
      final resolved = await resolveIn(
        tester,
        hasError: false,
        variant: CoreTextFieldVariant.plain,
        style: const CoreTextFieldStyle(
          backgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final resting = resolved.decoration.resolve({});
      final hovered = resolved.decoration.resolve({WidgetState.hovered});

      expect(
        hovered.color,
        isNot(resting.color),
        reason:
            'plain has no border to step, so the wash is its only '
            'channel — it must still fire once the fill is opaque',
      );
    });

    testWidgets('plain paints no face or border when disabled — the '
        'host draws the disabled box', (tester) async {
      final resolved = await resolveIn(
        tester,
        hasError: false,
        enabled: false,
        variant: CoreTextFieldVariant.plain,
      );
      final _ = await tester.pumpAndSettle();

      final disabled = resolved.decoration.resolve({WidgetState.disabled});
      expect(
        disabled.color?.a ?? 0,
        0,
        reason:
            "a disabled fill here sat inside the host's own disabled box "
            'as a second, narrower face (ItemPicker search row)',
      );
      final border = disabled.border;
      if (border is Border) {
        expect(border.top.color.a, 0);
        expect(border.left.color.a, 0);
      }
    });

    testWidgets('disabled outranks error — the decoration is identical '
        'either way', (tester) async {
      final normal = await resolveIn(tester, hasError: false, enabled: false);
      final _ = await tester.pumpAndSettle();
      final error = await resolveIn(tester, hasError: true, enabled: false);
      final _ = await tester.pumpAndSettle();

      final normalDisabled = normal.decoration.resolve({WidgetState.disabled});
      final errorDisabled = error.decoration.resolve({WidgetState.disabled});

      expect(
        errorDisabled.color,
        normalDisabled.color,
        reason:
            'a disabled field is disabled first — the error tone must not '
            'survive into the disabled fill',
      );
      expect(errorDisabled.border, normalDisabled.border);
    });

    testWidgets('disabled outranks error — an errorBorderColor override '
        'does not survive into the disabled paint', (tester) async {
      // The two rows' disabled tokens agree, so the default-token check
      // above passes on row agreement alone. An override paints past the
      // rows — this is the case the resolver's own `disabled > error`
      // gate exists for.
      const rawRed = CoreColor(0xFFFF0000);
      final normal = await resolveIn(tester, hasError: false, enabled: false);
      final _ = await tester.pumpAndSettle();
      final error = await resolveIn(
        tester,
        hasError: true,
        enabled: false,
        style: const CoreTextFieldStyle(errorBorderColor: rawRed),
      );
      final _ = await tester.pumpAndSettle();

      final normalDisabled = normal.decoration.resolve({WidgetState.disabled});
      final errorDisabled = error.decoration.resolve({WidgetState.disabled});

      expect(
        errorDisabled.border,
        normalDisabled.border,
        reason:
            'a disabled field is disabled first — the error border override '
            'must not paint over the disabled border',
      );
    });

    testWidgets('the error border override still paints while enabled', (
      tester,
    ) async {
      const rawRed = CoreColor(0xFFFF0000);
      final error = await resolveIn(
        tester,
        hasError: true,
        style: const CoreTextFieldStyle(errorBorderColor: rawRed),
      );
      final _ = await tester.pumpAndSettle();

      final border = error.decoration.resolve({}).border! as Border;
      expect(border.top.color, const Color(0xFFFF0000));
    });

    testWidgets("plain's horizontal padding is flush (0) at every size", (
      tester,
    ) async {
      for (final size in CoreComponentSize.values) {
        late ResolvedTextField resolved;
        await tester.pumpWidget(
          _buildApp(
            Builder(
              builder: (context) {
                resolved = resolveTextField(
                  context,
                  hasError: false,
                  enabled: true,
                  size: size,
                  variant: CoreTextFieldVariant.plain,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        expect(
          resolved.padding.left,
          0,
          reason:
              '${size.name} — plain must start flush like the label '
              'above it, not offset by the boxed field gutter',
        );
        expect(resolved.padding.right, 0, reason: size.name);
        // A one-line field is held on its row with the line centred, so
        // there is no vertical inset for the variant to keep or drop.
        expect(resolved.padding.top, 0, reason: size.name);
        expect(resolved.padding.bottom, 0, reason: size.name);
      }
    });

    testWidgets(
      'an explicit padding override wins over the plain zero-gutter',
      (tester) async {
        final resolved = await resolveIn(
          tester,
          hasError: false,
          variant: CoreTextFieldVariant.plain,
          style: const CoreTextFieldStyle(
            padding: CoreEdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
        );
        final _ = await tester.pumpAndSettle();

        expect(resolved.padding.left, 20);
        expect(resolved.padding.right, 20);
      },
    );
  });

  // `disabled > error` gates the box chrome only. The widget keeps showing
  // `errorText` while disabled, so the message's style must keep reading
  // the Theme `variantStyles[error]` row — a project that moved its error
  // text colour onto that row would otherwise see a disabled field's
  // message fall back to the kit's default red.
  group('TextField disabled > error — box chrome only, the error message '
      'keeps the Theme error row', () {
    const rawGreen = CoreColor(0xFF00FF00);
    const rawRed = CoreColor(0xFFFF0000);
    const fieldTheme = CoreTextFieldTheme(
      variantStyles: {
        CoreTextFieldVariant.error: CoreTextFieldStyle(
          errorColor: rawGreen,
          borderColor: rawRed,
        ),
      },
    );

    Future<ResolvedTextField> resolveThemed(
      WidgetTester tester, {
      required bool enabled,
      bool hasError = true,
    }) async {
      late ResolvedTextField resolved;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(
              coreComponentTheme: CoreComponentTheme(textField: fieldTheme),
            ),
            child: Builder(
              builder: (context) {
                resolved = resolveTextField(
                  context,
                  hasError: hasError,
                  enabled: enabled,
                  size: CoreComponentSize.md,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      return resolved;
    }

    for (final enabled in const [true, false]) {
      testWidgets('enabled: $enabled — the error message reads the Theme '
          'error row', (tester) async {
        final resolved = await resolveThemed(tester, enabled: enabled);
        final _ = await tester.pumpAndSettle();

        expect(
          resolved.errorTextStyle.color,
          const Color(0xFF00FF00),
          reason:
              'the message is content, not box chrome — disabling the '
              'field must not drop the Theme error row off it',
        );
      });
    }

    testWidgets('disabled — the Theme error row does not reach the box '
        'border', (tester) async {
      final normal = await resolveThemed(
        tester,
        enabled: false,
        hasError: false,
      );
      final _ = await tester.pumpAndSettle();
      final error = await resolveThemed(tester, enabled: false);
      final _ = await tester.pumpAndSettle();

      expect(
        error.decoration.resolve({WidgetState.disabled}).border,
        normal.decoration.resolve({WidgetState.disabled}).border,
      );

      final enabled = await resolveThemed(tester, enabled: true);
      final _ = await tester.pumpAndSettle();
      final border = enabled.decoration.resolve({}).border! as Border;
      expect(
        border.top.color,
        const Color(0xFFFF0000),
        reason: 'sanity — the Theme error row paints while enabled',
      );
    });
  });
}

/// The style a `Text` placed in an affix slot actually paints with — the
/// widget hands it down through `DefaultTextStyle.merge`, so the element's
/// own `DefaultTextStyle` is the resolved one.
TextStyle _affixStyleOf(WidgetTester tester, String text) =>
    DefaultTextStyle.of(tester.element(find.text(text))).style;

void _affixTextTests() {
  group('TextField affix text', () {
    // `suffix` is `W?`, so a unit / count / timer is a legal suffix — and
    // its typography was stated nowhere: Flutter let it inherit the page's
    // ambient style, Web pinned it to the ICON size. Both now wear the
    // field's own size-base in the affix colour. Asserted at two rungs so
    // the base being per-size (not flat) is what passes, not a coincidence
    // at one size — xs/sm/md/lg share the 14px rung (bodyMedium), xl/xl2
    // the 15px rung (bodyLarge), so md and xl are the pair that actually
    // differ.
    testWidgets('wears the size base — 14 at md, 15 at xl', (tester) async {
      Future<double> fontSizeAt(CoreComponentSize size) async {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextField(
                controller: TextEditingController(),
                size: size,
                suffix: const Text('02:47'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return _affixStyleOf(tester, '02:47').fontSize!;
      }

      expect(await fontSizeAt(CoreComponentSize.md), CoreFontSize.s14);
      expect(await fontSizeAt(CoreComponentSize.xl), CoreFontSize.s15);
    });

    testWidgets('wears the affix colour, and affixColor overrides it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          material.Scaffold(
            body: TextField(
              controller: TextEditingController(),
              suffix: const Text('02:47'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final expected = Theme.of(
        tester.element(find.byType(TextField)),
      ).colorScheme.resolve(CoreTextFieldStyle.defaultAffixColor).toValue();
      expect(_affixStyleOf(tester, '02:47').color, expected);

      const override = Color(0xFF123456);
      await tester.pumpWidget(
        _buildApp(
          material.Scaffold(
            body: TextField(
              controller: TextEditingController(),
              suffix: const Text('02:47'),
              textFieldStyle: const CoreTextFieldStyle(
                affixColor: CoreColor(0xFF123456),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_affixStyleOf(tester, '02:47').color, override);
    });
  });

  // The style chain (`withStyle`, `.radius0`, `.surface` …) rebuilds the
  // field through `copyWith`, so a field `copyWith` forgets is lost the
  // moment a style is applied. `variant` was that field: an error-state
  // field given a style tweak silently stopped looking like an error.
  group('TextField copyWith keeps what it is not told to change', () {
    test('withStyle keeps the variant', () {
      final field = TextField(
        controller: TextEditingController(),
        variant: CoreTextFieldVariant.error,
      ).withStyle(const CoreTextFieldStyle());

      expect(field.variant, CoreTextFieldVariant.error);
    });

    test('copyWith can change the variant', () {
      final field = TextField(
        controller: TextEditingController(),
        variant: CoreTextFieldVariant.error,
      ).copyWith(variant: CoreTextFieldVariant.plain);

      expect(field.variant, CoreTextFieldVariant.plain);
    });
  });
}

void _valueRoleTests() {
  group('TextField value role', () {
    // The size rung's base is the role the field draws when nothing states
    // one: `bodyMedium` at the role's own 150% line — the field lays no line
    // height of its own over it. A role stated in `valueStyle` is the newer
    // statement, so it is drawn whole — its own size and its own line box.
    //
    // Read off `EditableText`, whose style is what the engine lays out:
    // `height * fontSize` is the line box in logical px.
    Future<TextStyle> typedStyle(
      WidgetTester tester, {
      CoreTextFieldStyle? style,
    }) async {
      await tester.pumpWidget(
        _buildApp(
          material.Scaffold(
            body: TextField(
              controller: TextEditingController(text: _kTypedText),
              textFieldStyle: style,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.widget<EditableText>(find.byType(EditableText)).style;
    }

    double lineBoxOf(TextStyle style) => style.height! * style.fontSize!;

    testWidgets('with no role stated the size base draws: 14px at 150%', (
      tester,
    ) async {
      final style = await typedStyle(tester);
      expect(style.fontSize, CoreFontSize.s14);
      expect(lineBoxOf(style), closeTo(CoreFontSize.s14 * 1.5, 0.001));
    });

    testWidgets('every size rung reads its role at the role line height', (
      tester,
    ) async {
      // 10-29 결정 — the line height is the Core role's own; no rung lays
      // its own over it. The box floors (md and up) are unchanged by it.
      for (final size in CoreComponentSize.values) {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: Center(
                child: TextField(
                  size: size,
                  controller: TextEditingController(text: _kTypedText),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final theme = Theme.of(tester.element(find.byType(EditableText)));
        final role = size.index >= CoreComponentSize.xl.index
            ? theme.typography.bodyLarge
            : theme.typography.bodyMedium;
        final style = tester
            .widget<EditableText>(find.byType(EditableText))
            .style;
        expect(style.fontSize, role.fontSize, reason: '$size');
        expect(style.height, role.lineHeight, reason: '$size');
        expect(style.height, 1.5, reason: '$size');
        final floor = CoreTextFieldStyle.defaultsBySize[size]!.minHeight!;
        if (size.index >= CoreComponentSize.md.index) {
          expect(
            tester.getSize(find.byType(TextField)).height,
            floor,
            reason: '$size',
          );
        }
      }
    });

    testWidgets('a stated code role draws its own size and fixed line box', (
      tester,
    ) async {
      final style = await typedStyle(
        tester,
        style: const CoreTextFieldStyle(
          valueStyle: CoreTextStyle.token(CoreTextStyles.codeMd),
        ),
      );
      expect(style.fontSize, 13);
      expect(lineBoxOf(style), closeTo(CoreLineBox.px21, 0.001));
    });

    testWidgets('what the stated style adds itself still lands on its role', (
      tester,
    ) async {
      final style = await typedStyle(
        tester,
        style: const CoreTextFieldStyle(
          valueStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
        ),
      );
      // No role stated: the base role is kept and the weight lands on it.
      expect(style.fontSize, CoreFontSize.s14);
      expect(lineBoxOf(style), closeTo(CoreFontSize.s14 * 1.5, 0.001));
      expect(style.fontWeight, FontWeight.w700);
    });

    testWidgets('a stated role replaces the base for the placeholder too', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          material.Scaffold(
            body: TextField(
              controller: TextEditingController(),
              placeholder: const Text(_kPlaceholderText),
              textFieldStyle: const CoreTextFieldStyle(
                placeholderStyle: CoreTextStyle.token(CoreTextStyles.codeMd),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final style = DefaultTextStyle.of(
        tester.element(find.text(_kPlaceholderText)),
      ).style;
      expect(style.fontSize, 13);
      expect(lineBoxOf(style), closeTo(CoreLineBox.px21, 0.001));
    });
  });
}
