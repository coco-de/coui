// Narrow imports (not the `coui_web.dart` barrel) so this file compiles the
// phone-input graph only.
import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/display/divider/divider.dart';
import 'package:coui_web/src/components/form/form/form.dart';
import 'package:coui_web/src/components/form/form/form_controller.dart';
import 'package:coui_web/src/components/form/form_field/form_field.dart';
import 'package:coui_web/src/components/form/phone_input/phone_input.dart';
import 'package:coui_web/src/components/form/text_field/text_field.dart';
import 'package:jaspr/dom.dart' show RawText;
import 'package:jaspr/jaspr.dart' show DomComponent;
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kCanada = CoreCountry(code: 'CA', dialCode: '+1', name: 'Canada');

/// The vector table coui_core owns; the Flutter and Web `Icon` tests read the
/// same file.
const _kIconStrokeVectorsPath =
    '../coui_core/test/fixtures/icon_stroke_vectors.json';

/// Renders [input] inside a `Form` and returns the value it reports.
///
/// Reading through the form controller is what proves the parameter reached
/// behaviour: a declared-but-unread flag leaves this value unchanged.
Future<PhoneInputValue?> _reportedValue(
  ComponentTester tester,
  PhoneInput input,
) async {
  final controller = FormController();
  const key = FormKey<PhoneInputValue>('phone');

  pumpWithTheme(
    tester,
    Form(
      controller: controller,
      children: [
        FormField(label: 'Phone', formKey: key, child: input),
      ],
    ),
  );
  await tester.pump();

  return controller.getValue(key);
}

