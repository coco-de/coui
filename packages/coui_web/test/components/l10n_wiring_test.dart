import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

/// A locale whose chrome strings are unmistakably not the English ones —
/// used to prove a label comes from the active [CouiLocalizations] rather
/// than a literal baked into the component.
class _MarkedLocalizations extends DefaultCouiLocalizations {
  const _MarkedLocalizations();

  @override
  String get alertLabel => '표시';

  @override
  String get bannerLabel => '띠배너';

  @override
  String get menubarLabel => '메뉴표시줄';

  @override
  String get windowLabel => '창표시';

  @override
  String get windowMinimize => '줄이기';

  @override
  String get windowMaximize => '늘리기';

  @override
  String get buttonClose => '종료';

  @override
  String get trackerLabel => '추적기';

  @override
  String get resizableDividerLabel => '칸막이';

  @override
  String resizableDividerPositionLabel(int percent) => '$percent 지점';
}

Iterable<String> _ariaLabels(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .map((c) => (c.attributes ?? const {})['aria-label'])
    .whereType();

/// Attributes of every `role="separator"` element — the `Resizable`
/// divider carries its name and its spoken value on the same node.
Iterable<Map<String, String>> _separatorAttributes(ComponentTester tester) =>
    find
        .byType(DomComponent)
        .evaluate()
        .map((e) => e.component as DomComponent)
        .map((c) => c.attributes ?? const <String, String>{})
        .where((a) => a['role'] == 'separator');

/// The `Resizable` split under test — the left pane's share of the
/// container, which is what its divider announces.
const _kLeftPaneFraction = 0.3;
const _kRightPaneFraction = 0.7;

/// Ratio → percent, mirroring the component's own conversion so the
/// expected sentences are derived the same way the announced ones are
/// rather than transcribed by hand. `kPercentScale` is the kit's own
/// exported constant.
int _percent(double ratio) => (ratio * kPercentScale).round();

Component _twoPaneResizable() => Resizable(
  panes: [
    CoreResizablePaneData<Component>(
      content: div(const []),
      initialSize: _kLeftPaneFraction,
    ),
    CoreResizablePaneData<Component>(
      content: div(const []),
      initialSize: _kRightPaneFraction,
    ),
  ],
);

void main() {
  // Measured before these existed: each component already read some other
  // localizations member correctly (Alert/Banner's own `dismissLabel`,
  // Menubar had none at all) while its own root accessible name was either
  // absent or a hardcoded English literal. Switching locale never changed
  // it, so the gap only showed up once someone turned on a screen reader.
  group('root aria-label comes from the active locale, not a literal', () {
    // Alert used to belong to this group, reading `alertLabel` from the
    // locale for its root name. It no longer can: `title` became required,
    // so there is always a better name than a generic localised "Alert" and
    // the fallback branch is unreachable. Kept as a pair of tests rather
    // than deleted, because "this component stopped reading the locale" is
    // exactly what this file exists to catch — the two below say it is a
    // consequence of the title contract and not the old regression coming
    // back, and they fail if that contract is ever relaxed.
    testComponents('Alert names itself with its own title', (tester) async {
      pumpWithTheme(
        tester,
        CouiLocalizationsScope(
          localizations: const _MarkedLocalizations(),
          child: const Alert(
            title: 'Sort order',
            description: 'Orders are shown newest first',
          ),
        ),
      );

      // The marked locale is installed and deliberately *not* used: a
      // caller-supplied name outranks any generic one, translated or not.
      expect(_ariaLabels(tester), contains('Sort order'));
      expect(_ariaLabels(tester), isNot(contains('표시')));
    });

    test('and it has no other name to fall back to', () {
      // The reason above, made falsifiable rather than asserted in prose.
      // If `title` ever goes back to nullable this stops compiling, and
      // whoever makes that change has to restore the locale fallback and
      // the test for it.
      // Not `const`: this language cannot read a property off a const
      // object in a const initialiser (`const_eval_property_access`).
      final String title = const Alert(title: 'Sort order').title;
      expect(title, isNotEmpty);
    });

    testComponents('Banner', (tester) async {
      pumpWithTheme(
        tester,
        CouiLocalizationsScope(
          localizations: const _MarkedLocalizations(),
          child: Banner(message: const Text('Session expiring soon')),
        ),
      );

      expect(_ariaLabels(tester), contains('띠배너'));
    });

    testComponents('Menubar', (tester) async {
      pumpWithTheme(
        tester,
        CouiLocalizationsScope(
          localizations: const _MarkedLocalizations(),
          child: const Menubar(
            menus: [CoreMenubarMenu(label: 'File')],
          ),
        ),
      );

      expect(_ariaLabels(tester), contains('메뉴표시줄'));
    });

    testComponents('WindowPanel', (tester) async {
      pumpWithTheme(
        tester,
        CouiLocalizationsScope(
          localizations: const _MarkedLocalizations(),
          child: const WindowPanel(),
        ),
      );

      expect(_ariaLabels(tester), contains('창표시'));
    });
  });

  group('WindowPanel control button labels come from the active locale', () {
    testComponents('minimize / maximize / close', (tester) async {
      pumpWithTheme(
        tester,
        CouiLocalizationsScope(
          localizations: const _MarkedLocalizations(),
          child: const WindowPanel(minimizable: true, maximizable: true),
        ),
      );

      final labels = _ariaLabels(tester).toSet();
      expect(labels, containsAll(['줄이기', '늘리기', '종료']));
    });
  });

  // Measured before this changed: a segment with no `tooltip` fell back to
  // `segment.status.name` — a Dart identifier, not a translated string, and
  // not stable across a refactor. The Flutter twin's own accessible name
  // comes from `Tooltip(message: tooltip ?? status.name)`; Web's aria-label
  // ignored `tooltip` entirely and always read the raw enum name.
  group(
    'Tracker names come from the same source as Flutter, not the raw enum',
    () {
      testComponents('segment aria-label prefers the caller-supplied tooltip', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          Tracker(
            segments: const [
              CoreTrackerSegment(
                status: .fine,
                tooltip: 'Healthy',
              ),
              CoreTrackerSegment(status: .warning),
            ],
          ),
        );

        final labels = _ariaLabels(tester).toSet();
        expect(labels, contains('Healthy'));
        expect(labels, isNot(contains('fine')));
        // No tooltip supplied — falls back to the enum name, same as
        // Flutter's own fallback (not translated, tracked separately).
        expect(labels, contains('warning'));
      });

      testComponents('root aria-label comes from the active locale', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          CouiLocalizationsScope(
            localizations: const _MarkedLocalizations(),
            child: Tracker(
              segments: const [CoreTrackerSegment(status: .fine)],
            ),
          ),
        );

        expect(_ariaLabels(tester), contains('추적기'));
      });
    },
  );

  // Measured before this changed: the divider emitted `aria-valuetext:
  // "30%"` — a bare number with no subject — and carried no accessible
  // name at all. A reader announced "30 percent" of nothing, in English,
  // whatever the page locale was.
  group('Resizable divider name and spoken value come from the locale', () {
    testComponents('English default', (tester) async {
      pumpWithTheme(tester, _twoPaneResizable());

      final divider = _separatorAttributes(tester).single;
      final english = DefaultCouiLocalizations.instance;
      expect(divider['aria-label'], english.resizableDividerLabel);
      expect(
        divider['aria-valuetext'],
        english.resizableDividerPositionLabel(_percent(_kLeftPaneFraction)),
      );
    });

    testComponents('follows the active locale', (tester) async {
      pumpWithTheme(
        tester,
        CouiLocalizationsScope(
          localizations: const _MarkedLocalizations(),
          child: _twoPaneResizable(),
        ),
      );

      final divider = _separatorAttributes(tester).single;
      // Both strings move together: the name says what the control is,
      // `aria-valuetext` says what its number means. A literal in either
      // one would survive the locale swap and fail here.
      expect(divider['aria-label'], '칸막이');
      expect(divider['aria-valuetext'], '30 지점');
    });

    testComponents(
      'aria-valuenow stays a bare number while aria-valuetext is the '
      'localized sentence',
      (tester) async {
        pumpWithTheme(
          tester,
          CouiLocalizationsScope(
            localizations: const _MarkedLocalizations(),
            child: _twoPaneResizable(),
          ),
        );

        final divider = _separatorAttributes(tester).single;
        // `aria-valuenow`/`min`/`max` are numeric ARIA attributes — a
        // translated sentence in them is invalid, so localization must
        // stop at `aria-valuetext`. Both halves are asserted here, or
        // the name would outrun the body.
        expect(divider['aria-valuenow'], '${_percent(_kLeftPaneFraction)}');
        expect(divider['aria-valuemin'], '0');
        expect(divider['aria-valuemax'], '100');
        expect(divider['aria-valuetext'], '30 지점');
      },
    );

    // The tests above prove the divider follows whatever locale is
    // installed, using a fake. They say nothing about the locale this
    // package actually ships: `KoCouiLocalizations` could serve the
    // English strings and every one of them would still pass. The
    // Flutter twin has the same guard.
    test('the shipped ko strings are translated, and carry their number', () {
      const english = DefaultCouiLocalizations.instance;
      const korean = KoCouiLocalizations.instance;
      final percent = _percent(_kLeftPaneFraction);

      expect(
        korean.resizableDividerLabel,
        isNot(english.resizableDividerLabel),
      );
      expect(
        korean.resizableDividerPositionLabel(percent),
        isNot(english.resizableDividerPositionLabel(percent)),
      );
      expect(
        english.resizableDividerPositionLabel(percent),
        contains('$percent'),
      );
      expect(
        korean.resizableDividerPositionLabel(percent),
        contains('$percent'),
      );
    });
  });
}
