import 'dart:ui' show Tristate;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Reads the semantics tree a screen reader walks — not the widgets that
// were asked to produce it. Each group below is a state change that was
// drawn correctly and reached no reader: an error that appeared after
// submit, a list that opened, a row that was the chosen one.

// Fixed pumps rather than `pumpAndSettle` once a popover is open — the
// overlay keeps a ticker alive, so "settled" never arrives.
const _kFrame = Duration(seconds: 1);

const _kItems = [
  CoreSelectItem<String>(value: 'apple', label: 'Apple'),
  CoreSelectItem<String>(value: 'banana', label: 'Banana'),
];

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: 320, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Every node in the committed semantics tree.
List<SemanticsData> _nodes(WidgetTester tester) {
  final out = <SemanticsData>[];
  bool visit(SemanticsNode node) {
    out.add(node.getSemanticsData());
    node.visitChildren(visit);
    return true;
  }

  // Climb from any node to the root rather than asking the binding's
  // pipeline owner for it — that accessor is deprecated under multi-view.
  var root = tester.getSemantics(find.byType(SizedBox).first);
  while (root.parent != null) {
    root = root.parent!;
  }
  visit(root);
  return out;
}

/// The live-region nodes whose text mentions [text].
Iterable<SemanticsData> _liveRegionsSaying(WidgetTester tester, String text) =>
    _nodes(tester).where(
      (n) => n.flagsCollection.isLiveRegion && n.label.contains(text),
    );

/// The expanded state of the node that carries one — null when no node
/// states it at all.
Tristate? _expandedState(WidgetTester tester) {
  for (final n in _nodes(tester)) {
    final state = n.flagsCollection.isExpanded;
    if (state != Tristate.none) return state;
  }
  return null;
}

