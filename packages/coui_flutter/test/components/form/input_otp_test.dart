import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

// OTP codepoint constants — '0' = 48.
const _kCodepointDigitZero = 48;

// OTP length fixture constants.
const _kOtpLength = 4;

Widget _buildApp(Widget child, {ThemeData? theme}) => material.MaterialApp(
  home: Theme(data: theme ?? const ThemeData(), child: child),
);

/// Settles pending frames, discarding the returned frame count.
Future<void> _settle(WidgetTester tester) async {
  final _ = await tester.pumpAndSettle();
}

void main() {
  group('InputOtp widget', () {
    testWidgets('renders with length parameter', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            body: InputOtp(length: _kOtpLength),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(InputOtp), findsOneWidget);
    });

    testWidgets('renders with key parameter', (tester) async {
      const testKey = Key('input-otp');
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            body: InputOtp(key: testKey, length: _kOtpLength),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('renders with separator interval', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            // The contract defaults — six cells, a separator every three.
            body: InputOtp(),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(InputOtp), findsOneWidget);
    });

    testWidgets('renders obscured', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            body: InputOtp(length: _kOtpLength, obscured: true),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(InputOtp), findsOneWidget);
    });

    testWidgets('renders with initialValue', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            body: InputOtp(
              length: 3,
              separatorInterval: 0,
              // '1', '2', '3' codepoints.
              initialValue: [49, 50, 51],
            ),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(InputOtp), findsOneWidget);
    });

    testWidgets('onChanged callback is wired up', (tester) async {
      OTPCodepointList? changedValue;
      await tester.pumpWidget(
        _buildApp(
          material.Scaffold(
            body: InputOtp(
              length: _kOtpLength,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );
      await _settle(tester);
      // Callback is wired; triggering it requires actual key input.
      expect(changedValue, isNull);
    });
  });

  group('InputOtp keyboard interaction', () {
    testWidgets('backspace on filled cell clears value', (tester) async {
      OTPCodepointList? lastChanged;
      await tester.pumpWidget(
        _buildApp(
          material.Scaffold(
            body: InputOtp(
              length: 3,
              separatorInterval: 0,
              onChanged: (v) => lastChanged = v,
              initialValue: const [_kCodepointDigitZero, null, null],
            ),
          ),
        ),
      );
      await _settle(tester);

      // Focus the hidden buffer.
      await tester.tap(find.byType(TextField).first);
      await _settle(tester);

      final _ = await tester.sendKeyEvent(.backspace);
      await _settle(tester);

      expect(lastChanged, isNotNull);
      expect(lastChanged![0], isNull);
    });

    testWidgets('arrow keys do not crash navigation', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            body: InputOtp(length: 3, separatorInterval: 0),
          ),
        ),
      );
      await _settle(tester);

      await tester.tap(find.byType(TextField).first);
      await _settle(tester);

      final _ = await tester.sendKeyEvent(.arrowRight);
      await _settle(tester);
      final _ = await tester.sendKeyEvent(.arrowLeft);
      await _settle(tester);

      expect(find.byType(InputOtp), findsOneWidget);
    });

    testWidgets('tapping the field moves the caret to the end of the '
        'entered text', (tester) async {
      // '1', '2' codepoints — two of four cells filled.
      const partialCode = [49, 50, null, null];
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            body: InputOtp(
              initialValue: partialCode,
              length: 4,
              separatorInterval: 0,
            ),
          ),
        ),
      );
      await _settle(tester);

      // Tap anywhere on the row — the underlying invisible buffer's own
      // glyph layout has no relationship to the visual cell grid, so the
      // caret must always land at the end of the entered text ("12"),
      // never wherever the tap physically hit the buffer.
      await tester.tap(find.byType(TextField).first);
      await _settle(tester);

      final editable = tester.widget<material.EditableText>(
        find.byType(material.EditableText),
      );
      expect(
        editable.controller.selection,
        const TextSelection.collapsed(offset: 2),
      );
    });

    testWidgets(
      'backspace removes one digit at a time — active cell (index == '
      'controller.text.length) moves back a slot per press',
      (tester) async {
        const typedCode = '123';
        await tester.pumpWidget(
          _buildApp(
            const material.Scaffold(
              body: InputOtp(length: 4, separatorInterval: 0),
            ),
          ),
        );
        await _settle(tester);

        await tester.showKeyboard(find.byType(TextField));
        await tester.enterText(find.byType(TextField), typedCode);
        await tester.pump();

        final editable = tester.widget<material.EditableText>(
          find.byType(material.EditableText),
        );

        Future<void> backspaceOnce() async {
          final _ = await tester.sendKeyEvent(.backspace);
          await tester.pump();
        }

        // Active index (`_activeIndex`) is `controller.text.length`
        // clamped to `length - 1` — verifying the length here directly
        // verifies the active cell tracks backspace one slot at a time.
        expect(editable.controller.text.length, equals(typedCode.length));
        await backspaceOnce();
        expect(
          editable.controller.text.length,
          equals(typedCode.length - 1),
        );
        await backspaceOnce();
        expect(
          editable.controller.text.length,
          equals(typedCode.length - 2),
        );
      },
    );
  });

  group('InputOtp error state', () {
    testWidgets('renders no error text by default', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(body: InputOtp(length: _kOtpLength)),
        ),
      );
      await _settle(tester);
      expect(find.text('Invalid code'), findsNothing);
    });

    testWidgets('renders the error message below the cell row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            body: InputOtp(length: _kOtpLength, errorText: 'Invalid code'),
          ),
        ),
      );
      await _settle(tester);
      expect(find.text('Invalid code'), findsOneWidget);
      // Still exactly one hidden TextField — the error variant only
      // changes chrome (border colour), never the single-input
      // architecture (Web parity).
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('InputOtp autofocus', () {
    testWidgets('does not autofocus by default', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(body: InputOtp(length: _kOtpLength)),
        ),
      );
      await _settle(tester);
      final editable = tester.widget<material.EditableText>(
        find.byType(material.EditableText),
      );
      expect(editable.focusNode.hasFocus, isFalse);
    });

    testWidgets('autofocuses when autofocus is true', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            body: InputOtp(length: _kOtpLength, autofocus: true),
          ),
        ),
      );
      await _settle(tester);
      final editable = tester.widget<material.EditableText>(
        find.byType(material.EditableText),
      );
      expect(editable.focusNode.hasFocus, isTrue);
    });
  });

  group('InputOtp focus release on completion', () {
    testWidgets('releases focus when all cells are filled', (tester) async {
      OTPCodepointList? completedValue;
      await tester.pumpWidget(
        _buildApp(
          material.Scaffold(
            body: InputOtp(
              length: _kOtpLength,
              separatorInterval: 0,
              onCompleted: (value) => completedValue = value,
            ),
          ),
        ),
      );
      await _settle(tester);

      // Focusing the field raises the soft keyboard.
      await tester.showKeyboard(find.byType(TextField));
      await tester.pump();
      final editable = tester.widget<material.EditableText>(
        find.byType(material.EditableText),
      );
      expect(editable.focusNode.hasFocus, isTrue);

      // Enter the full code.
      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();

      // onCompleted fired and focus was released (keyboard dismissed).
      expect(completedValue, isNotNull);
      expect(editable.focusNode.hasFocus, isFalse);
    });

    testWidgets('keeps focus while the code is incomplete', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            body: InputOtp(
              length: _kOtpLength,
              separatorInterval: 0,
            ),
          ),
        ),
      );
      await _settle(tester);

      await tester.showKeyboard(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();

      // Still incomplete → focus is retained (keyboard stays up).
      final editable = tester.widget<material.EditableText>(
        find.byType(material.EditableText),
      );
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets(
      'onCompleted fires exactly once — editing an already-complete '
      'code (still full length afterward) must not re-fire it',
      (tester) async {
        var completedCount = 0;
        await tester.pumpWidget(
          _buildApp(
            material.Scaffold(
              body: InputOtp(
                length: _kOtpLength,
                separatorInterval: 0,
                onCompleted: (_) => completedCount += 1,
              ),
            ),
          ),
        );
        await _settle(tester);

        await tester.showKeyboard(find.byType(TextField));
        await tester.enterText(find.byType(TextField), '1234');
        await tester.pump();
        expect(completedCount, equals(1));

        // Replace the whole (still 4-digit) value in one go — length
        // never dips below `_kOtpLength` at any point, so this must NOT
        // re-invoke onCompleted a second time for the same completion.
        await tester.enterText(find.byType(TextField), '5678');
        await tester.pump();
        expect(completedCount, equals(1));
      },
    );
  });

  group('InputOtp obscured vs. plaintext rendering (#security)', () {
    testWidgets('renders the digit as visible text when not obscured', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            body: InputOtp(
              initialValue: [_kCodepointDigitZero],
              length: 1,
              separatorInterval: 0,
            ),
          ),
        ),
      );
      await _settle(tester);
      // `find.text` also matches the hidden buffer's `EditableText`
      // (whose controller always holds the raw digit for keyboard /
      // autofill purposes, obscured or not) — so the digit-vs-dot
      // assertion must target the visible glyph `Text` widget
      // specifically, not any widget merely containing that string.
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data == '0'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders a dot in place of the digit when obscured — the '
      'plaintext digit never reaches a visible Text widget',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const material.Scaffold(
              body: InputOtp(
                initialValue: [_kCodepointDigitZero],
                length: 1,
                obscured: true,
                separatorInterval: 0,
              ),
            ),
          ),
        );
        await _settle(tester);
        // The digit must not appear as a visible glyph `Text` anywhere —
        // this is the actual security property `obscured` promises. (The
        // hidden buffer's `EditableText` still carries the raw digit for
        // keyboard/autofill — that's a separate, already-invisible
        // element and not what this test is guarding.)
        expect(
          find.byWidgetPredicate((w) => w is Text && w.data == '0'),
          findsNothing,
        );
        // The dot chrome renders as a circular `Container` in its place.
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).shape == .circle,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders no dot for an empty (unfilled) cell even when obscured',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const material.Scaffold(
              body: InputOtp(length: 1, obscured: true, separatorInterval: 0),
            ),
          ),
        );
        await _settle(tester);
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).shape == .circle,
          ),
          findsNothing,
        );
      },
    );
  });

  group('InputOtp disabled state', () {
    testWidgets('disables the hidden TextField and dims the row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            body: InputOtp(length: _kOtpLength, enabled: false),
          ),
        ),
      );
      await _settle(tester);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, equals(CoreOpacity.opacity50));
    });

    testWidgets('does not dim the row when enabled', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(body: InputOtp(length: _kOtpLength)),
        ),
      );
      await _settle(tester);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isTrue);
      expect(find.byType(Opacity), findsNothing);
    });
  });

  group('InputOtp variant colour threading (#Theme.variantStyles)', () {
    /// Captures the [BuildContext] a real widget tree resolves under (with
    /// the ambient [Theme] `_buildApp` installs) so resolver-level tests
    /// can call `resolveInputOtp` directly instead of re-deriving chrome
    /// assertions by digging through the rendered widget tree.
    Future<BuildContext> themedContext(
      WidgetTester tester, {
      ThemeData? theme,
    }) async {
      late BuildContext context;
      await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
          theme: theme,
        ),
      );
      await _settle(tester);
      return context;
    }

    testWidgets('default variant cell border uses the outlineVariant token', (
      tester,
    ) async {
      final context = await themedContext(tester);
      final resolved = resolveInputOtp(context);
      // `OutlinedContainer` resolves the token through the active scheme
      // itself, so the composed chrome carries the raw Core token, not
      // a materialised Flutter `Color`.
      expect(
        resolved.unfocusedCellContainerStyle.borderColor,
        equals(CoreInputOtpStyle.defaultBorderColor),
      );
      expect(
        resolved.unfocusedCellContainerStyle.borderColor,
        equals(const CoreColor.token(CoreColors.outlineVariant)),
      );
    });

    testWidgets(
      'error variant switches the cell border, focused-cell border, and '
      'focus ring to the error token',
      (tester) async {
        final context = await themedContext(tester);
        final resolved = resolveInputOtp(context, hasError: true);
        const expectedErrorColor = CoreColor.token(CoreColors.error);
        expect(
          resolved.unfocusedCellContainerStyle.borderColor,
          equals(expectedErrorColor),
        );
        expect(
          resolved.focusedCellContainerStyle.borderColor,
          equals(expectedErrorColor),
        );
        // The focus-ring colour must thread through the same
        // merged-override → variant-chrome chain as the border, rather
        // than a separate hardcoded `hasError` ternary — otherwise a
        // `CoreInputOtpTheme.variantStyles` override recolouring the
        // error variant's border would leave the ring on the wrong
        // colour.
        expect(
          resolved.cellFocusOutlineStyle.borderColor,
          equals(const CoreColor.token(CoreColors.error)),
        );
      },
    );

    testWidgets(
      'default variant leaves the focus ring on its own design-system '
      'default (no explicit ring-colour override threaded through)',
      (tester) async {
        final context = await themedContext(tester);
        final resolved = resolveInputOtp(context);
        expect(resolved.cellFocusOutlineStyle.borderColor, isNull);
      },
    );

    testWidgets(
      'a project-level CoreInputOtpTheme.variantStyles override for the '
      'error variant recolours the cell border consistently with the '
      'ring — the ring must not stay pinned to the global error token',
      (tester) async {
        const projectErrorStyle = CoreInputOtpStyle(
          borderColor: CoreColor.token(CoreColors.tertiary),
          focusBorderColor: CoreColor.token(CoreColors.tertiary),
        );
        final context = await themedContext(
          tester,
          theme: const ThemeData(
            coreComponentTheme: CoreComponentTheme(
              inputOtp: CoreInputOtpTheme(
                variantStyles: {
                  .defaultVariant: CoreInputOtpStyle(),
                  .error: projectErrorStyle,
                },
              ),
            ),
          ),
        );
        final overridden = resolveInputOtp(context, hasError: true);
        const expectedTertiary = CoreColor.token(CoreColors.tertiary);
        expect(
          overridden.focusedCellContainerStyle.borderColor,
          equals(expectedTertiary),
        );
        expect(
          overridden.cellFocusOutlineStyle.borderColor,
          equals(const CoreColor.token(CoreColors.tertiary)),
        );
      },
    );
  });

  group('InputOtp hover border', () {
    const rest = CoreColor.token(CoreColors.outlineVariant);
    const hover = CoreColor.token(CoreColors.outline);
    const error = CoreColor.token(CoreColors.error);

    /// Captures the [BuildContext] a real widget tree resolves under so the
    /// resolver can be read directly.
    Future<BuildContext> themedContext(WidgetTester tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      await _settle(tester);
      return context;
    }

    Future<void> pumpOtp(WidgetTester tester, InputOtp otp) async {
      await tester.pumpWidget(
        _buildApp(material.Scaffold(body: Center(child: otp))),
      );
      await _settle(tester);
    }

    /// The border colour each cell box is painting right now — read off the
    /// decoration the cell's `OutlinedContainer` hands the framework, not
    /// off the style that was requested.
    List<Color> paintedCellBorders(WidgetTester tester) {
      final colors = <Color>[];
      for (final box
          in find
              .descendant(
                of: find.byType(InputOtp),
                matching: find.byType(OutlinedContainer),
              )
              .evaluate()) {
        final decorated = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byElementPredicate((e) => e == box),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        colors.add((decorated.decoration as BoxDecoration).border!.top.color);
      }
      return colors;
    }

    Color resolvedToken(WidgetTester tester, CoreColor token) {
      final context = tester.element(find.byType(InputOtp));
      return Theme.of(context).colorScheme.resolve(token).toValue();
    }

    /// Parks a mouse pointer on the middle of the control.
    Future<TestGesture> hoverControl(WidgetTester tester) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byType(InputOtp)));
      await _settle(tester);
      return gesture;
    }

    testWidgets('resolver: a resting cell hovers to outline, the fill is '
        'untouched, the resting edge is still outlineVariant', (tester) async {
      final context = await themedContext(tester);
      final resolved = resolveInputOtp(context);

      expect(resolved.hoveredCellContainerStyle.borderColor, hover);
      expect(
        resolved.hoveredCellContainerStyle.backgroundColor,
        resolved.unfocusedCellContainerStyle.backgroundColor,
      );
      expect(resolved.unfocusedCellContainerStyle.borderColor, rest);
    });

    testWidgets('resolver: the error variant restates error for hover', (
      tester,
    ) async {
      final context = await themedContext(tester);
      final resolved = resolveInputOtp(context, hasError: true);

      expect(resolved.hoveredCellContainerStyle.borderColor, error);
    });

    testWidgets('resolver: a per-instance hoverBorderColor wins over the '
        'default and over the error variant', (tester) async {
      final context = await themedContext(tester);
      const tertiary = CoreColor.token(CoreColors.tertiary);
      const style = CoreInputOtpStyle(hoverBorderColor: tertiary);

      expect(
        resolveInputOtp(
          context,
          inputOtpStyle: style,
        ).hoveredCellContainerStyle.borderColor,
        tertiary,
      );
      expect(
        resolveInputOtp(
          context,
          hasError: true,
          inputOtpStyle: style,
        ).hoveredCellContainerStyle.borderColor,
        tertiary,
      );
    });

    testWidgets('pointer over the control steps every resting cell to '
        'outline, and leaving steps it back', (tester) async {
      await pumpOtp(tester, const InputOtp(length: _kOtpLength));
      final restColor = resolvedToken(tester, rest);
      final hoverColor = resolvedToken(tester, hover);
      expect(hoverColor, isNot(restColor));

      expect(paintedCellBorders(tester), everyElement(restColor));

      final gesture = await hoverControl(tester);
      expect(paintedCellBorders(tester), hasLength(_kOtpLength));
      expect(paintedCellBorders(tester), everyElement(hoverColor));

      await gesture.moveTo(const Offset(1, 1));
      await _settle(tester);
      expect(paintedCellBorders(tester), everyElement(restColor));
    });

    testWidgets('an error control keeps its error edge under the pointer', (
      tester,
    ) async {
      await pumpOtp(
        tester,
        const InputOtp(length: _kOtpLength, errorText: 'Invalid code'),
      );
      final errorColor = resolvedToken(tester, error);

      expect(paintedCellBorders(tester), everyElement(errorColor));
      await hoverControl(tester);
      expect(paintedCellBorders(tester), everyElement(errorColor));
    });

    testWidgets('a disabled control has no hover step', (tester) async {
      await pumpOtp(
        tester,
        const InputOtp(length: _kOtpLength, enabled: false),
      );
      final restColor = resolvedToken(tester, rest);

      await hoverControl(tester);
      expect(paintedCellBorders(tester), everyElement(restColor));
    });

    testWidgets('a focused control does not step: the active cell keeps its '
        'focus border and the cells beside it stay at rest', (tester) async {
      await pumpOtp(tester, const InputOtp(length: _kOtpLength));
      final restColor = resolvedToken(tester, rest);
      final hoverColor = resolvedToken(tester, hover);

      // Hover first, so the pointer is already over the control when focus
      // arrives — the case a plain `hover > rest` ladder would get wrong.
      await hoverControl(tester);
      expect(paintedCellBorders(tester), everyElement(hoverColor));

      await tester.tap(find.byType(TextField).first);
      await _settle(tester);

      // The active cell (the first, nothing typed) takes the neutral
      // `outline` focus edge; the cells beside it go back to rest.
      final borders = paintedCellBorders(tester);
      expect(borders.first, hoverColor);
      expect(borders.skip(1), everyElement(restColor));
    });
  });

  group('InputOtp layout', () {
    testWidgets('hugs the cell-row width instead of stretching (Web '
        'inline-flex w-fit parity)', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            body: Center(
              child: InputOtp(length: _kOtpLength),
            ),
          ),
        ),
      );
      await _settle(tester);

      final otpWidth = tester.getSize(find.byType(InputOtp)).width;
      final bodyWidth = tester.getSize(find.byType(material.Scaffold)).width;
      expect(
        otpWidth,
        lessThan(bodyWidth),
        reason:
            'the component must size to its cells so an enclosing '
            'Center actually centres it — a stretched root pinned the '
            'left-aligned cells to the left at wide preview widths',
      );

      // And centred: equal margins on both sides.
      final otpRect = tester.getRect(find.byType(InputOtp));
      final bodyRect = tester.getRect(find.byType(material.Scaffold));
      expect(
        (otpRect.left - bodyRect.left) - (bodyRect.right - otpRect.right),
        closeTo(0, 1),
      );
    });
  });

  group('cell focus ring corner radius is raw-forwarded (not double-bent)', () {
    testWidgets('cellFocusOutlineStyle.borderRadius is the un-bent default', (
      tester,
    ) async {
      // `FocusOutline`'s own resolver already runs the geometry bend +
      // scaling on whatever `CoreFocusOutlineStyle.borderRadius` it is
      // given (focus_outline_style.dart). If `input_otp_style.dart`
      // pre-bent/pre-scaled the value before forwarding it here, that
      // bend/scale would apply a second time — a regression this test
      // pins by asserting the forwarded value is exactly the un-bent
      // design-system default, not a derived scalar.
      //
      // Read the resolver output directly rather than fishing a
      // `FocusOutline` instance out of the render tree — the hidden
      // backing `TextField` composes its own `FocusOutline` too (with
      // its own non-null default `borderRadius`, since `TextField`'s
      // resolver fills defaults before forwarding), so a tree query
      // cannot reliably tell the two apart.
      //
      // A non-1 `scaling` is required to make a double-application
      // observable at all: at the default `scaling: 1` with identity
      // geometry, bending/scaling a value twice is numerically a
      // no-op both times, so a buggy and a fixed resolver would
      // return the same number and this assertion would pass either
      // way.
      late ResolvedInputOtp resolved;
      await tester.pumpWidget(
        _buildApp(
          material.Scaffold(
            body: Builder(
              builder: (context) {
                resolved = resolveInputOtp(context);
                return const SizedBox.shrink();
              },
            ),
          ),
          theme: const ThemeData(scaling: 1.25),
        ),
      );
      await _settle(tester);

      expect(
        resolved.cellFocusOutlineStyle.borderRadius,
        CoreInputOtpStyle.defaultBorderRadius,
        reason:
            'the cell focus ring should receive the raw design-system '
            'default corner radius — a bent/scaled scalar here would '
            'be geometry-bent a second time by FocusOutline itself',
      );
    });
  });

  // A 50 × 58 cell (a large verification code field) was impossible:
  // the cell was `SizedBox.square(cellSize)`. And a cell taller than the row
  // was squeezed by the row's scale-down fit, where the Web twin let it
  // overflow — so the row is never shorter than its cells on either side.
  group('InputOtp cell geometry', () {
    Future<ResolvedInputOtp> resolve(
      WidgetTester tester,
      CoreInputOtpStyle? style,
    ) async {
      late ResolvedInputOtp resolved;
      await tester.pumpWidget(
        _buildApp(
          material.Scaffold(
            body: Builder(
              builder: (context) {
                resolved = resolveInputOtp(context, inputOtpStyle: style);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      return resolved;
    }

    testWidgets('an unset cell is the Core default box', (tester) async {
      final resolved = await resolve(tester, null);

      expect(resolved.cellSize, CoreInputOtpStyle.defaultCellSize);
      expect(resolved.cellHeight, CoreInputOtpStyle.defaultCellHeight);
      expect(resolved.height, CoreInputOtpStyle.defaultHeight);
    });

    testWidgets('cellHeight draws a cell that is not square', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            body: Center(
              child: InputOtp(
                length: _kOtpLength,
                inputOtpStyle: CoreInputOtpStyle(
                  cellSize: CoreSize.size48,
                  cellHeight: CoreSize.size56,
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);

      final cell = tester.getSize(find.byType(OutlinedContainer).first);
      expect(cell, const Size(CoreSize.size48, CoreSize.size56));
    });

    testWidgets('a restated cellSize alone keeps the cell square', (
      tester,
    ) async {
      final resolved = await resolve(
        tester,
        const CoreInputOtpStyle(cellSize: CoreSize.size48),
      );

      expect(resolved.cellHeight, CoreSize.size48);
    });

    testWidgets('the row is never shorter than its cells', (tester) async {
      // A cell taller than the row's default used to shrink to the row
      // under the scale-down fit — the cell keeps its height now.
      await tester.pumpWidget(
        _buildApp(
          const material.Scaffold(
            body: Center(
              child: InputOtp(
                length: _kOtpLength,
                inputOtpStyle: CoreInputOtpStyle(cellSize: CoreSize.size56),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);

      final cell = tester.getSize(find.byType(OutlinedContainer).first);
      expect(cell, const Size(CoreSize.size56, CoreSize.size56));
    });

    testWidgets('length and separatorInterval default to the contract', (
      tester,
    ) async {
      const otp = InputOtp();
      expect(otp.length, CoreInputOtpContract.defaultLength);
      expect(
        otp.separatorInterval,
        CoreInputOtpContract.defaultSeparatorInterval,
      );
    });
  });

  // The size axis and the #6464 redesign — what the tree can answer is read
  // off the rendered boxes and paragraphs, not off the resolver alone: a
  // value the resolver returns proves nothing about where the widget put it.
  group('InputOtp size', () {
    // '1', '2', '3', '4' — a full four-cell value so every cell shows its
    // glyph and the default separator (after the third cell) is drawn.
    const fullValue = [49, 50, 51, 52];
    const primary = CoreColor.token(CoreColors.primary);

    Future<ResolvedInputOtp> resolveAt(
      WidgetTester tester, {
      CoreInputOtpSize? size,
      CoreInputOtpStyle? style,
      ThemeData? theme,
      bool hasError = false,
    }) async {
      late ResolvedInputOtp resolved;
      await tester.pumpWidget(
        _buildApp(
          material.Scaffold(
            body: Builder(
              builder: (context) {
                resolved = size == null
                    ? resolveInputOtp(
                        context,
                        hasError: hasError,
                        inputOtpStyle: style,
                      )
                    : resolveInputOtp(
                        context,
                        size: size,
                        hasError: hasError,
                        inputOtpStyle: style,
                      );
                return const SizedBox.shrink();
              },
            ),
          ),
          theme: theme,
        ),
      );
      return resolved;
    }

    Future<void> pumpOtp(
      WidgetTester tester,
      InputOtp otp, {
      ThemeData? theme,
    }) async {
      await tester.pumpWidget(
        _buildApp(
          material.Scaffold(body: Center(child: otp)),
          theme: theme,
        ),
      );
      await _settle(tester);
    }

    Finder cells() => find.descendant(
      of: find.byType(InputOtp),
      matching: find.byType(OutlinedContainer),
    );

    TextStyle paintedStyle(WidgetTester tester, String glyph) {
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.byType(InputOtp), matching: find.text(glyph)),
      );
      return paragraph.text.style!;
    }

    BoxDecoration paintedCell(WidgetTester tester, int index) {
      final decorated = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: cells().at(index),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      return decorated.decoration as BoxDecoration;
    }

    /// The corner the first cell's box hands the framework.
    Radius paintedCellCorner(WidgetTester tester) => paintedCell(
      tester,
      0,
    ).borderRadius!.resolve(TextDirection.ltr).topLeft;

    Color resolvedToken(WidgetTester tester, CoreColor token) {
      final context = tester.element(find.byType(InputOtp));
      return Theme.of(context).colorScheme.resolve(token).toValue();
    }

    /// Painted boxes inside the cell row that are not a cell — the caret,
    /// the separator bar and the obscured dot are each a `Container` with a
    /// decoration of its own.
    Finder decoratedContainers(bool Function(BoxDecoration d) test) =>
        find.descendant(
          of: find.byType(InputOtp),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                test(w.decoration! as BoxDecoration),
          ),
        );

    Finder caret(WidgetTester tester, CoreColor colour) => decoratedContainers(
      (d) =>
          d.shape == BoxShape.rectangle &&
          d.color == resolvedToken(tester, colour) &&
          d.borderRadius != null,
    );

    testWidgets('md resolves the #6464 field', (tester) async {
      for (final explicit in [false, true]) {
        final resolved = await resolveAt(
          tester,
          size: explicit ? CoreInputOtpSize.md : null,
        );

        expect(resolved.cellSize, CoreSpace.space44);
        expect(resolved.cellHeight, CoreSpace.space52);
        expect(resolved.height, CoreSpace.space52);
        expect(resolved.cellSpacing, CoreSpace.space8);
        expect(resolved.obscuredDotSize, CoreSize.size10);
        const corner = CoreBorderRadius.all(CoreRadius.radius10);
        expect(resolved.cellFocusOutlineStyle.borderRadius, corner);
        expect(resolved.unfocusedCellContainerStyle.borderRadius, corner);
        expect(resolved.valueTextStyle.fontSize, CoreFontSize.s18);
        expect(resolved.valueTextStyle.fontWeight, FontWeight.w600);
        expect(resolved.caretWidth, 2);
        expect(resolved.caretHeight, 20);
        expect(resolved.separatorWidth, 8);
        expect(resolved.separatorThickness, 2);
        expect(
          resolved.errorValidatorHintStyle.iconStyle?.size,
          CoreIconSize.size14,
        );
      }
    });

    testWidgets('md renders 44 × 52 cells in a 52 row, 8 apart, with 18 '
        'semi-bold digits', (tester) async {
      await pumpOtp(
        tester,
        const InputOtp(length: _kOtpLength, initialValue: fullValue),
      );

      expect(cells(), findsNWidgets(_kOtpLength));
      expect(
        tester.getSize(cells().first),
        const Size(CoreSpace.space44, CoreSpace.space52),
      );
      expect(tester.getSize(find.byType(InputOtp)).height, CoreSpace.space52);
      expect(
        tester.getRect(cells().at(1)).left -
            tester.getRect(cells().first).right,
        CoreSpace.space8,
      );
      expect(
        paintedCellCorner(tester),
        const Radius.circular(CoreRadius.radius10),
      );
      expect(paintedStyle(tester, '1').fontSize, CoreFontSize.s18);
      expect(paintedStyle(tester, '1').fontWeight, FontWeight.w600);
    });

    testWidgets('an empty cell is surfaceContainerLow on outlineVariant, a '
        'filled one surface on outline', (tester) async {
      await pumpOtp(
        tester,
        const InputOtp(
          length: _kOtpLength,
          separatorInterval: 0,
          initialValue: [49, null, null, null],
        ),
      );

      final filled = paintedCell(tester, 0);
      final empty = paintedCell(tester, 1);
      expect(
        filled.color,
        resolvedToken(tester, const CoreColor.token(CoreColors.surface)),
      );
      expect(
        filled.border!.top.color,
        resolvedToken(tester, const CoreColor.token(CoreColors.outline)),
      );
      expect(
        empty.color,
        resolvedToken(
          tester,
          const CoreColor.token(CoreColors.surfaceContainerLow),
        ),
      );
      expect(
        empty.border!.top.color,
        resolvedToken(tester, const CoreColor.token(CoreColors.outlineVariant)),
      );
      expect(filled.color, isNot(empty.color));
    });

    testWidgets('the active empty cell draws a 2 × 20 primary caret on an '
        'outline edge — never primary', (tester) async {
      await pumpOtp(
        tester,
        const InputOtp(
          length: _kOtpLength,
          separatorInterval: 0,
          initialValue: [49, null, null, null],
        ),
      );
      expect(caret(tester, primary), findsNothing);

      await tester.tap(find.byType(InputOtp));
      await _settle(tester);

      final mark = caret(tester, primary);
      expect(mark, findsOneWidget);
      expect(tester.getSize(mark), const Size(2, 20));
      // The caret sits in the active cell (index 1, the next empty one),
      // centred.
      final cell = tester.getRect(cells().at(1));
      expect(tester.getCenter(mark).dx, closeTo(cell.center.dx, 0.5));
      expect(tester.getCenter(mark).dy, closeTo(cell.center.dy, 0.5));
      // The active cell keeps the empty fill and takes the neutral `outline`
      // edge — the ring and the caret say "focused", not a coloured border.
      expect(
        paintedCell(tester, 1).border!.top.color,
        resolvedToken(tester, const CoreColor.token(CoreColors.outline)),
      );
      expect(
        paintedCell(tester, 1).color,
        resolvedToken(
          tester,
          const CoreColor.token(CoreColors.surfaceContainerLow),
        ),
      );
      expect(
        paintedCell(tester, 1).border!.top.color,
        isNot(resolvedToken(tester, primary)),
      );
    });

    testWidgets('the error caret is error', (tester) async {
      await pumpOtp(
        tester,
        const InputOtp(length: _kOtpLength, errorText: 'Invalid code'),
      );
      await tester.tap(find.byType(InputOtp));
      await _settle(tester);

      const error = CoreColor.token(CoreColors.error);
      expect(caret(tester, error), findsOneWidget);
      expect(caret(tester, primary), findsNothing);
    });

    testWidgets('a full field shows no caret', (tester) async {
      await pumpOtp(
        tester,
        const InputOtp(length: _kOtpLength, initialValue: fullValue),
      );
      await tester.tap(find.byType(InputOtp));
      await tester.pump();
      expect(caret(tester, primary), findsNothing);
    });

    testWidgets('the separator is an 8 × 2 outline bar with round ends', (
      tester,
    ) async {
      await pumpOtp(
        tester,
        const InputOtp(length: _kOtpLength, initialValue: fullValue),
      );

      expect(
        find.descendant(of: find.byType(InputOtp), matching: find.text('-')),
        findsNothing,
      );
      final outline = resolvedToken(
        tester,
        const CoreColor.token(CoreColors.outline),
      );
      final bar = decoratedContainers((d) => d.color == outline);
      expect(bar, findsOneWidget);
      expect(tester.getSize(bar), const Size(8, 2));
      final radius = tester.widget<Container>(bar).decoration! as BoxDecoration;
      expect(
        radius.borderRadius!.resolve(TextDirection.ltr).topLeft.x,
        greaterThanOrEqualTo(1),
      );
      // Padding 4 either side, so the bar sits 4 + 8 (row gap) from the
      // cells beside it.
      final left = tester.getRect(cells().at(2)).right;
      expect(tester.getRect(bar).left - left, CoreSpace.space8 + 4);
    });

    testWidgets('the hidden dot is 10', (tester) async {
      await pumpOtp(
        tester,
        const InputOtp(
          length: _kOtpLength,
          initialValue: fullValue,
          obscured: true,
        ),
      );

      final dots = decoratedContainers((d) => d.shape == BoxShape.circle);
      expect(dots, findsNWidgets(_kOtpLength));
      expect(
        tester.getSize(dots.first),
        const Size(CoreSize.size10, CoreSize.size10),
      );
    });

    testWidgets('the error line is a ValidatorHint: a 14 circle-alert before '
        'the message, in the error colour', (tester) async {
      await pumpOtp(
        tester,
        const InputOtp(length: _kOtpLength, errorText: 'Invalid code'),
      );

      final hint = find.descendant(
        of: find.byType(InputOtp),
        matching: find.byType(ValidatorHint),
      );
      expect(hint, findsOneWidget);
      final icon = find.descendant(of: hint, matching: find.byType(Icon));
      expect(icon, findsOneWidget);
      expect(tester.widget<Icon>(icon).icon, LucideIcons.circleAlert);
      expect(tester.getSize(icon), const Size(14, 14));
      final message = find.descendant(
        of: hint,
        matching: find.text('Invalid code'),
      );
      expect(
        tester.getRect(icon).right,
        lessThan(tester.getRect(message).left),
      );
      final error = resolvedToken(
        tester,
        const CoreColor.token(CoreColors.error),
      );
      expect(
        tester.renderObject<RenderParagraph>(message).text.style!.color,
        error,
      );
      // Below the row, 4 apart.
      expect(
        tester.getRect(hint).top - tester.getRect(cells().first).bottom,
        CoreSpace.space4,
      );
    });

    testWidgets('lg resolves a 56 × 64 cell and row, a 14 corner on the cell '
        'and its focus ring, a 24 caret, headlineSmall semi-bold digits', (
      tester,
    ) async {
      final resolved = await resolveAt(tester, size: CoreInputOtpSize.lg);

      expect(resolved.cellSize, CoreSize.size56);
      expect(resolved.cellHeight, CoreSize.size64);
      expect(resolved.height, CoreSize.size64);
      expect(resolved.caretHeight, CoreSize.size24);
      expect(resolved.obscuredDotSize, CoreSize.size10);
      // The gap between cells does not vary by size.
      expect(resolved.cellSpacing, CoreSpace.space8);
      const corner = CoreBorderRadius.all(CoreRadius.radius14);
      expect(resolved.cellFocusOutlineStyle.borderRadius, corner);
      expect(resolved.unfocusedCellContainerStyle.borderRadius, corner);
      expect(resolved.filledCellContainerStyle.borderRadius, corner);
      expect(resolved.focusedCellContainerStyle.borderRadius, corner);
      expect(resolved.hoveredCellContainerStyle.borderRadius, corner);
      expect(resolved.valueTextStyle.fontSize, CoreFontSize.s24);
      expect(resolved.valueTextStyle.fontWeight, FontWeight.w600);
      // Colours do not vary by size.
      final md = await resolveAt(tester);
      expect(
        resolved.unfocusedCellContainerStyle.backgroundColor,
        md.unfocusedCellContainerStyle.backgroundColor,
      );
      expect(
        resolved.filledCellContainerStyle.borderColor,
        md.filledCellContainerStyle.borderColor,
      );
    });

    testWidgets('lg renders 56 × 64 cells in a 64 row, 8 apart, and a 2 × 24 '
        'caret', (tester) async {
      await pumpOtp(
        tester,
        const InputOtp(length: _kOtpLength, size: CoreInputOtpSize.lg),
      );

      for (final cell in cells().evaluate()) {
        expect(
          tester.getSize(find.byElementPredicate((e) => e == cell)),
          const Size(CoreSize.size56, CoreSize.size64),
        );
      }
      expect(tester.getSize(find.byType(InputOtp)).height, CoreSize.size64);
      expect(
        paintedCellCorner(tester),
        const Radius.circular(CoreRadius.radius14),
      );
      await tester.tap(find.byType(InputOtp));
      await _settle(tester);
      expect(tester.getSize(caret(tester, primary)), const Size(2, 24));
      // Focus does not move the box.
      expect(
        tester.getSize(cells().first),
        const Size(CoreSize.size56, CoreSize.size64),
      );
    });

    testWidgets('the lg digit sits in the vertical middle of its cell', (
      tester,
    ) async {
      await pumpOtp(
        tester,
        const InputOtp(
          length: _kOtpLength,
          initialValue: fullValue,
          size: CoreInputOtpSize.lg,
        ),
      );

      final cell = tester.getRect(cells().first);
      final glyph = tester.getRect(
        find.descendant(of: find.byType(InputOtp), matching: find.text('1')),
      );
      expect(glyph.top - cell.top, closeTo(cell.bottom - glyph.bottom, 0.5));
      expect(glyph.left - cell.left, closeTo(cell.right - glyph.right, 0.5));
    });

    testWidgets('a per-instance cellSize wins over the lg row', (tester) async {
      await pumpOtp(
        tester,
        const InputOtp(
          length: _kOtpLength,
          size: CoreInputOtpSize.lg,
          inputOtpStyle: CoreInputOtpStyle(
            cellSize: CoreSize.size48,
            cellHeight: CoreSize.size48,
          ),
        ),
      );

      expect(
        tester.getSize(cells().first),
        const Size(CoreSize.size48, CoreSize.size48),
      );
      // The lg corner still applies — only the cell was restated.
      expect(
        paintedCellCorner(tester),
        const Radius.circular(CoreRadius.radius14),
      );
    });

    testWidgets('a theme style wins over the lg row', (tester) async {
      const theme = ThemeData(
        coreComponentTheme: CoreComponentTheme(
          inputOtp: CoreInputOtpTheme(
            style: CoreInputOtpStyle(
              cellSize: CoreSize.size64,
              cellHeight: CoreSize.size64,
              borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
            ),
          ),
        ),
      );
      final resolved = await resolveAt(
        tester,
        size: CoreInputOtpSize.lg,
        theme: theme,
      );
      expect(resolved.cellSize, CoreSize.size64);
      expect(
        resolved.cellFocusOutlineStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius4),
      );
      // Unstated by the theme, the lg digit survives.
      expect(resolved.valueTextStyle.fontSize, CoreFontSize.s24);
    });

    testWidgets('the error variant keeps its error border at lg, empty and '
        'filled', (tester) async {
      await pumpOtp(
        tester,
        const InputOtp(
          length: _kOtpLength,
          size: CoreInputOtpSize.lg,
          initialValue: [49, null, null, null],
          errorText: 'Invalid code',
        ),
      );
      final errorColor = resolvedToken(
        tester,
        const CoreColor.token(CoreColors.error),
      );

      for (var i = 0; i < _kOtpLength; i++) {
        expect(paintedCell(tester, i).border!.top.color, errorColor);
      }
    });

    testWidgets('the error variant wins in every state', (tester) async {
      final resolved = await resolveAt(
        tester,
        size: CoreInputOtpSize.lg,
        hasError: true,
      );
      const error = CoreColor.token(CoreColors.error);
      for (final style in [
        resolved.unfocusedCellContainerStyle,
        resolved.hoveredCellContainerStyle,
        resolved.focusedCellContainerStyle,
        resolved.filledCellContainerStyle,
        resolved.hoveredFilledCellContainerStyle,
        resolved.focusedFilledCellContainerStyle,
      ]) {
        expect(style.borderColor, error);
      }
      expect(resolved.cellFocusOutlineStyle.borderColor, error);
    });

    testWidgets('a colour-only textStyle on lg keeps the 24 semi-bold digit', (
      tester,
    ) async {
      await pumpOtp(
        tester,
        const InputOtp(
          length: _kOtpLength,
          initialValue: fullValue,
          size: CoreInputOtpSize.lg,
          inputOtpStyle: CoreInputOtpStyle(
            textStyle: CoreTextStyle(color: primary),
          ),
        ),
      );

      final digit = paintedStyle(tester, '1');
      expect(digit.fontSize, CoreFontSize.s24);
      expect(digit.fontWeight, FontWeight.w600);
      expect(digit.color, resolvedToken(tester, primary));
    });

    testWidgets('copyWith and the style chain keep the size', (tester) async {
      const lg = InputOtp(length: _kOtpLength, size: CoreInputOtpSize.lg);
      expect(lg.copyWith(length: 6).size, CoreInputOtpSize.lg);
      expect(
        lg.copyWith(size: CoreInputOtpSize.md).size,
        CoreInputOtpSize.md,
      );

      await pumpOtp(
        tester,
        lg.withStyle(const CoreInputOtpStyle(backgroundColor: primary)),
      );
      expect(
        tester.getSize(cells().first),
        const Size(CoreSize.size56, CoreSize.size64),
      );

      // A primitive getter rebuilds through the same `copyWith`.
      await pumpOtp(tester, lg.radius4);
      expect(
        paintedCellCorner(tester),
        const Radius.circular(CoreRadius.radius4),
      );
    });
  });
}
