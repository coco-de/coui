// FormFieldScope — the disabled / error constraint `FormField` and
// `Fieldset` publish to the input they wrap, and `TextField` reading it.
//
// Every chrome claim here is made by comparison against a standalone
// `TextField` stated the same way (`enabled: false`, `errorText: ...`)
// rather than against a token value — the question is "does the wrapper's
// state reach the input as if the input had been told directly", and a
// hard-coded colour would pass or fail on a palette change instead.

import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: Theme(
      data: const ThemeData(),
      child: SingleChildScrollView(child: child),
    ),
  ),
  localizationsDelegates: const [
    CoUILocalizationsDelegate.delegate,
    material.DefaultMaterialLocalizations.delegate,
    material.DefaultWidgetsLocalizations.delegate,
  ],
);

/// Same as [_buildApp], but with the theme ABOVE the navigator — a route
/// pushed onto the root navigator (a dialog) resolves its barrier and
/// transition against the navigator's own context, which `_buildApp`'s
/// theme (installed under `home`) does not reach.
Widget _buildOverlayApp(Widget child) => material.MaterialApp(
  builder: (context, navigator) =>
      Theme(data: const ThemeData(), child: navigator!),
  home: material.Scaffold(body: SingleChildScrollView(child: child)),
  localizationsDelegates: const [
    CoUILocalizationsDelegate.delegate,
    material.DefaultMaterialLocalizations.delegate,
    material.DefaultWidgetsLocalizations.delegate,
  ],
);

/// Every box decoration painted inside the [index]-th `TextField` — the
/// field box plus whatever the focus outline paints. Compared as a list
/// so a difference anywhere in the input's own chrome shows.
List<Decoration> _decorationsOf(WidgetTester tester, int index) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(TextField).at(index),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((box) => box.decoration)
    .toList();

EditableText _editableOf(WidgetTester tester, int index) =>
    tester.widget<EditableText>(
      find.descendant(
        of: find.byType(TextField).at(index),
        matching: find.byType(EditableText),
      ),
    );

/// The effective text style a `Text` widget painted with — the style the
/// `RenderParagraph` under [finder] carries, so an inherited
/// `DefaultTextStyle` counts the same as a style passed in directly.
TextStyle? _paintedStyleOf(WidgetTester tester, Finder finder) =>
    tester.renderObject<RenderParagraph>(finder).text.style;

/// Frames to pump while waiting for an overlay to mount — a bound, so an
/// overlay that never opens fails an assertion instead of hanging.
const _kOverlayMountFrames = 20;

