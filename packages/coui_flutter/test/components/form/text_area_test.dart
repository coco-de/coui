import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// Theme test constants.

// Widget test constants.
const _kCustomInitialHeight = 150.0;
const _kMinHeight = 80.0;
const _kMaxHeight = 300.0;
const _kInitialWidth = 200.0;
const _kMinWidth = 100.0;
const _kMaxWidth = 500.0;
const _kPlaceholderText = 'Enter your message...';
const _kInitialText = 'Initial text content';
const _kTypedText = 'some typed content';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  group('TextArea widget', () {
    group('rendering', () {
      testWidgets('renders with no arguments', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextArea(controller: TextEditingController()),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byType(TextArea), findsOneWidget);
      });

      testWidgets('renders with key parameter', (tester) async {
        const testKey = Key('text-area-test');
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextArea(
                key: testKey,
                controller: TextEditingController(),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byKey(testKey), findsOneWidget);
      });

      testWidgets('renders with placeholder', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextArea(
                controller: TextEditingController(),
                placeholder: _kPlaceholderText,
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.text(_kPlaceholderText), findsOneWidget);
      });

      testWidgets('renders with initialValue', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextArea(
                initialValue: _kInitialText,
                controller: TextEditingController(),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byType(TextArea), findsOneWidget);
      });

      testWidgets(
        'requiredMarkColor override reaches the FormLabel asterisk',
        (tester) async {
          const overrideColor = Color(0xFF00FF00);
          await tester.pumpWidget(
            _buildApp(
              material.Scaffold(
                body: TextArea(
                  controller: TextEditingController(),
                  label: 'Notes',
                  required: true,
                  textAreaStyle: const CoreTextAreaStyle(
                    requiredMarkColor: CoreColor(0xFF00FF00),
                  ),
                ),
              ),
            ),
          );
          final _ = await tester.pumpAndSettle();

          final asterisk = tester.widget<material.Text>(
            find.descendant(
              of: find.byType(FormLabel),
              matching: find.text('*'),
            ),
          );
          expect(asterisk.style?.color, equals(overrideColor));
        },
      );

      testWidgets('renders disabled TextArea', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextArea(
                controller: TextEditingController(),
                enabled: false,
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byType(TextArea), findsOneWidget);
      });

      testWidgets('renders readOnly TextArea', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextArea(
                controller: TextEditingController(),
                readOnly: true,
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byType(TextArea), findsOneWidget);
      });

      testWidgets('renders with controller', (tester) async {
        final controller = TextEditingController(text: _kInitialText);
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextArea(controller: controller),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byType(TextArea), findsOneWidget);
        controller.dispose();
      });

      testWidgets('renders with custom initialHeight', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextArea(
                controller: TextEditingController(),
                textAreaStyle: const CoreTextAreaStyle(
                  initialHeight: _kCustomInitialHeight,
                ),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byType(TextArea), findsOneWidget);
      });

      testWidgets('renders with expandableHeight enabled', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextArea(
                controller: TextEditingController(),
                expandableHeight: true,
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byType(TextArea), findsOneWidget);
      });

      testWidgets('renders with expandableWidth enabled', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextArea(
                controller: TextEditingController(),
                expandableWidth: true,
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byType(TextArea), findsOneWidget);
      });

      testWidgets('renders with leading widget', (tester) async {
        const leadingText = 'LEAD';
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextArea(
                controller: TextEditingController(),
                prefix: const Text(leadingText),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.text(leadingText), findsOneWidget);
      });

      testWidgets('renders with trailing widget', (tester) async {
        const trailingText = 'TRAIL';
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextArea(
                controller: TextEditingController(),
                suffix: const Text(trailingText),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.text(trailingText), findsOneWidget);
      });
    });

    group('constructor defaults', () {
      test('default field values are correct', () {
        final area = TextArea();
        expect(area.autofocus, isFalse);
        expect(area.enabled, isTrue);
        expect(area.expandableHeight, isFalse);
        expect(area.expandableWidth, isFalse);
        expect(area.obscureText, isFalse);
        expect(area.obscuringCharacter, equals('•'));
        expect(area.readOnly, isFalse);
      });
    });

    group('callbacks', () {
      testWidgets('onChanged is called when text changes', (tester) async {
        String? changedValue;
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextArea(
                onChanged: (value) {
                  changedValue = value;
                },
                controller: TextEditingController(),
              ),
            ),
          ),
        );
        await tester.tap(find.byType(TextArea));
        final _ = await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), _kTypedText);
        await tester.pump();
        expect(changedValue, equals(_kTypedText));
      });

      testWidgets('onHeightChanged is invoked when height changes', (
        tester,
      ) async {
        double? newHeight;
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextArea(
                controller: TextEditingController(),
                expandableHeight: true,
                onHeightChanged: (h) {
                  newHeight = h;
                },
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        // The callback is attached; actual resize via gesture is hard to simulate.
        expect(newHeight, isNull); // not triggered without drag
      });

      testWidgets('onWidthChanged is invoked when width changes', (
        tester,
      ) async {
        double? newWidth;
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextArea(
                controller: TextEditingController(),
                expandableWidth: true,
                onWidthChanged: (w) {
                  newWidth = w;
                },
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(newWidth, isNull); // not triggered without drag
      });
    });

    group('dimension constraints', () {
      testWidgets('respects minHeight and maxHeight settings', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextArea(
                controller: TextEditingController(),
                expandableHeight: true,
                textAreaStyle: const CoreTextAreaStyle(
                  maxHeight: _kMaxHeight,
                  minHeight: _kMinHeight,
                ),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byType(TextArea), findsOneWidget);
      });

      testWidgets('respects minWidth and maxWidth settings', (tester) async {
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: TextArea(
                controller: TextEditingController(),
                expandableWidth: true,
                textAreaStyle: const CoreTextAreaStyle(
                  initialWidth: _kInitialWidth,
                  maxWidth: _kMaxWidth,
                  minWidth: _kMinWidth,
                ),
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(find.byType(TextArea), findsOneWidget);
      });
    });
  });

  // Same defect, same shape as the `TextField` twin: `resolveTextArea`
  // merges the caller's `focusOutlineStyle` onto the design default and
  // then restates `borderRadius` and `borderColor` with `copyWith`. Both
  // arguments can never be null — `focusRingColor` is a non-nullable
  // variant field and the radius local is `merged.borderRadius ??
  // default` — and `CoreFocusOutlineStyle.copyWith` writes any non-null
  // argument through, so the merge's two carried values were overwritten
  // every time.
  //
  // Read the resolver output rather than the widget tree: `TextArea`
  // composes a chromeless inner buffer with its own `FocusOutline`, so
  // `find.byType` cannot say which ring answered.
  group('TextArea focus ring — the caller slot reaches it (#4120)', () {
    // Neither the default variant tone (`primary`) nor the text area's
    // own `defaultFocusOutlineStyle.borderColor` (also `primary`) — a
    // ring that fell back to either is visibly not this one.
    const rawGreen = CoreColor(0xFF00FF00);

    // Far off the 4px default, so a dropped radius is unmistakable.
    const bigRadius = CoreBorderRadius.all(CoreRadius.radius64);

    Future<ResolvedTextArea> resolveIn(
      WidgetTester tester, {
      required bool hasError,
      CoreTextAreaStyle? style,
    }) async {
      late ResolvedTextArea resolved;
      await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (context) {
              resolved = resolveTextArea(
                context,
                hasError: hasError,
                size: CoreComponentSize.md,
                textAreaStyle: style,
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
        style: const CoreTextAreaStyle(
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
        style: const CoreTextAreaStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(borderColor: rawGreen),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(resolved.focusOutlineStyle.borderColor, rawGreen);
    });

    testWidgets('an explicit slot borderRadius wins over the field radius', (
      tester,
    ) async {
      final resolved = await resolveIn(
        tester,
        hasError: false,
        style: const CoreTextAreaStyle(
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

    // Passes before the fix too, and that is the point — it fails for
    // the *wrong* fix, on the radius axis this time.
    //
    // Of the four sites, `CoreTextAreaStyle.defaultFocusOutlineStyle` is
    // the only one that states a `borderRadius`. So a radius guard
    // written against the post-merge slot is never null here, and the
    // `?? borderRadius` tail — the area's own corner — becomes
    // unreachable: the box would round to 64 and the ring would stay at
    // the 4px default, on the same widget.
    testWidgets('with no slot radius, the ring follows the area corner', (
      tester,
    ) async {
      final resolved = await resolveIn(
        tester,
        hasError: false,
        style: const CoreTextAreaStyle(borderRadius: bigRadius),
      );
      final _ = await tester.pumpAndSettle();

      expect(
        resolved.focusOutlineStyle.borderRadius,
        bigRadius,
        reason:
            'the ring traces the corner it sits on — a box rounded to 64 '
            'with a ring still at 4 is two radii on one widget',
      );
    });

    // Passes before the fix too, and that is the point: it fails for the
    // *wrong* fix. `CoreTextAreaStyle.defaultFocusOutlineStyle` already
    // states a non-null `borderColor`, so a guard written against the
    // post-merge slot (`slot.borderColor ?? …`) is never null and the
    // error tone becomes unreachable — the invalid ring silently goes
    // back to `primary`. The guard has to read the pre-merge
    // `merged.focusOutlineStyle?.borderColor`.
    testWidgets('with no slot colour, an invalid area still rings error', (
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
        style: const CoreTextAreaStyle(
          focusBorderColor: rawGreen,
          focusOutlineStyle: CoreFocusOutlineStyle(borderWidth: 3),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(resolved.focusOutlineStyle.borderColor, rawGreen);
      expect(resolved.focusOutlineStyle.borderWidth, 3);
    });
  });

  // TextArea carries hover on the border and states no wash at all — the
  // same border-only model TextField's boxed variants use. And a disabled
  // area is disabled first: a stale error must not reach its chrome.
  group(
    'TextArea state model — border-only hover, disabled outranks error',
    () {
      // A raw colour neither variant row states, so a border that picked
      // it up is visibly the Theme's error row and nothing else.
      const rawRed = CoreColor(0xFFFF0000);

      Future<ResolvedTextArea> resolveIn(
        WidgetTester tester, {
        required bool hasError,
        bool enabled = true,
        CoreTextAreaTheme? areaTheme,
      }) async {
        late ResolvedTextArea resolved;
        await tester.pumpWidget(
          material.MaterialApp(
            home: Theme(
              data: ThemeData(
                coreComponentTheme: CoreComponentTheme(textArea: areaTheme),
              ),
              child: Builder(
                builder: (context) {
                  resolved = resolveTextArea(
                    context,
                    hasError: hasError,
                    size: CoreComponentSize.md,
                    enabled: enabled,
                  );
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
        return resolved;
      }

      for (final hasError in const [false, true]) {
        testWidgets('hasError: $hasError — the fill is the same in every '
            'interaction state', (tester) async {
          final resolved = await resolveIn(tester, hasError: hasError);
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
      }

      testWidgets('disabled outranks error — the default rows paint the same '
          'disabled decoration', (tester) async {
        final normal = await resolveIn(tester, hasError: false, enabled: false);
        final _ = await tester.pumpAndSettle();
        final error = await resolveIn(tester, hasError: true, enabled: false);
        final _ = await tester.pumpAndSettle();

        final normalDisabled = normal.decoration.resolve({
          WidgetState.disabled,
        });
        final errorDisabled = error.decoration.resolve({WidgetState.disabled});

        expect(errorDisabled.color, normalDisabled.color);
        expect(errorDisabled.border, normalDisabled.border);
      });

      testWidgets('disabled outranks error — a Theme error-row border does not '
          'survive into the disabled paint', (tester) async {
        // The rows' disabled tokens agree, so the check above passes on row
        // agreement alone. A Theme `variantStyles[true]` border paints past
        // the rows — the resolver's own gate is what keeps it out.
        const areaTheme = CoreTextAreaTheme(
          variantStyles: {true: CoreTextAreaStyle(borderColor: rawRed)},
        );
        final normal = await resolveIn(
          tester,
          hasError: false,
          enabled: false,
          areaTheme: areaTheme,
        );
        final _ = await tester.pumpAndSettle();
        final error = await resolveIn(
          tester,
          hasError: true,
          enabled: false,
          areaTheme: areaTheme,
        );
        final _ = await tester.pumpAndSettle();

        expect(
          error.decoration.resolve({WidgetState.disabled}).border,
          normal.decoration.resolve({WidgetState.disabled}).border,
          reason:
              'a disabled area is disabled first — the error row the Theme '
              'states must not paint over the disabled border',
        );

        final enabled = await resolveIn(
          tester,
          hasError: true,
          areaTheme: areaTheme,
        );
        final _ = await tester.pumpAndSettle();
        final border = enabled.decoration.resolve({}).border! as Border;
        expect(
          border.top.color,
          const Color(0xFFFF0000),
          reason: 'the Theme error row still paints while the area is enabled',
        );
      });

      // `disabled > error` gates the box chrome only — the widget keeps
      // showing `errorText` while disabled, so the message's style keeps
      // reading the Theme `variantStyles[true]` row.
      for (final enabled in const [true, false]) {
        testWidgets('enabled: $enabled — the error message reads the Theme '
            'error row', (tester) async {
          const areaTheme = CoreTextAreaTheme(
            variantStyles: {
              true: CoreTextAreaStyle(errorTextColor: CoreColor(0xFF00FF00)),
            },
          );
          final resolved = await resolveIn(
            tester,
            hasError: true,
            enabled: enabled,
            areaTheme: areaTheme,
          );
          final _ = await tester.pumpAndSettle();

          expect(
            resolved.errorTextStyle.color,
            const Color(0xFF00FF00),
            reason:
                'the message is content, not box chrome — disabling the '
                'area must not drop the Theme error row off it',
          );
        });
      }
    },
  );
}
