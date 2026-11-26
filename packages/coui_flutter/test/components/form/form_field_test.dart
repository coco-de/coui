import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// Form key constants
const _kFieldKeyName = 'name';
const _kFieldKeyAge = 'age';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: Theme(data: const ThemeData(), child: child),
  ),
  localizationsDelegates: const [
    CoUILocalizationsDelegate(),
    material.DefaultMaterialLocalizations.delegate,
    material.DefaultWidgetsLocalizations.delegate,
  ],
);

void main() {
  group('CorePromptMode', () {
    test('has two modes: dialog and popover', () {
      expect(CorePromptMode.values.length, equals(2));
      expect(CorePromptMode.values, contains(CorePromptMode.dialog));
      expect(CorePromptMode.values, contains(CorePromptMode.popover));
    });
  });

  group('FormField widget', () {
    testWidgets('renders the label', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const FormField(
            label: 'Name',
            child: SizedBox.shrink(),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const FormField(
            label: 'Name',
            child: Text('child content'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('child content'), findsOneWidget);
    });

    testWidgets('renders description when provided', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const FormField(
            description: 'Enter your full name',
            label: 'Name',
            child: SizedBox.shrink(),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Enter your full name'), findsOneWidget);
    });

    testWidgets('renders error when provided', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const FormField(
            error: 'This field is required',
            label: 'Name',
            child: SizedBox.shrink(),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('renders a labelWidget when provided', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const FormField(
            labelWidget: Text('Custom Label'),
            child: SizedBox.shrink(),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Custom Label'), findsOneWidget);
    });

    testWidgets('multiple FormFields render independently', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Column(
            children: [
              FormField(
                key: FormKey<String>(_kFieldKeyName),
                label: 'Name',
                child: SizedBox.shrink(),
              ),
              FormField(
                key: FormKey<int>(_kFieldKeyAge),
                label: 'Age',
                child: SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
    });
  });

  group('FormField key parameter', () {
    testWidgets('uses FormKey as key and renders in tree', (tester) async {
      const formKey = FormKey<String>(_kFieldKeyName);

      await tester.pumpWidget(
        _buildApp(
          const FormField(
            key: formKey,
            label: 'Name',
            child: SizedBox.shrink(),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(FormField), findsOneWidget);
    });
  });

  group('ObjectFormField widget', () {
    testWidgets('renders placeholder when value is null', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          ObjectFormField<String>(
            onChanged: (_) {},
            editorBuilder: (context, handler) => const SizedBox.shrink(),
            placeholder: const Text('Select an option'),
            value: null,
            builder: (context, value) => Text(value),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Select an option'), findsOneWidget);
    });

    testWidgets('renders built value when value is not null', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          ObjectFormField<String>(
            onChanged: (_) {},
            editorBuilder: (context, handler) => const SizedBox.shrink(),
            placeholder: const Text('Select an option'),
            value: 'Option A',
            builder: (context, value) => Text('Selected: $value'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Selected: Option A'), findsOneWidget);
      expect(find.text('Select an option'), findsNothing);
    });

    testWidgets('respects key parameter', (tester) async {
      const testKey = Key('object-form-field-key');

      await tester.pumpWidget(
        _buildApp(
          ObjectFormField<String>(
            key: testKey,
            onChanged: (_) {},
            editorBuilder: (context, handler) => const SizedBox.shrink(),
            placeholder: const Text('Select'),
            value: null,
            builder: (context, value) => Text(value),
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('renders as disabled when onChanged is null', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          ObjectFormField<String>(
            onChanged: null,
            editorBuilder: (context, handler) => const SizedBox.shrink(),
            placeholder: const Text('Disabled field'),
            value: null,
            builder: (context, value) => Text(value),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Disabled field'), findsOneWidget);
    });

    testWidgets('renders leading widget when provided', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          ObjectFormField<String>(
            onChanged: (_) {},
            editorBuilder: (context, handler) => const SizedBox.shrink(),
            leading: const material.Icon(material.Icons.search),
            placeholder: const Text('With leading'),
            value: null,
            builder: (context, value) => Text(value),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byIcon(material.Icons.search), findsOneWidget);
    });
  });

  group('FormField labelAction / counterText', () {
    testWidgets('labelAction renders beside the label', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const FormField(
            label: 'Password',
            labelAction: material.Text('Forgot password?'),
            child: SizedBox.shrink(),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('label row is unchanged when no action is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const FormField(label: 'Password', child: SizedBox.shrink()),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Password'), findsOneWidget);
      // No action means no row wrapping it — the label is the whole of it.
      expect(find.byType(FormLabel), findsOneWidget);
    });

    testWidgets('counterText renders in the footer', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const FormField(
            label: 'Bio',
            counterText: '0 / 20',
            child: SizedBox.shrink(),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('0 / 20'), findsOneWidget);
    });

    // The counter has to hold the footer open BY ITSELF. The row used to
    // collapse on "no error and no description", and a length-capped
    // field with nothing else to say is exactly that case — the tally
    // would have gone with them.
    testWidgets('counter alone keeps the footer from collapsing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const FormField(
            label: 'Bio',
            counterText: '12 / 20',
            child: SizedBox.shrink(),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('12 / 20'), findsOneWidget);
      // …and nothing invented a message to sit beside it.
      expect(find.byType(ValidatorHint), findsNothing);
    });

    testWidgets('counter sits alongside a description', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const FormField(
            label: 'Bio',
            description: 'Tell us about yourself.',
            counterText: '0 / 20',
            child: SizedBox.shrink(),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Tell us about yourself.'), findsOneWidget);
      expect(find.text('0 / 20'), findsOneWidget);
    });

    // `error` outranks `description` — that predates this change, and the
    // counter must not have quietly resurrected the description beside it.
    testWidgets('error still hides the description, counter still shows', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const FormField(
            label: 'Bio',
            description: 'Tell us about yourself.',
            error: 'Too long.',
            counterText: '21 / 20',
            child: SizedBox.shrink(),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Too long.'), findsOneWidget);
      expect(find.text('Tell us about yourself.'), findsNothing);
      expect(find.text('21 / 20'), findsOneWidget);
    });

    testWidgets('neither slot given leaves the field as it was', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const FormField(label: 'Plain', child: SizedBox.shrink()),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Plain'), findsOneWidget);
      expect(find.byType(ValidatorHint), findsNothing);
    });
  });
}