void main() {
  group('a validation message is announced when it appears', () {
    testWidgets('a field error lands in a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const FormField(
          label: 'Email',
          child: SizedBox.shrink(),
        ),
      );
      expect(_liveRegionsSaying(tester, 'Enter a valid email'), isEmpty);

      // Submitting produced this before; the reader never heard it. The
      // field kept focus, so nothing prompted it to read the new line.
      await _pump(
        tester,
        const FormField(
          label: 'Email',
          error: 'Enter a valid email',
          child: SizedBox.shrink(),
        ),
      );

      expect(_liveRegionsSaying(tester, 'Enter a valid email'), hasLength(1));
      handle.dispose();
    });

    testWidgets('a description is not news', (tester) async {
      // The half a blanket live region would fail: helper text is there
      // from the start, and announcing it would interrupt at load.
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const FormField(
          label: 'Email',
          description: 'We never share it',
          child: SizedBox.shrink(),
        ),
      );

      expect(_liveRegionsSaying(tester, 'We never share it'), isEmpty);
      handle.dispose();
    });

    testWidgets('each reported tone announces, a neutral rule does not', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final type in CoreValidatorHintType.values) {
        await _pump(
          tester,
          ValidatorHint(type: type, message: Text('hint ${type.name}')),
        );
        final announced = _liveRegionsSaying(
          tester,
          'hint ${type.name}',
        ).isNotEmpty;
        expect(
          announced,
          type != CoreValidatorHintType.neutral,
          reason: '$type',
        );
      }
      handle.dispose();
    });
  });

  group('a popup field says whether its list is showing', () {
    testWidgets('Select opens and closes', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        Select<String>(
          placeholder: 'Fruit',
          items: _kItems,
          onChanged: (_) {},
        ),
      );
      expect(_expandedState(tester), Tristate.isFalse);

      await tester.tap(find.byType(TextField));
      await tester.pump(_kFrame);
      expect(_expandedState(tester), Tristate.isTrue);

      // Closing from outside — nothing in Select rebuilds for it, so the
      // flag follows only if the popover rebuilds its own trigger.
      await tester.tapAt(const Offset(4, 590), kind: PointerDeviceKind.mouse);
      await tester.pump(_kFrame);
      expect(_expandedState(tester), Tristate.isFalse);

      await tester.tap(find.byType(TextField));
      await tester.pump(_kFrame);
      expect(_expandedState(tester), Tristate.isTrue);

      // Closing through the list — the path that used to skip the
      // rebuild and leave the field saying "expanded".
      await tester.tap(find.text('Banana'));
      await tester.pump(_kFrame);
      expect(_expandedState(tester), Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('Autocomplete opens as suggestions match, closes on Escape', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const Autocomplete(suggestions: ['Apple', 'Apricot']),
      );
      expect(_expandedState(tester), Tristate.isFalse);

      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'Ap');
      await tester.pump(_kFrame);
      expect(_expandedState(tester), Tristate.isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(_kFrame);
      expect(_expandedState(tester), Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('PhoneInput follows a close it did not ask for', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const PhoneInput());
      expect(_expandedState(tester), Tristate.isFalse);

      await tester.tap(find.textContaining('+82').first);
      await tester.pump(_kFrame);
      expect(_expandedState(tester), Tristate.isTrue);

      // An outside tap closes the list without the field's involvement;
      // nothing rebuilt it, so the flag kept saying "expanded".
      await tester.tapAt(const Offset(4, 590), kind: PointerDeviceKind.mouse);
      await tester.pump(_kFrame);
      expect(_expandedState(tester), Tristate.isFalse);
      handle.dispose();
    });
  });

  group('the chosen row says it is chosen', () {
    testWidgets('ItemPicker', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        ItemPicker(
          items: const ['Apple', 'Banana'],
          selectedValue: 'Banana',
          onChanged: (_) {},
        ),
      );

      final rows = {
        for (final n in _nodes(tester))
          if (n.label == 'Apple' || n.label == 'Banana')
            n.label: n.flagsCollection.isSelected,
      };
      expect(rows, {'Apple': Tristate.isFalse, 'Banana': Tristate.isTrue});
      handle.dispose();
    });

    testWidgets('Command — the keyboard cursor is the selected row', (
      tester,
    ) async {
      // A palette has no value; the row in play is the one Enter would
      // run, and the Web twin states it as `aria-selected="true"` beside
      // `aria-activedescendant`. Before, the row said nothing at all — the
      // cursor was only a fill and an accent bar.
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        SizedBox(
          height: 400,
          child: Command(
            onSelect: (_) {},
            groups: const [
              CoreCommandGroup(
                items: [
                  CoreCommandItem(value: 'calendar', label: 'Calendar'),
                  CoreCommandItem(value: 'search', label: 'Search'),
                ],
              ),
            ],
          ),
        ),
      );

      Map<String, Tristate> rows() => {
        for (final n in _nodes(tester))
          if (n.label == 'Calendar' || n.label == 'Search')
            n.label: n.flagsCollection.isSelected,
      };

      expect(rows(), {'Calendar': Tristate.isTrue, 'Search': Tristate.isFalse});

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(rows(), {'Calendar': Tristate.isFalse, 'Search': Tristate.isTrue});
      handle.dispose();
    });
  });

  group('the keyboard cursor in an open list reaches the reader', () {
    testWidgets('Select names the row the cursor lands on', (tester) async {
      // Web points the trigger at the row with `aria-activedescendant`.
      // Flutter has no such relation and the row's `selected` flag is the
      // value, so the cursor travels as an announcement of the row.
      final spoken = _announcements();
      await _pump(tester, _announcingSelect(supportsAnnounce: true));
      expect(spoken, isEmpty);

      // Opening starts the cursor on the value — Web's first
      // `aria-activedescendant`.
      await tester.tap(find.byType(TextField));
      await tester.pump(_kFrame);
      expect(spoken, ['Banana']);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(spoken, ['Banana', 'Cherry', 'Apple']);
    });

    testWidgets('Select stays quiet where the platform cannot announce', (
      tester,
    ) async {
      // Nothing is queued for a reader the platform says is not there.
      final spoken = _announcements();
      await _pump(tester, _announcingSelect(supportsAnnounce: false));
      await tester.tap(find.byType(TextField));
      await tester.pump(_kFrame);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(spoken, isEmpty);
    });
  });
}

/// A three-row `Select` on `banana`, under a media query that states
/// whether the platform can announce.
Widget _announcingSelect({required bool supportsAnnounce}) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(supportsAnnounce: supportsAnnounce),
    child: Select<String>(
      placeholder: 'Fruit',
      value: 'banana',
      items: const [
        CoreSelectItem<String>(value: 'apple', label: 'Apple'),
        CoreSelectItem<String>(value: 'banana', label: 'Banana'),
        CoreSelectItem<String>(value: 'cherry', label: 'Cherry'),
      ],
      onChanged: (_) {},
    ),
  ),
);

/// Collects the sentences announced to the platform, as it would receive
/// them.
List<String> _announcements() {
  final spoken = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockDecodedMessageHandler<Object?>(
        SystemChannels.accessibility,
        (message) async {
          if (message case {
            'type': 'announce',
            'data': final Map<Object?, Object?> data,
          }) {
            spoken.add(data['message']! as String);
          }
          return null;
        },
      );
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(
          SystemChannels.accessibility,
          null,
        ),
  );
  return spoken;
}
