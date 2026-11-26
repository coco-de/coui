import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  testComponents('raw placeholder color reaches the single native input', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      const FormattedInput.phone(
        id: 'raw-placeholder',
        formattedInputStyle: CoreFormattedInputStyle(
          segmentInputStyle: CoreTextFieldStyle(
            placeholderStyle: CoreTextStyle(color: CoreColor(0xFF123456)),
          ),
        ),
      ),
    );
    final input = find.tag('input').evaluate().single.component as DomComponent;
    expect(input.classes, isNot(contains('placeholder:text-placeholder')));
    final style = find.tag('style').evaluate().single.component as DomComponent;
    final css = (style.children!.single as RawText).text;
    expect(css, contains('#${input.id}::placeholder'));
    expect(css, contains('rgb(18, 52, 86)'));
  });

  testComponents('disabled state keeps an explicitly stated raw color', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      const FormattedInput.phone(
        enabled: false,
        id: 'disabled-placeholder',
        formattedInputStyle: CoreFormattedInputStyle(
          segmentInputStyle: CoreTextFieldStyle(
            placeholderStyle: CoreTextStyle(color: CoreColor(0x80123456)),
          ),
        ),
      ),
    );
    final input = find.tag('input').evaluate().single.component as DomComponent;
    expect(input.attributes?.containsKey('disabled'), isTrue);
    expect(input.classes, isNot(contains('placeholder:text-disabled-content')));
    expect(input.classes, isNot(contains('placeholder:text-placeholder')));
    final style = find.tag('style').evaluate().single.component as DomComponent;
    final css = (style.children!.single as RawText).text;
    expect(css, contains('#${input.id}::placeholder'));
    expect(css, contains('rgba(18, 52, 86,'));
  });

  testComponents('default and disabled token colors retain the class path', (
    tester,
  ) async {
    for (final enabled in [true, false]) {
      pumpWithTheme(tester, FormattedInput.phone(enabled: enabled));
      final input =
          find.tag('input').evaluate().single.component as DomComponent;
      expect(
        input.classes,
        contains(
          enabled
              ? 'placeholder:text-placeholder'
              : 'placeholder:text-disabled-content',
        ),
      );
      expect(find.tag('style'), findsNothing);
    }
  });

  testComponents('raw rules do not target another input or its affix', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      const div([
        FormattedInput.phone(
          leading: Component.element(tag: 'input', id: 'affix-input'),
          formattedInputStyle: CoreFormattedInputStyle(
            segmentInputStyle: CoreTextFieldStyle(
              placeholderStyle: CoreTextStyle(color: CoreColor(0xFF123456)),
            ),
          ),
        ),
        FormattedInput.phone(),
      ]),
    );
    final inputs = find
        .tag('input')
        .evaluate()
        .map(
          (element) => element.component as DomComponent,
        )
        .toList();
    final style = find.tag('style').evaluate().single.component as DomComponent;
    final css = (style.children!.single as RawText).text;
    final target = inputs.singleWhere(
      (field) =>
          field.id != 'affix-input' &&
          !(field.classes ?? '').contains('placeholder:text-placeholder'),
    );
    final other = inputs.singleWhere(
      (field) => (field.classes ?? '').contains('placeholder:text-placeholder'),
    );
    expect(css, contains('#${target.id}::placeholder'));
    expect(css, isNot(contains('#affix-input')));
    expect(css, isNot(contains('#${other.id}')));
  });

  testComponents('raw and default placeholders survive the dark theme', (
    tester,
  ) async {
    tester.pumpComponent(
      Theme(
        data: ThemeData.dark,
        child: const FormattedInput.phone(
          formattedInputStyle: CoreFormattedInputStyle(
            segmentInputStyle: CoreTextFieldStyle(
              placeholderStyle: CoreTextStyle(color: CoreColor(0xFF123456)),
            ),
          ),
        ),
      ),
    );
    var field = find.tag('input').evaluate().single.component as DomComponent;
    final style = find.tag('style').evaluate().single.component as DomComponent;
    expect(
      (style.children!.single as RawText).text,
      contains('rgb(18, 52, 86)'),
    );
    expect(field.classes, isNot(contains('placeholder:text-placeholder')));

    tester.pumpComponent(
      Theme(data: ThemeData.dark, child: const FormattedInput.phone()),
    );
    field = find.tag('input').evaluate().single.component as DomComponent;
    expect(field.classes, contains('placeholder:text-placeholder'));
    expect(find.tag('style'), findsNothing);
  });

  testComponents('transparent placeholder remains transparent', (tester) async {
    pumpWithTheme(
      tester,
      const FormattedInput.phone(
        formattedInputStyle: CoreFormattedInputStyle(
          segmentInputStyle: CoreTextFieldStyle(
            placeholderStyle: CoreTextStyle(color: CoreColor.transparent),
          ),
        ),
      ),
    );
    final style = find.tag('style').evaluate().single.component as DomComponent;
    expect(
      (style.children!.single as RawText).text,
      contains('rgba(0, 0, 0, 0'),
    );
  });

  testComponents('instance placeholder color overrides the theme', (
    tester,
  ) async {
    final theme = ThemeData.coui.copyWith(
      coreComponentTheme: const CoreComponentTheme(
        formattedInput: CoreFormattedInputTheme(
          style: CoreFormattedInputStyle(
            segmentInputStyle: CoreTextFieldStyle(
              placeholderStyle: CoreTextStyle(color: CoreColor(0xFF112233)),
            ),
          ),
        ),
      ),
    );
    tester.pumpComponent(
      Theme(data: theme, child: const FormattedInput.phone()),
    );
    var style = find.tag('style').evaluate().single.component as DomComponent;
    expect(
      (style.children!.single as RawText).text,
      contains('rgb(17, 34, 51)'),
    );

    tester.pumpComponent(
      Theme(
        data: theme,
        child: const FormattedInput.phone(
          formattedInputStyle: CoreFormattedInputStyle(
            segmentInputStyle: CoreTextFieldStyle(
              placeholderStyle: CoreTextStyle(color: CoreColor(0xFF123456)),
            ),
          ),
        ),
      ),
    );
    style = find.tag('style').evaluate().single.component as DomComponent;
    final css = (style.children!.single as RawText).text;
    expect(css, contains('rgb(18, 52, 86)'));
    expect(css, isNot(contains('rgb(17, 34, 51)')));
  });
}