void main() {
  group('CoreFormFieldScope value', () {
    test('equality covers both fields', () {
      const a = CoreFormFieldScope(disabled: true, hasError: false);
      const b = CoreFormFieldScope(disabled: true, hasError: false);
      const c = CoreFormFieldScope(disabled: true, hasError: true);
      const d = CoreFormFieldScope(disabled: false, hasError: false);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });
  });

  group('standalone use — no scope, no change', () {
    testWidgets('a TextField with no wrapper reads no scope', (tester) async {
      CoreFormFieldScope? seen = const CoreFormFieldScope(
        disabled: true,
        hasError: true,
      );
      await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (context) {
              seen = FormFieldScope.maybeOf(context);
              return TextField(controller: TextEditingController());
            },
          ),
        ),
      );
      expect(seen, isNull);
    });

    testWidgets(
      'an enabled, error-free FormField leaves its TextField exactly as a '
      'bare one',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            Column(
              children: [
                TextField(controller: TextEditingController()),
                FormField(
                  label: 'Name',
                  child: TextField(controller: TextEditingController()),
                ),
              ],
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        expect(_decorationsOf(tester, 1), equals(_decorationsOf(tester, 0)));
        expect(_editableOf(tester, 1).readOnly, isFalse);
      },
    );

    testWidgets("a standalone TextField's own enabled / errorText still work", (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Column(
            children: [
              TextField(controller: TextEditingController()),
              TextField(enabled: false, controller: TextEditingController()),
              TextField(errorText: 'bad', controller: TextEditingController()),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(
        _decorationsOf(tester, 1),
        isNot(equals(_decorationsOf(tester, 0))),
      );
      expect(_editableOf(tester, 1).readOnly, isTrue);
      expect(
        _decorationsOf(tester, 2),
        isNot(equals(_decorationsOf(tester, 0))),
      );
    });
  });

  group('Fieldset(enabled: false) → FormField → TextField', () {
    testWidgets('the FormField and its input both read disabled', (
      tester,
    ) async {
      CoreFormFieldScope? atField;
      CoreFormFieldScope? atInput;
      await tester.pumpWidget(
        _buildApp(
          Column(
            children: [
              TextField(enabled: false, controller: TextEditingController()),
              TextField(controller: TextEditingController()),
              Fieldset(
                enabled: false,
                children: [
                  Builder(
                    builder: (context) {
                      atField = FormFieldScope.maybeOf(context);
                      return FormField(
                        label: 'Name',
                        child: Builder(
                          builder: (context) {
                            atInput = FormFieldScope.maybeOf(context);
                            return TextField(
                              controller: TextEditingController(),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(atField?.disabled, isTrue);
      expect(atField?.hasError, isFalse);
      // The FormField states `enabled: true` itself — the enclosing
      // Fieldset still wins, and the FormField republishes that.
      expect(atInput?.disabled, isTrue);
      expect(atInput?.hasError, isFalse);

      // Disabled chrome, identical to a TextField told `enabled: false`.
      expect(_decorationsOf(tester, 2), equals(_decorationsOf(tester, 0)));
      expect(
        _decorationsOf(tester, 2),
        isNot(equals(_decorationsOf(tester, 1))),
      );
      expect(_editableOf(tester, 2).readOnly, isTrue);

      // The FormField itself blocks the pointer, as it does for its own
      // `enabled: false` — an ignoring `IgnorePointer` sits between the
      // FormField and its input.
      final blockers = tester
          .widgetList<IgnorePointer>(
            find.ancestor(
              of: find.byType(TextField).at(2),
              matching: find.byType(IgnorePointer),
            ),
          )
          .where((pointer) => pointer.ignoring);
      final fieldBlockers = tester.widgetList<IgnorePointer>(
        find.descendant(
          of: find.byType(FormField),
          matching: find.byType(IgnorePointer),
        ),
      );
      expect(blockers.where(fieldBlockers.contains), isNotEmpty);
    });

    testWidgets('a nested enabled Fieldset cannot re-enable its fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Column(
            children: [
              TextField(enabled: false, controller: TextEditingController()),
              Fieldset(
                enabled: false,
                children: [
                  Fieldset(
                    children: [
                      FormField(
                        child: TextField(controller: TextEditingController()),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(_decorationsOf(tester, 1), equals(_decorationsOf(tester, 0)));
      expect(_editableOf(tester, 1).readOnly, isTrue);
    });

    testWidgets('an enabled Fieldset publishes an enabled scope', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Column(
            children: [
              TextField(controller: TextEditingController()),
              Fieldset(
                children: [
                  FormField(
                    child: TextField(controller: TextEditingController()),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(_decorationsOf(tester, 1), equals(_decorationsOf(tester, 0)));
      expect(_editableOf(tester, 1).readOnly, isFalse);
    });
  });

  group('FormField(error) → TextField', () {
    testWidgets('the input takes the error chrome from the wrapper', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Column(
            children: [
              TextField(errorText: 'x', controller: TextEditingController()),
              TextField(controller: TextEditingController()),
              FormField(
                label: 'Email',
                error: 'Invalid email',
                child: TextField(controller: TextEditingController()),
              ),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(_decorationsOf(tester, 2), equals(_decorationsOf(tester, 0)));
      expect(
        _decorationsOf(tester, 2),
        isNot(equals(_decorationsOf(tester, 1))),
      );
      // The message is the wrapper's to show — the input draws the tone
      // only, not a second copy of the text.
      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('wrapper error and input errorText combine with OR', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Column(
            children: [
              TextField(errorText: 'x', controller: TextEditingController()),
              // Both stated.
              FormField(
                error: 'from wrapper',
                child: TextField(
                  errorText: 'from input',
                  controller: TextEditingController(),
                ),
              ),
              // Only the input stated — the wrapper carries no error and
              // must not clear the input's own.
              FormField(
                child: TextField(
                  errorText: 'from input',
                  controller: TextEditingController(),
                ),
              ),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(_decorationsOf(tester, 1), equals(_decorationsOf(tester, 0)));
      expect(_decorationsOf(tester, 2), equals(_decorationsOf(tester, 0)));
    });

    testWidgets('a disabled FormField disables its input', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Column(
            children: [
              TextField(enabled: false, controller: TextEditingController()),
              FormField(
                enabled: false,
                child: TextField(controller: TextEditingController()),
              ),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(_decorationsOf(tester, 1), equals(_decorationsOf(tester, 0)));
      expect(_editableOf(tester, 1).readOnly, isTrue);
    });
  });

  group('FormField live validation → scope', () {
    testWidgets(
      "the child's scope follows the validator's verdict, not only `error`",
      (tester) async {
        final controller = FormController();
        addTearDown(controller.dispose);
        final seen = <CoreFormFieldScope?>[];

        Widget build(String? value) => _buildApp(
          Form(
            controller: controller,
            children: [
              FormField(
                validator: const RequiredValidator<String>(
                  message: 'Required',
                ),
                child: _ScopeReportingField(value: value, onScope: seen.add),
              ),
            ],
          ),
        );

        // No `error` is stated anywhere — any error tone the child reads
        // comes from the live validation result.
        await tester.pumpWidget(build(null));
        await tester.pumpAndSettle();
        expect(find.text('Required'), findsOneWidget);
        expect(seen.last?.hasError, isTrue);

        await tester.pumpWidget(build('hello'));
        await tester.pumpAndSettle();
        expect(find.text('Required'), findsNothing);
        expect(seen.last?.hasError, isFalse);
      },
    );
  });

  group('FormField footer', () {
    testWidgets('an error removes the description from the tree', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          FormField(
            label: 'Email',
            description: 'We never share it.',
            error: 'Invalid email',
            child: TextField(controller: TextEditingController()),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Invalid email'), findsOneWidget);
      expect(find.text('We never share it.'), findsNothing);
    });

    testWidgets('without an error the description renders', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          FormField(
            label: 'Email',
            description: 'We never share it.',
            child: TextField(controller: TextEditingController()),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('We never share it.'), findsOneWidget);
    });
  });

  group('FormField size', () {
    testWidgets('defaults to md and forwards the size to its FormLabel', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Column(
            children: [
              FormField(label: 'Default', child: SizedBox.shrink()),
              FormField(
                label: 'Large',
                size: CoreComponentSize.lg,
                child: SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final labels = tester.widgetList<FormLabel>(find.byType(FormLabel));
      expect(labels.map((formLabel) => formLabel.size), [
        CoreFormFieldStyle.defaultSize,
        CoreComponentSize.lg,
      ]);
      expect(CoreFormFieldStyle.defaultSize, CoreComponentSize.md);

      // The lg label draws larger than the md one — the rung comes from
      // FormLabel's own ladder (label-medium 13 → label-large 14).
      final defaultSize = tester.getSize(find.text('Default')).height;
      final largeSize = tester.getSize(find.text('Large')).height;
      expect(largeSize, greaterThan(defaultSize));
    });

    testWidgets(
      'a disabled lg field keeps the lg label rung — only the colour mutes',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const Column(
              children: [
                FormField(label: 'MdOn', child: SizedBox.shrink()),
                FormField(
                  label: 'MdOff',
                  enabled: false,
                  child: SizedBox.shrink(),
                ),
                FormField(
                  label: 'LgOn',
                  size: CoreComponentSize.lg,
                  child: SizedBox.shrink(),
                ),
                FormField(
                  label: 'LgOff',
                  size: CoreComponentSize.lg,
                  enabled: false,
                  child: SizedBox.shrink(),
                ),
                // The same pose reached through the scope rather than the
                // field's own flag.
                Fieldset(
                  enabled: false,
                  children: [
                    FormField(
                      label: 'LgInFieldset',
                      size: CoreComponentSize.lg,
                      child: SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final mdOn = _paintedStyleOf(tester, find.text('MdOn'))!;
        final mdOff = _paintedStyleOf(tester, find.text('MdOff'))!;
        final lgOn = _paintedStyleOf(tester, find.text('LgOn'))!;
        final lgOff = _paintedStyleOf(tester, find.text('LgOff'))!;
        final lgInFieldset = _paintedStyleOf(
          tester,
          find.text('LgInFieldset'),
        )!;

        expect(lgOn.fontSize, greaterThan(mdOn.fontSize!));
        // Disabling moves the colour, never the rung.
        expect(lgOff.fontSize, equals(lgOn.fontSize));
        expect(lgOff.fontWeight, equals(lgOn.fontWeight));
        expect(lgOff.height, equals(lgOn.height));
        expect(lgInFieldset.fontSize, equals(lgOn.fontSize));
        // …and the colour it moves to is the one md already mutes to.
        expect(lgOff.color, isNot(equals(lgOn.color)));
        expect(lgOff.color, equals(mdOff.color));
        expect(lgInFieldset.color, equals(mdOff.color));
        // md itself is unchanged by the overlay carrying no role.
        expect(mdOff.fontSize, equals(mdOn.fontSize));
      },
    );
  });

  group('the scope stops at an overlay boundary', () {
    testWidgets(
      'a dialog opened from inside a disabled, erroring field gets no scope',
      (tester) async {
        late BuildContext opener;
        CoreFormFieldScope? atOpener;
        CoreFormFieldScope? inDialog = const CoreFormFieldScope(
          disabled: true,
          hasError: true,
        );
        await tester.pumpWidget(
          _buildOverlayApp(
            Fieldset(
              enabled: false,
              children: [
                FormField(
                  label: 'Name',
                  error: 'Required',
                  child: Builder(
                    builder: (context) {
                      opener = context;
                      atOpener = FormFieldScope.maybeOf(context);
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        // The opener itself sits inside the scope — without this the
        // assertion below would pass for the wrong reason.
        expect(
          atOpener,
          const CoreFormFieldScope(disabled: true, hasError: true),
        );

        unawaited(
          showDialog<void>(
            context: opener,
            builder: (context) {
              inDialog = FormFieldScope.maybeOf(context);
              return TextField(controller: TextEditingController());
            },
          ),
        );
        for (var frame = 0; frame < _kOverlayMountFrames; frame++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (find.byType(TextField).evaluate().isNotEmpty) break;
        }

        expect(find.byType(TextField), findsOneWidget);
        expect(inDialog, isNull);
        // The dialog's input is not the input the wrapper wraps: it stays
        // editable.
        expect(_editableOf(tester, 0).readOnly, isFalse);
      },
    );

    testWidgets('a TimePicker in a disabled Fieldset cannot be opened', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Column(
            children: [
              TimePicker(),
              Fieldset(enabled: false, children: [TimePicker()]),
            ],
          ),
        ),
      );
      await tester.pump();

      // The trigger is a TextField, so the group's scope reaches it — the
      // same answer a Select gives. The panel never mounts.
      await tester.tap(find.byType(TimePicker).last, warnIfMissed: false);
      for (var frame = 0; frame < _kOverlayMountFrames; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(
        find.byWidgetPredicate((w) => w is TextField && !w.readOnly),
        findsNothing,
        reason: 'the panel stays shut',
      );

      // Control: the same picker outside the group does open — otherwise
      // "stays shut" above could just mean the tap missed.
      await tester.tap(find.byType(TimePicker).first);
      for (var frame = 0; frame < _kOverlayMountFrames; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find
            .byWidgetPredicate((w) => w is TextField && !w.readOnly)
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }
      expect(
        find.byWidgetPredicate((w) => w is TextField && !w.readOnly),
        findsWidgets,
      );
    });
  });

  group('inputs that compose a TextField receive the scope through it', () {
    testWidgets('a Select in a disabled Fieldset cannot be opened', (
      tester,
    ) async {
      const items = [
        CoreSelectItem<String>(value: 'apple', label: 'Apple'),
        CoreSelectItem<String>(value: 'banana', label: 'Banana'),
      ];
      await tester.pumpWidget(
        _buildApp(
          Column(
            children: [
              Select<String>(
                onChanged: (_) {},
                placeholder: 'Bare',
                items: items,
              ),
              Select<String>(
                onChanged: (_) {},
                placeholder: 'Told disabled',
                enabled: false,
                items: items,
              ),
              Fieldset(
                enabled: false,
                children: [
                  Select<String>(
                    onChanged: (_) {},
                    placeholder: 'Grouped',
                    items: items,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      // The trigger is a TextField, so the group's scope reaches it: the
      // grouped Select draws exactly the chrome of one told
      // `enabled: false`. (The trigger is `readOnly` in every pose — a
      // select's value is chosen, not typed — so that flag says nothing.)
      expect(_decorationsOf(tester, 2), equals(_decorationsOf(tester, 1)));
      expect(
        _decorationsOf(tester, 2),
        isNot(equals(_decorationsOf(tester, 0))),
      );

      // The placeholder takes the disabled tone too (#5747): the select
      // folds the scope into the colours it hands its trigger.
      Color? placeholderColour(String copy) => tester
          .widget<RichText>(
            find.descendant(
              of: find.text(copy),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style
          ?.color;
      expect(placeholderColour('Grouped'), placeholderColour('Told disabled'));
      expect(
        placeholderColour('Grouped'),
        isNot(placeholderColour('Bare')),
      );

      await tester.tap(find.byType(TextField).at(2), warnIfMissed: false);
      for (var frame = 0; frame < _kOverlayMountFrames; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Apple'), findsNothing, reason: 'the panel stays shut');

      // Control: the same Select outside the group does open — otherwise
      // "stays shut" above could just mean the tap missed.
      await tester.tap(find.byType(TextField).at(0));
      for (var frame = 0; frame < _kOverlayMountFrames; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Apple').evaluate().isNotEmpty) break;
      }
      expect(find.text('Apple'), findsWidgets);
    });
  });
}

/// Minimal form input that reports a value to the ambient form handle and
/// records the [CoreFormFieldScope] it reads on every build — stands in for
/// a real input so the field's live-validation → scope path is observable
/// on its own.
class _ScopeReportingField extends StatefulWidget {
  const _ScopeReportingField({required this.value, required this.onScope});

  final String? value;
  final ValueChanged<CoreFormFieldScope?> onScope;

  @override
  State<_ScopeReportingField> createState() => _ScopeReportingFieldState();
}

class _ScopeReportingFieldState extends State<_ScopeReportingField>
    with FormValueSupplier<String, _ScopeReportingField> {
  @override
  void initState() {
    super.initState();
    formValue = widget.value;
  }

  @override
  void didUpdateWidget(_ScopeReportingField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      formValue = widget.value;
    }
  }

  @override
  void didReplaceFormValue(String value) {}

  @override
  Widget build(BuildContext context) {
    widget.onScope(FormFieldScope.maybeOf(context));
    return const SizedBox.shrink();
  }
}
