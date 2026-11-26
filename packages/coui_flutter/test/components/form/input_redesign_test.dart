// The input redesign (#5747), read back from what the fields render: the
// outer focus ring is a keyboard signal, the filled variant steps its fill
// under the pointer, a disabled placeholder takes the disabled ink, the
// `lg` rung's helper line steps up, and a text area can end its helper line
// in a character count.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: Theme(
      data: const ThemeData(),
      child: Center(child: SizedBox(width: 240, child: child)),
    ),
  ),
);

Future<T> _resolve<T>(
  WidgetTester tester,
  T Function(BuildContext context, ThemeData theme) read,
) async {
  late T result;
  await tester.pumpWidget(
    _app(
      Builder(
        builder: (context) {
          result = read(context, Theme.of(context));
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return result;
}

bool _ringShown(WidgetTester tester) =>
    tester.widget<FocusOutline>(find.byType(FocusOutline).first).focused;

void main() {
  group('the outer focus ring is a keyboard signal', () {
    for (final entry in <String, Widget Function()>{
      'TextField': TextField.new,
      'TextArea': TextArea.new,
    }.entries) {
      // The strategy is forced, so this reads only the touch-mode half. What a
      // real mouse does is `input_focus_ring_pointer_test.dart`'s.
      testWidgets('${entry.key}: a touch-mode focus draws no ring', (
        tester,
      ) async {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTouch;
        addTearDown(
          () => FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.automatic,
        );
        await tester.pumpWidget(_app(entry.value()));
        await tester.tap(find.byType(EditableText));
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .hasFocus,
          isTrue,
        );
        expect(_ringShown(tester), isFalse);
      });

      testWidgets('${entry.key}: a keyboard focus draws the ring', (
        tester,
      ) async {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        addTearDown(
          () => FocusManager.instance.highlightStrategy =
              FocusHighlightStrategy.automatic,
        );
        await tester.pumpWidget(_app(entry.value()));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(_ringShown(tester), isTrue);
      });
    }
  });

  group('the filled variant', () {
    testWidgets('TextField steps its fill under the pointer and hides its '
        'resting edge', (tester) async {
      final r = await _resolve(
        tester,
        (context, theme) => (
          field: resolveTextField(
            context,
            hasError: false,
            enabled: true,
            size: CoreComponentSize.md,
            variant: CoreTextFieldVariant.filled,
          ),
          scheme: theme.colorScheme,
        ),
      );
      Color token(CoreColorToken t) =>
          r.scheme.resolve(CoreColor.token(t)).toValue();
      final rest = r.field.decoration.resolve(const {});
      final hover = r.field.decoration.resolve(const {WidgetState.hovered});
      expect(rest.color, token(CoreColors.surfaceContainer));
      expect(rest.border!.top.color, rest.color);
      expect(hover.color, token(CoreColors.surfaceContainerHigh));
    });

    testWidgets('TextArea steps its fill under the pointer', (tester) async {
      final r = await _resolve(
        tester,
        (context, theme) => (
          area: resolveTextArea(
            context,
            hasError: false,
            size: CoreComponentSize.md,
            variant: CoreTextAreaVariant.filled,
          ),
          scheme: theme.colorScheme,
        ),
      );
      Color token(CoreColorToken t) =>
          r.scheme.resolve(CoreColor.token(t)).toValue();
      expect(
        r.area.decoration.resolve(const {}).color,
        token(CoreColors.surfaceContainer),
      );
      expect(
        r.area.decoration.resolve(const {WidgetState.hovered}).color,
        token(CoreColors.surfaceContainerHigh),
      );
    });
  });

  testWidgets('a disabled placeholder takes the disabled ink', (tester) async {
    final r = await _resolve(
      tester,
      (context, theme) => (
        field: resolveTextField(
          context,
          hasError: false,
          enabled: false,
          size: CoreComponentSize.md,
        ),
        scheme: theme.colorScheme,
      ),
    );
    expect(
      r.field.placeholderTextStyle.color,
      r.scheme
          .resolve(const CoreColor.token(CoreColors.disabledContent))
          .toValue(),
    );
  });

  testWidgets('the lg rung widens the helper gap and steps the helper role', (
    tester,
  ) async {
    final md = await _resolve(
      tester,
      (context, _) => resolveTextField(
        context,
        hasError: false,
        enabled: true,
        size: CoreComponentSize.md,
      ),
    );
    final lg = await _resolve(
      tester,
      (context, _) => resolveTextField(
        context,
        hasError: false,
        enabled: true,
        size: CoreComponentSize.lg,
      ),
    );
    expect(md.labelPadding.bottom, 6);
    expect(lg.labelPadding.bottom, 8);
    expect(lg.descriptionPadding.top, 8);
    expect(md.descriptionTextStyle.fontSize, 12);
    expect(lg.descriptionTextStyle.fontSize, 13);
  });

  testWidgets('a text area ends its helper line in a live character count', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(TextArea(description: 'Notes', showCounter: true, maxLength: 20)),
    );
    expect(find.text('0 / 20'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'hello');
    await tester.pump();
    expect(find.text('5 / 20'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
  });

  testWidgets('TextArea keeps 12 between a long description and the count '
      '(#5747)', (tester) async {
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 240,
          child: TextArea(
            description:
                'A description long enough to run all the way to the count',
            showCounter: true,
            maxLength: 20,
          ),
        ),
      ),
    );
    final description = tester.getRect(
      find.ancestor(
        of: find.textContaining('A description'),
        matching: find.byType(Expanded),
      ),
    );
    final counter = tester.getRect(find.text('0 / 20'));
    expect(counter.left - description.right, CoreSpace.space12);
    expect(
      counter.right,
      tester.getRect(find.byType(TextArea)).right,
      reason: 'the count ends the row',
    );
  });
}
