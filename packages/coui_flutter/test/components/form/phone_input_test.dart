import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// Phone input test constants.
const _kTestNumber = '5551234567';
const _kTestEmptyNumber = '';
// Canada as a `const CoreCountry` literal — `CoreCountry` is a value class
// (not the old `phonecodes` enum), so a non-default country needs either a
// const literal like this or `CoreCountry.byCode('CA')` (runtime lookup).
const _kCanada = CoreCountry(code: 'CA', dialCode: '+1', name: 'Canada');

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  group('PhoneNumber', () {
    group('constructor', () {
      test('creates with country and number', () {
        const phone = PhoneNumber(.unitedStates, _kTestNumber);

        expect(phone.country, equals(CoreCountry.unitedStates));
        expect(phone.number, equals(_kTestNumber));
      });

      test('creates with empty number', () {
        const phone = PhoneNumber(.unitedStates, _kTestEmptyNumber);

        expect(phone.number, equals(_kTestEmptyNumber));
      });
    });

    group('fullNumber getter', () {
      test('returns dialCode + number', () {
        const phone = PhoneNumber(.unitedStates, _kTestNumber);

        expect(
          phone.fullNumber,
          equals('${CoreCountry.unitedStates.dialCode}$_kTestNumber'),
        );
      });
    });

    group('value getter', () {
      test('returns null when number is empty', () {
        const phone = PhoneNumber(.unitedStates, _kTestEmptyNumber);

        expect(phone.value, isNull);
      });

      test('returns fullNumber when number is non-empty', () {
        const phone = PhoneNumber(.unitedStates, _kTestNumber);

        expect(phone.value, equals(phone.fullNumber));
      });
    });

    group('toString', () {
      test('returns empty string when number is empty', () {
        const phone = PhoneNumber(.unitedStates, _kTestEmptyNumber);

        expect(phone.toString(), equals(''));
      });

      test('returns fullNumber when number is non-empty', () {
        const phone = PhoneNumber(.unitedStates, _kTestNumber);

        expect(phone.toString(), equals(phone.fullNumber));
      });
    });

    group('equality', () {
      test('two identical PhoneNumbers are equal', () {
        const phone1 = PhoneNumber(.unitedStates, _kTestNumber);
        const phone2 = PhoneNumber(.unitedStates, _kTestNumber);

        expect(phone1, equals(phone2));
      });

      test('different country makes PhoneNumbers unequal', () {
        const phone1 = PhoneNumber(.unitedStates, _kTestNumber);
        const phone2 = PhoneNumber(_kCanada, _kTestNumber);

        expect(phone1, isNot(equals(phone2)));
      });

      test('different number makes PhoneNumbers unequal', () {
        const phone1 = PhoneNumber(.unitedStates, _kTestNumber);
        const phone2 = PhoneNumber(.unitedStates, '9998887777');

        expect(phone1, isNot(equals(phone2)));
      });

      test('empty vs non-empty number makes PhoneNumbers unequal', () {
        const phone1 = PhoneNumber(.unitedStates, _kTestEmptyNumber);
        const phone2 = PhoneNumber(.unitedStates, _kTestNumber);

        expect(phone1, isNot(equals(phone2)));
      });
    });

    group('hashCode', () {
      test('identical instances have same hashCode', () {
        const phone1 = PhoneNumber(.unitedStates, _kTestNumber);
        const phone2 = PhoneNumber(.unitedStates, _kTestNumber);

        expect(phone1.hashCode, equals(phone2.hashCode));
      });
    });
  });

  group('PhoneInput widget', () {
    testWidgets('renders with key parameter', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const PhoneInput(key: Key('phone_input')),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byKey(const Key('phone_input')), findsOneWidget);
    });

    testWidgets('renders with default country (United States)', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const PhoneInput(),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(PhoneInput), findsOneWidget);
    });

    testWidgets('renders with specified initialCountry', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const PhoneInput(initialCountry: _kCanada),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(PhoneInput), findsOneWidget);
    });

    testWidgets('renders with initialValue', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const PhoneInput(
            initialValue: PhoneNumber(.unitedStates, _kTestNumber),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(PhoneInput), findsOneWidget);
    });

    testWidgets('renders with onChanged callback', (tester) async {
      PhoneNumber? changedValue;

      await tester.pumpWidget(
        _buildApp(
          PhoneInput(
            onChanged: (phone) => changedValue = phone,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      // Verify the widget renders (flag asset errors are expected in test env).
      expect(find.byType(PhoneInput), findsOneWidget);
      // changedValue is null until user interacts.
      expect(changedValue, isNull);
    });

    testWidgets('renders with custom controller', (tester) async {
      final controller = material.TextEditingController();

      await tester.pumpWidget(
        _buildApp(
          PhoneInput(controller: controller),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(PhoneInput), findsOneWidget);

      controller.dispose();
    });

    testWidgets('renders with filterPlusCode false', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const PhoneInput(filterPlusCode: false),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(PhoneInput), findsOneWidget);
    });

    testWidgets('renders with limited country list', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const PhoneInput(
            countries: [.unitedStates, _kCanada],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(PhoneInput), findsOneWidget);
    });

    testWidgets(
      'outer container border switches to the focus colour when the '
      'number field is focused (single focus boundary, no clipped ring)',
      (tester) async {
        await tester.pumpWidget(_buildApp(const PhoneInput()));
        final _ = await tester.pumpAndSettle();

        // The decorated outer container is the DecoratedBox that carries the
        // border — read its border-top colour before / after focusing.
        Color borderColor() {
          final decoration = tester
              .widgetList<Container>(find.byType(Container))
              .map((c) => c.decoration)
              .whereType<BoxDecoration>()
              .firstWhere((d) => d.border != null);
          return (decoration.border! as Border).top.color;
        }

        final resolved = resolvePhoneInput(
          tester.element(find.byType(PhoneInput)),
        );
        final idle = borderColor();
        expect(idle, equals(resolved.borderColor));

        await tester.tap(find.byType(EditableText).first);
        final _ = await tester.pumpAndSettle();

        expect(borderColor(), equals(resolved.focusBorderColor));
        expect(borderColor(), isNot(equals(idle)));
      },
    );

    testWidgets(
      'opening the country picker renders the list without crashing '
      '(Popover anchorFixedSize gives the ListView a definite width)',
      (tester) async {
        await tester.pumpWidget(_buildApp(const PhoneInput()));
        await tester.pump(const Duration(milliseconds: 100));

        // Tap the country selector trigger to open the popover.
        await tester.tap(
          find.byType(GestureDetector).first,
          warnIfMissed: false,
        );
        for (var i = 0; i < 12; i += 1) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // No `hasSize` / IntrinsicWidth assertion (the freeze), the search
        // field is mounted, and country rows populate the list.
        expect(tester.takeException(), isNull);
        expect(find.byType(EditableText), findsNWidgets(2));
        final rows = find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_CountryPickerItem',
        );
        expect(rows, findsWidgets);
      },
    );
  });

  // Typing detection is `+`-triggered and never overrides on an ambiguous
  // match — the decision lives in `CorePhoneCountryDetector` so both
  // platforms read the same match; these pin that the Flutter widget is
  // actually wired to it (the Web twin has the mirrored group).
  // #6471: a phone input that names no country starts on South Korea —
  // the trigger reads its dial code and a typed number is reported in it.
  group('PhoneInput default country (#6471)', () {
    testWidgets('the trigger shows +82 and the value is in KR', (
      tester,
    ) async {
      PhoneNumber? changed;
      await tester.pumpWidget(
        _buildApp(PhoneInput(onChanged: (phone) => changed = phone)),
      );
      expect(find.text('+82'), findsOneWidget);
      expect(find.text('+1'), findsNothing);

      await tester.enterText(find.byType(EditableText), '1012345678');
      await tester.pump();
      expect(changed?.country, CorePhoneInputContract.defaultInitialCountry);
      expect(changed?.country.code, 'KR');
      expect(changed?.fullNumber, '+821012345678');
    });

    testWidgets('an explicit initialCountry still wins', (tester) async {
      await tester.pumpWidget(
        _buildApp(const PhoneInput(initialCountry: CoreCountry.unitedStates)),
      );
      expect(find.text('+1'), findsOneWidget);
      expect(find.text('+82'), findsNothing);
    });
  });

  group('PhoneInput typing country detection', () {
    Future<CoreCountry?> countryAfterTyping(
      WidgetTester tester,
      String text, {
      CoreCountry? initialCountry,
    }) async {
      PhoneNumber? changed;
      await tester.pumpWidget(
        _buildApp(
          PhoneInput(
            initialCountry: initialCountry,
            onChanged: (phone) => changed = phone,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).first, text);
      final _ = await tester.pumpAndSettle();

      return changed?.country;
    }

    testWidgets('a unique dial code switches the country (+82 -> KR)', (
      tester,
    ) async {
      expect(
        (await countryAfterTyping(
          tester,
          '+821012345678',
          initialCountry: CoreCountry.unitedStates,
        ))?.code,
        'KR',
      );
    });

    testWidgets('digits without a leading + keep the current country', (
      tester,
    ) async {
      expect(
        (await countryAfterTyping(
          tester,
          '821012345678',
          initialCountry: CoreCountry.unitedStates,
        ))?.code,
        CoreCountry.unitedStates.code,
      );
    });

    testWidgets('an ambiguous dial code keeps the current country (+1)', (
      tester,
    ) async {
      expect(
        (await countryAfterTyping(
          tester,
          '+15551234567',
          initialCountry: _kCanada,
        ))?.code,
        _kCanada.code,
      );
    });

    testWidgets('a partial dial code keeps the current country (+8)', (
      tester,
    ) async {
      expect(
        (await countryAfterTyping(
          tester,
          '+8',
          initialCountry: CoreCountry.unitedStates,
        ))?.code,
        CoreCountry.unitedStates.code,
      );
    });
  });

  // The outer box owns the one border. While the pointer is over it the
  // border steps to `onSurface`; `disabled > focus > hover > rest`.
  group('PhoneInput hover border', () {
    // The decorated outer box — the first `Container` whose decoration
    // carries a border (the inner number field is chromeless).
    // Centred, so `Offset.zero` is genuinely outside the box.
    Widget app(Widget child) => _buildApp(material.Center(child: child));

    Color outerBorder(WidgetTester tester) {
      final decoration = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.border != null);
      return (decoration.border! as Border).top.color;
    }

    Color schemeColor(WidgetTester tester, CoreColor color) => Theme.of(
      tester.element(find.byType(PhoneInput)),
    ).colorScheme.resolve(color).toValue();

    Future<TestGesture> mouse(WidgetTester tester) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      return gesture;
    }

    testWidgets(
      'the resolver states a hover border apart from rest and focus',
      (
        tester,
      ) async {
        await tester.pumpWidget(app(const PhoneInput()));
        final _ = await tester.pumpAndSettle();
        final context = tester.element(find.byType(PhoneInput));

        final resolved = resolvePhoneInput(context);
        expect(
          resolved.borderColor,
          schemeColor(tester, CorePhoneInputStyle.defaultBorderColor),
        );
        expect(
          resolved.hoverBorderColor,
          schemeColor(tester, CorePhoneInputStyle.defaultHoverBorderColor),
        );
        expect(resolved.hoverBorderColor, isNot(resolved.borderColor));
        expect(resolved.hoverBorderColor, isNot(resolved.focusBorderColor));

        const raw = CoreColor(0xFF00FF00);
        expect(
          resolvePhoneInput(
            context,
            phoneInputStyle: const CorePhoneInputStyle(hoverBorderColor: raw),
          ).hoverBorderColor,
          raw.toValue(),
        );
      },
    );

    testWidgets(
      'a pointer over the box steps the border, leaving restores it',
      (
        tester,
      ) async {
        await tester.pumpWidget(app(const PhoneInput()));
        final _ = await tester.pumpAndSettle();
        final resolved = resolvePhoneInput(
          tester.element(find.byType(PhoneInput)),
        );
        expect(outerBorder(tester), resolved.borderColor);

        final gesture = await mouse(tester);
        await gesture.moveTo(tester.getCenter(find.byType(PhoneInput)));
        await tester.pump();
        expect(outerBorder(tester), resolved.hoverBorderColor);

        await gesture.moveTo(Offset.zero);
        await tester.pump();
        expect(outerBorder(tester), resolved.borderColor);
      },
    );

    testWidgets('hovering the country selector also hovers the box', (
      tester,
    ) async {
      await tester.pumpWidget(app(const PhoneInput()));
      final _ = await tester.pumpAndSettle();
      final resolved = resolvePhoneInput(
        tester.element(find.byType(PhoneInput)),
      );

      // The selector is a child of the box — the box's border follows the
      // pointer over it, not just over the number field.
      final gesture = await mouse(tester);
      final selector = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_CountrySelectorTrigger',
      );
      expect(selector, findsOneWidget);
      await gesture.moveTo(tester.getCenter(selector));
      await tester.pump();
      expect(outerBorder(tester), resolved.hoverBorderColor);
    });

    testWidgets('a focused field keeps its focus border under a pointer', (
      tester,
    ) async {
      await tester.pumpWidget(app(const PhoneInput()));
      final _ = await tester.pumpAndSettle();
      final resolved = resolvePhoneInput(
        tester.element(find.byType(PhoneInput)),
      );

      // Focus the number field with the mouse, which then stays over the box.
      final gesture = await mouse(tester);
      final field = tester.getCenter(find.byType(EditableText).first);
      await gesture.moveTo(field);
      await tester.pump();
      expect(outerBorder(tester), resolved.hoverBorderColor);

      await gesture.down(field);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        outerBorder(tester),
        resolved.focusBorderColor,
        reason: 'hover must never override the focus border',
      );
      expect(outerBorder(tester), isNot(resolved.hoverBorderColor));
    });

    testWidgets('a disabled field takes no hover step', (tester) async {
      await tester.pumpWidget(app(const PhoneInput(enabled: false)));
      final _ = await tester.pumpAndSettle();
      final resolved = resolvePhoneInput(
        tester.element(find.byType(PhoneInput)),
        enabled: false,
      );

      final gesture = await mouse(tester);
      await gesture.moveTo(tester.getCenter(find.byType(PhoneInput)));
      await tester.pump();

      expect(outerBorder(tester), resolved.borderColor);
      expect(outerBorder(tester), isNot(resolved.hoverBorderColor));
    });

    testWidgets('a hoverBorderColor override reaches the painted border', (
      tester,
    ) async {
      const raw = CoreColor(0xFF00FF00);
      await tester.pumpWidget(
        app(
          const PhoneInput(
            phoneInputStyle: CorePhoneInputStyle(hoverBorderColor: raw),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final gesture = await mouse(tester);
      await gesture.moveTo(tester.getCenter(find.byType(PhoneInput)));
      await tester.pump();

      expect(outerBorder(tester), raw.toValue());
    });

    // A zero-width Flutter border is a hairline, not nothing. The number field
    // is a composed `TextField`, and a `TextField` takes an `onSurface`
    // border while hovered — unless the chromeless style silences it, a second
    // line would be drawn inside the box's one boundary.
    testWidgets(
      'the chromeless inner field paints no hover border of its own',
      (
        tester,
      ) async {
        await tester.pumpWidget(app(const PhoneInput()));
        final _ = await tester.pumpAndSettle();

        final gesture = await mouse(tester);
        await gesture.moveTo(tester.getCenter(find.byType(EditableText).first));
        await tester.pump();

        // Every border-carrying box inside the number field is transparent.
        final inner = find.descendant(
          of: find.byType(TextField),
          matching: find.byType(DecoratedBox),
        );
        expect(inner, findsWidgets);
        for (final box in tester.widgetList<DecoratedBox>(inner)) {
          final decoration = box.decoration;
          if (decoration is! BoxDecoration) continue;
          final border = decoration.border;
          if (border is Border) {
            expect(
              border.top.color.a,
              0,
              reason: 'the inner field must not draw a border while hovered',
            );
          }
        }
      },
    );
  });

  group('PhoneInput redesign (#5831)', () {
    Finder iconNamed(IconName name) => find.byWidgetPredicate(
      (widget) => widget is Icon && widget.icon == name,
    );

    testWidgets('the box is the lg row with corner 12, quiet edge and the '
        'disabled tokens', (tester) async {
      await tester.pumpWidget(_buildApp(const PhoneInput()));
      final _ = await tester.pumpAndSettle();
      final context = tester.element(find.byType(PhoneInput));
      final scheme = Theme.of(context).colorScheme;
      final enabled = resolvePhoneInput(context);
      final disabled = resolvePhoneInput(context, enabled: false);

      expect(enabled.height, CoreControlSize.heightLg);
      expect(
        enabled.borderRadius,
        BorderRadius.circular(CoreRadiusRole.panel),
      );
      expect(
        enabled.borderColor,
        scheme.resolve(CorePhoneInputStyle.defaultBorderColor).toValue(),
      );
      expect(
        enabled.hoverBorderColor,
        scheme.resolve(CorePhoneInputStyle.defaultHoverBorderColor).toValue(),
      );
      expect(
        disabled.backgroundColor,
        scheme
            .resolve(CorePhoneInputStyle.defaultDisabledBackgroundColor)
            .toValue(),
      );
      expect(
        disabled.borderColor,
        scheme
            .resolve(CorePhoneInputStyle.defaultDisabledBorderColor)
            .toValue(),
      );
    });

    testWidgets('the flag is 14 high with the part corner; the hairline is '
        '20 high; the selector insets 14 / 10', (tester) async {
      await tester.pumpWidget(_buildApp(const PhoneInput()));
      final _ = await tester.pumpAndSettle();
      final resolved = resolvePhoneInput(
        tester.element(find.byType(PhoneInput)),
      );

      expect(resolved.flagSize, CoreSize.size14);
      // The country list draws the flag at the selector's step.
      expect(resolved.dropdownFlagSize, CoreSize.size14);
      expect(
        resolved.flagBorderRadius,
        BorderRadius.circular(CoreRadiusRole.part),
      );
      expect(resolved.separatorHeight, CoreSize.size20);
      expect(
        resolved.selectorPadding,
        const EdgeInsetsDirectional.only(
          start: CoreSpace.space14,
          end: CoreSpace.space10,
        ),
      );
    });

    testWidgets('the number field insets 12 at the start and 12 at the end, '
        'by reading order', (tester) async {
      await tester.pumpWidget(_buildApp(const PhoneInput()));
      final _ = await tester.pumpAndSettle();
      final resolved = resolvePhoneInput(
        tester.element(find.byType(PhoneInput)),
      );

      expect(
        resolved.inputFieldPadding,
        const EdgeInsetsDirectional.only(
          start: CoreSpace.space12,
          end: CoreSpace.space12,
        ),
      );
    });

    testWidgets('the country panel is the item picker panel: bare search '
        'with a glyph, a divider, rows of 8 with corner 8, the check in '
        'primary', (tester) async {
      await tester.pumpWidget(_buildApp(const PhoneInput()));
      final _ = await tester.pumpAndSettle();
      final resolved = resolvePhoneInput(
        tester.element(find.byType(PhoneInput)),
      );

      expect(
        resolved.popoverStyle.panelStyle?.borderColor,
        CoreItemPickerStyle.defaultBorderColor,
      );
      expect(resolved.popoverStyle.panelStyle?.padding, CoreEdgeInsets.zero);
      expect(
        resolved.dropdownListPadding,
        const EdgeInsets.all(CoreSpace.space6),
      );
      expect(
        resolved.dropdownItemPadding,
        const EdgeInsets.all(CoreSpace.space8),
      );
      expect(
        resolved.dropdownItemBorderRadius,
        BorderRadius.circular(CoreRadiusRole.control),
      );
      expect(
        resolved.dropdownCheckIconStyle.color,
        const CoreColor.token(CoreColors.primary),
      );

      await tester.tap(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_CountrySelectorTrigger',
        ),
      );
      // The search field autofocuses and its caret blinks, so the tree
      // never settles — pump the open animation instead.
      await tester.pump(const Duration(seconds: 1));

      final searches = tester
          .widgetList<TextField>(find.byType(TextField))
          .where((field) => field.variant == CoreTextFieldVariant.plain);
      expect(searches, hasLength(1));
      expect(iconNamed(LucideIcons.search), findsOneWidget);
      expect(find.byType(Divider), findsWidgets);
    });
  });
}