void main() {
  group('Web PhoneInput initialValue', () {
    testComponents('seeds both the country and the number', (tester) async {
      final value = await _reportedValue(
        tester,
        const PhoneInput(
          initialValue: PhoneInputValue(CoreCountry.southKorea, '1012345678'),
        ),
      );

      expect(value?.country, CoreCountry.southKorea);
      expect(value?.number, '1012345678');
      expect(value?.fullNumber, '+821012345678');
    });

    testComponents('outranks initialCountry and initialNumber', (tester) async {
      final value = await _reportedValue(
        tester,
        const PhoneInput(
          initialValue: PhoneInputValue(CoreCountry.southKorea, '1012345678'),
          initialCountry: _kCanada,
          initialNumber: '5551234',
        ),
      );

      expect(value?.country, CoreCountry.southKorea);
      expect(value?.number, '1012345678');
    });

    testComponents('renders the seeded dial code in the selector', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const PhoneInput(
          initialValue: PhoneInputValue(CoreCountry.southKorea, '1012345678'),
        ),
      );
      await tester.pump();

      expect(find.text('+82'), findsOneComponent);
    });
  });

  group('Web PhoneInput input filters', () {
    testComponents('a leading trunk zero is carried through', (tester) async {
      // Stripping it used to be unconditional, which corrupts every country
      // whose trunk 0 belongs to the national number (Italy).
      final value = await _reportedValue(
        tester,
        const PhoneInput(
          initialCountry: CoreCountry.southKorea,
          initialNumber: '01012345678',
        ),
      );

      expect(value?.number, '01012345678');
    });

    testComponents('a plus-less dial code is carried through', (tester) async {
      // Matching it by prefix meant any number merely starting with those
      // digits lost them — for `+1`, every US number beginning with 1.
      final value = await _reportedValue(
        tester,
        const PhoneInput(
          initialCountry: CoreCountry.southKorea,
          initialNumber: '821012345678',
        ),
      );

      expect(value?.number, '821012345678');
    });

    testComponents('filterPlusCode drops a leading +dialCode', (tester) async {
      final value = await _reportedValue(
        tester,
        const PhoneInput(
          initialCountry: CoreCountry.southKorea,
          initialNumber: '+821012345678',
        ),
      );

      expect(value?.number, '1012345678');
    });

    testComponents('filterPlusCode: false keeps the plus form', (tester) async {
      final value = await _reportedValue(
        tester,
        const PhoneInput(
          initialCountry: CoreCountry.southKorea,
          initialNumber: '+821012345678',
          filterPlusCode: false,
        ),
      );

      expect(value?.number, '+821012345678');
    });
  });

  // Mirror of the Flutter widget's detection group — both read the same
  // `CorePhoneCountryDetector`, so these pin that the Web side is actually
  // wired to it rather than carrying a hand-copied match of its own.
  // #6471: a phone input that names no country starts on South Korea —
  // the trigger reads its dial code and the form value is in it.
  group('Web PhoneInput default country (#6471)', () {
    testComponents('the trigger shows +82 and the value is in KR', (
      tester,
    ) async {
      final controller = FormController();
      const key = FormKey<PhoneInputValue>('phone');
      pumpWithTheme(
        tester,
        Form(
          controller: controller,
          children: const [
            FormField(
              label: 'Phone',
              formKey: key,
              child: PhoneInput(),
            ),
          ],
        ),
      );
      await tester.pump();
      expect(find.text('+82'), findsOneComponent);
      expect(find.text('+1'), findsNothing);

      final field =
          find.byType(TextField).evaluate().single.component as TextField;
      field.onChanged!('1012345678');
      await tester.pump();
      final value = controller.getValue(key);
      expect(value?.country, CorePhoneInputContract.defaultInitialCountry);
      expect(value?.country.code, 'KR');
      expect(value?.fullNumber, '+821012345678');
    });

    testComponents('an explicit initialCountry still wins', (tester) async {
      pumpWithTheme(
        tester,
        const PhoneInput(initialCountry: CoreCountry.unitedStates),
      );
      await tester.pump();
      expect(find.text('+1'), findsOneComponent);
      expect(find.text('+82'), findsNothing);
    });
  });

  group('Web PhoneInput typing country detection', () {
    Future<CoreCountry?> countryAfterTyping(
      ComponentTester tester,
      String text, {
      CoreCountry? initialCountry,
    }) async {
      final controller = FormController();
      const key = FormKey<PhoneInputValue>('phone');

      pumpWithTheme(
        tester,
        Form(
          controller: controller,
          children: [
            FormField(
              label: 'Phone',
              formKey: key,
              child: PhoneInput(initialCountry: initialCountry),
            ),
          ],
        ),
      );
      await tester.pump();

      // The typist edits the composed field, so detection is reached the way
      // it is in the browser — through the number field's change callback.
      final field =
          find.byType(TextField).evaluate().single.component as TextField;
      field.onChanged!(text);
      await tester.pump();

      return controller.getValue(key)?.country;
    }

    testComponents('a unique dial code switches the country (+82 -> KR)', (
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

    testComponents('digits without a leading + keep the current country', (
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

    testComponents('an ambiguous dial code keeps the current country (+1)', (
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

    testComponents('a partial dial code keeps the current country (+8)', (
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

  group('Web PhoneInput chevron stroke', () {
    testComponents(
      'the <svg> carries the rule weight in its style, not as an attribute',
      (tester) async {
        pumpWithTheme(tester, const PhoneInput());
        await tester.pump();

        // The chevron is the only inline <svg> with a polyline child — flags
        // are background images and the fields draw no glyph.
        final chevrons = find
            .tag('svg')
            .evaluate()
            .map((e) => e.component as DomComponent)
            .where(
              (svg) =>
                  svg.children?.whereType<DomComponent>().any(
                    (c) => c.tag == 'polyline',
                  ) ??
                  false,
            )
            .toList();
        expect(chevrons, hasLength(1));
        final chevron = chevrons.single;

        final fixture =
            jsonDecode(File(_kIconStrokeVectorsPath).readAsStringSync())
                as Map<String, Object?>;
        final size = CorePhoneInputStyle.defaultChevronIconStyle.size!;
        final row = (fixture['cases']! as List)
            .cast<Map<String, Object?>>()
            .singleWhere((c) => (c['tokenSize']! as num).toDouble() == size);

        // One source for the weight: the resolver's inline CSS. A literal
        // `stroke-width="2"` attribute on the root would be the Iconify
        // default the Flutter twin no longer draws.
        expect(chevron.attributes?.containsKey('stroke-width'), isFalse);
        expect(chevron.styles?.properties['stroke-width'], row['svgString']);
        // The weight is in the glyph's own units, so it is only right while
        // the root draws on the grid the resolver divides by.
        expect(
          chevron.attributes?['viewBox'],
          '0 0 ${fixture['viewBox']} '
          '${fixture['viewBox']}',
        );
      },
    );
  });

  // The rendered box — what the browser actually sees — carries the resolver's
  // hover border. The unit assertions on the resolver cannot catch a widget
  // that stops applying `resolved.root.className` or stops rendering the
  // scoped `<style>`.
  group('Web PhoneInput hover border (rendered)', () {
    const guardedHover = '[&:hover:not(:focus-within)]:border-outline';

    // The bordered row: the only element that carries the focus-within border.
    DomComponent box(ComponentTester tester) => find
        .tag('div')
        .evaluate()
        .map((e) => e.component as DomComponent)
        .firstWhere((d) => (d.classes ?? '').contains('focus-within:border-'));

    testComponents('the box renders the guarded hover class, no <style>', (
      tester,
    ) async {
      pumpWithTheme(tester, const PhoneInput());
      await tester.pump();

      final classes = (box(tester).classes ?? '').split(' ');
      expect(classes, contains('border-outline-variant'));
      expect(classes, contains(guardedHover));
      expect(classes.any((c) => c.startsWith('hover:border-')), isFalse);
      expect(find.tag('style'), findsNothing);
    });

    testComponents('a raw hover border renders its scope class and rule', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const PhoneInput(
          phoneInputStyle: CorePhoneInputStyle(
            hoverBorderColor: CoreColor(0xFF00FF00),
          ),
        ),
      );
      await tester.pump();

      final classes = (box(tester).classes ?? '').split(' ');
      expect(classes.any((c) => c.startsWith('co-phone-input-hb-')), isTrue);
      expect(classes, isNot(contains(guardedHover)));
      expect(find.tag('style'), findsOneComponent);
      final style =
          find.tag('style').evaluate().single.component as DomComponent;
      final scope = classes.firstWhere(
        (c) => c.startsWith('co-phone-input-hb-'),
      );
      // The selector and the element have to agree — a rule that names a
      // class nothing carries paints nothing, and it looks fine in the
      // resolver test.
      expect(
        (style.children?.first as RawText?)?.text,
        '.$scope:hover:not(:focus-within){border-color: rgb(0, 255, 0);}',
      );
    });

    testComponents('a disabled field renders no hover border', (tester) async {
      pumpWithTheme(
        tester,
        const PhoneInput(
          enabled: false,
          phoneInputStyle: CorePhoneInputStyle(
            hoverBorderColor: CoreColor(0xFF00FF00),
          ),
        ),
      );
      await tester.pump();

      final classes = (box(tester).classes ?? '').split(' ');
      expect(classes, isNot(contains(guardedHover)));
      expect(classes.any((c) => c.startsWith('co-phone-input-hb-')), isFalse);
      expect(find.tag('style'), findsNothing);
    });
  });

  group('Web PhoneInput redesign (#5831) (rendered)', () {
    testComponents('the selector and the number are parted by a composed '
        'vertical Divider, not a border on the selector', (tester) async {
      pumpWithTheme(tester, const PhoneInput());
      await tester.pump();

      final dividers = find.byType(Divider).evaluate();
      expect(dividers, hasLength(1));
      expect(
        (dividers.single.component as Divider).orientation,
        CoreDividerOrientation.vertical,
      );
      final selector = find
          .tag('button')
          .evaluate()
          .map((e) => e.component as DomComponent)
          .first;
      expect(selector.classes ?? '', isNot(contains('border-r')));
    });
  });
}
