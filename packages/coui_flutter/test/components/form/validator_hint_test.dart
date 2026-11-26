import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kFontSize = 12.0;
const _kValidatorHintTypeCount = 5;

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  group('CoreValidatorHintType', () {
    test('has error, warning, info, success, neutral values', () {
      expect(
        CoreValidatorHintType.values.length,
        equals(_kValidatorHintTypeCount),
      );
      expect(
        CoreValidatorHintType.values,
        contains(CoreValidatorHintType.error),
      );
      expect(
        CoreValidatorHintType.values,
        contains(CoreValidatorHintType.warning),
      );
      expect(
        CoreValidatorHintType.values,
        contains(CoreValidatorHintType.info),
      );
      expect(
        CoreValidatorHintType.values,
        contains(CoreValidatorHintType.success),
      );
      expect(
        CoreValidatorHintType.values,
        contains(CoreValidatorHintType.neutral),
      );
    });
  });

  group('ValidatorHint widget', () {
    testWidgets('renders when visible is true', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidatorHint(
            message: material.Text('Error message'),
          ),
        ),
      );

      expect(find.text('Error message'), findsOneWidget);
    });

    testWidgets('accepts key parameter', (tester) async {
      const testKey = material.Key('test-validator-hint');

      await tester.pumpWidget(
        _buildApp(
          const ValidatorHint(
            key: testKey,
            message: material.Text('Error'),
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('renders SizedBox when visible is false', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidatorHint(
            message: material.Text('Hidden message'),
            visible: false,
          ),
        ),
      );

      expect(find.text('Hidden message'), findsNothing);
      expect(find.byType(material.SizedBox), findsWidgets);
    });

    testWidgets('defaults to error type', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidatorHint(
            message: material.Text('Error'),
          ),
        ),
      );

      final widget = tester.widget<ValidatorHint>(find.byType(ValidatorHint));
      expect(widget.type, equals(CoreValidatorHintType.error));
    });

    testWidgets('renders with warning type', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidatorHint(
            message: material.Text('Warning message'),
            type: .warning,
          ),
        ),
      );

      expect(find.text('Warning message'), findsOneWidget);
    });

    testWidgets('renders with info type', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidatorHint(
            message: material.Text('Info message'),
            type: .info,
          ),
        ),
      );

      expect(find.text('Info message'), findsOneWidget);
    });

    testWidgets('renders with success type', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidatorHint(
            message: material.Text('Success message'),
            type: .success,
          ),
        ),
      );

      expect(find.text('Success message'), findsOneWidget);
    });

    testWidgets('renders custom icon when provided', (tester) async {
      const customIcon = material.Icon(material.Icons.star);

      await tester.pumpWidget(
        _buildApp(
          const ValidatorHint(
            message: material.Text('With icon'),
            icon: customIcon,
          ),
        ),
      );

      expect(find.byIcon(material.Icons.star), findsOneWidget);
    });

    testWidgets('renders default icon when none provided', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidatorHint(
            message: material.Text('Error with default icon'),
          ),
        ),
      );

      // Default icon is a CoUI Icon glyph derived from the hint type.
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('renders warning default icon', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidatorHint(
            message: material.Text('Warning'),
            type: .warning,
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('renders info default icon', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidatorHint(
            message: material.Text('Info'),
            type: .info,
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('renders success default icon', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidatorHint(
            message: material.Text('Success'),
            type: .success,
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
    });

    // The neutral member exists so a not-yet-met line can be drawn WITHOUT
    // a status colour — that is the whole of it, so the accent is what the
    // test has to read. Asserting only that an icon renders would pass with
    // `info`'s blue, which is the bug this member was added for.
    testWidgets('neutral draws its accent from onSurfaceVariant, not a '
        'status colour', (tester) async {
      // `final`, not `const` — indexing a const map is not itself a
      // constant expression (`const_eval_method_invocation`).
      final neutralAccent =
          CoreValidatorHintStyle.defaultsByType[CoreValidatorHintType.neutral];
      final infoAccent = CoreValidatorHintStyle
          .defaultsByType[CoreValidatorHintType.info]!
          .accentColor;

      expect(neutralAccent, isNotNull);
      expect(
        neutralAccent!.accentColor,
        equals(const CoreColor.token(CoreColors.onSurfaceVariant)),
      );
      // …and is not simply a copy of the nearest status tone.
      expect(neutralAccent.accentColor, isNot(equals(infoAccent)));
    });

    testWidgets('neutral default glyph is the unfilled twin of success', (
      tester,
    ) async {
      expect(
        coValidatorHintDefaultIcon(CoreValidatorHintType.neutral),
        equals(LucideIcons.circleDashed),
      );
      // The pair shares a column in a checklist, so it must not collide
      // with the mark it alternates against.
      expect(
        coValidatorHintDefaultIcon(CoreValidatorHintType.neutral),
        isNot(
          equals(coValidatorHintDefaultIcon(CoreValidatorHintType.success)),
        ),
      );
    });

    testWidgets('applies custom textStyle via validatorHintStyle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidatorHint(
            message: material.Text('Styled'),
            validatorHintStyle: CoreValidatorHintStyle(
              messageTextStyle: CoreTextStyle(fontSize: _kFontSize),
            ),
          ),
        ),
      );

      expect(find.text('Styled'), findsOneWidget);
    });
  });

  group('ValidatorHint named constructors', () {
    testWidgets('ValidatorHint.error creates error type', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidatorHint.error(
            message: material.Text('Error'),
          ),
        ),
      );

      final widget = tester.widget<ValidatorHint>(find.byType(ValidatorHint));
      expect(widget.type, equals(CoreValidatorHintType.error));
    });

    testWidgets('ValidatorHint.warning creates warning type', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidatorHint.warning(
            message: material.Text('Warning'),
          ),
        ),
      );

      final widget = tester.widget<ValidatorHint>(find.byType(ValidatorHint));
      expect(widget.type, equals(CoreValidatorHintType.warning));
    });

    testWidgets('ValidatorHint.info creates info type', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidatorHint.info(
            message: material.Text('Info'),
          ),
        ),
      );

      final widget = tester.widget<ValidatorHint>(find.byType(ValidatorHint));
      expect(widget.type, equals(CoreValidatorHintType.info));
    });

    testWidgets('ValidatorHint.success creates success type', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidatorHint.success(
            message: material.Text('Success'),
          ),
        ),
      );

      final widget = tester.widget<ValidatorHint>(find.byType(ValidatorHint));
      expect(widget.type, equals(CoreValidatorHintType.success));
    });
  });
}
