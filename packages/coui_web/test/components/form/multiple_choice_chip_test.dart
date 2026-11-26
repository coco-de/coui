// The deprecated flat option fields are exercised on purpose: this file
// pins that they still reach the composed chip.
// ignore_for_file: deprecated_member_use

import 'package:coui_web/coui_web.dart';
import 'package:html/dom.dart' as html;
import 'package:jaspr_test/server_test.dart';

// Most cases use `testServer` because only the real SSR binding hands back
// markup. The deprecated-colour case reads actual child components to pin
// public slot forwarding without depending on CSS serialization.
// Together these pin: each option is a composed `Chip`
// (its own Clickable root carrying `role="radio"`, its own body), the
// group draws no option box of its own, and the deprecated flat option
// fields still land on the chip's body.

const List<CoreMultipleChoiceOption<String>> _kOptions = [
  (value: 'a', label: 'Apple'),
  (value: 'b', label: 'Banana'),
];

Component _group({
  String? value,
  bool enabled = true,
  CoreMultipleChoiceStyle? style,
}) => CoUIWeb(
  theme: .coui,
  child: MultipleChoice<String>(
    options: _kOptions,
    value: value,
    enabled: enabled,
    onChanged: (_) {},
    multipleChoiceStyle: style,
  ),
);

List<html.Element> _radios(html.Document? document) =>
    document?.querySelectorAll('[role="radio"]').toList() ?? const [];

/// The chip body — the element the Chip paints its box on.
html.Element? _bodyOf(html.Element radio) =>
    radio.querySelector('.co-chip-body') ??
    (radio.className.contains('co-chip-body') ? radio : null);

void main() {
  group('MultipleChoice DOM', () {
    testServer('every option is a composed Chip', (tester) async {
      tester.pumpComponent(_group(value: 'b'));
      final response = await tester.request('/');
      final radios = _radios(response.document);

      expect(radios, hasLength(2));
      expect(radios[0].attributes['aria-checked'], 'false');
      expect(radios[1].attributes['aria-checked'], 'true');
      for (final radio in radios) {
        expect(_bodyOf(radio), isNotNull, reason: 'a Chip body per option');
      }
      expect(radios[0].text, contains('Apple'));
      expect(radios[1].text, contains('Banana'));
      // The group is the row; it draws no per-option box of its own.
      expect(
        response.document?.querySelector('[role="radiogroup"]'),
        isNotNull,
      );
    });

    testServer('the options sit 8 apart and are 32 tall', (tester) async {
      tester.pumpComponent(_group());
      final response = await tester.request('/');
      final group = response.document?.querySelector('[role="radiogroup"]');
      expect(group?.attributes['style'], contains('gap'));
      expect(group?.attributes['style'], contains('--coui-space-8'));
      final body = _bodyOf(_radios(response.document).first);
      expect(body?.attributes['style'], contains('min-height'));
      expect(body?.attributes['style'], contains('min-height: 2.0rem'));
    });

    testServer('a selected option wears the primary chip, a resting one '
        'does not', (tester) async {
      tester.pumpComponent(_group(value: 'b'));
      final response = await tester.request('/');
      final radios = _radios(response.document);
      final resting = _bodyOf(radios[0])?.className ?? '';
      final selected = _bodyOf(radios[1])?.className ?? '';

      expect(selected, isNot(resting));
      // Emphasis=low: 선택 칩은 solid primary 가 아니라 primaryContainer.
      expect(selected, contains('bg-primary-container'));
      expect(selected.split(' '), isNot(contains('bg-primary')));
      expect(resting, isNot(contains('bg-primary')));
    });

    testServer('a resting option wears the neutral · low chip', (tester) async {
      expect(CoreChipColor.defaultColor, CoreChipColor.neutral);
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: Component.fragment([
            MultipleChoice<String>(
              options: _kOptions,
              value: 'b',
              onChanged: (_) {},
            ),
            Chip(
              label: 'Ref',
              emphasis: CoreChipEmphasis.low,
              onTap: () {},
            ),
          ]),
        ),
      );
      final response = await tester.request('/');
      final bodies =
          response.document?.querySelectorAll('.co-chip-body').toList() ??
          const <html.Element>[];
      expect(bodies, hasLength(3));
      // Same chrome classes as the standalone neutral · outlined · low chip.
      expect(bodies[0].className, bodies[2].className);
    });

    testServer('a disabled group disables its chips', (tester) async {
      tester.pumpComponent(_group(enabled: false));
      final response = await tester.request('/');
      for (final radio in _radios(response.document)) {
        expect(radio.attributes['aria-disabled'], 'true');
      }
    });

    testServer('chipStyle lands on the chip body', (tester) async {
      tester.pumpComponent(
        _group(
          style: const CoreMultipleChoiceStyle(
            chipStyle: CoreChipStyle(
              backgroundColor: CoreColor(0xFF123456),
            ),
          ),
        ),
      );
      final response = await tester.request('/');
      final body = _bodyOf(_radios(response.document).first);
      expect(body?.attributes['style'], contains('background-color'));
    });

    testComponents('deprecated flat fields reach the selected and resting '
        'Chip styles', (
      tester,
    ) async {
      tester.pumpComponent(
        _group(
          value: 'a',
          style: const CoreMultipleChoiceStyle(
            selectedBackgroundColor: CoreColor(0xFFAA0000),
            unselectedBackgroundColor: CoreColor(0xFF00AA00),
          ),
        ),
      );
      final chips = find
          .byType(Chip)
          .evaluate()
          .map((element) => element.component as Chip)
          .toList();
      expect(chips, hasLength(2));
      expect(chips.map((chip) => chip.selected), [true, false]);
      expect(
        chips[0].chipStyle?.backgroundColor,
        const CoreColor(0xFFAA0000),
      );
      expect(
        chips[1].chipStyle?.backgroundColor,
        const CoreColor(0xFF00AA00),
      );
    });
  });
}
