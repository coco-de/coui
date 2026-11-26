// #4012 (FR-001) — BDD acceptance for the schema v3 `axes` reader, straight
// from `docs/bdd-figma-contract-components.md`'s two axis scenarios plus the
// always-present-keys shape rule. Runs against the real contracts tree (not
// fixtures) — the scenarios are claims about *this* codebase's enums, and a
// fixture copy would go stale without failing anything.
import 'package:test/test.dart';

import '../bin/figma_reader/axis_reader.dart';

// `dart test`'s working directory for this package is `packages/coui_core/`
// itself — same override reasoning as `export_figma_components_test.dart`.
const _kContractsRoot = 'lib/src/component/contracts';
const _kSrcRoot = 'lib/src';

/// The seed spec's arithmetic for Button was 12 variants × 6 sizes ×
/// enabled 2. `text`, `card` and `link` are gone from the enum, and `fixed`
/// is @behaviourOnly, and `tonal` joined beside `secondary` — so the surface
/// the reader reports is 9 × 6 × 2. The enum has ten; `hidden` names the one
/// that is not a pose.
const _kSpecButtonComboCount = 108;

void main() {
  final axes = readAxes(contractsRoot: _kContractsRoot);
  final sizeMembers = readComponentSizeMembers(srcRoot: _kSrcRoot);

  test('CoreComponentSize members come out in source order', () {
    expect(sizeMembers, ['xs', 'sm', 'md', 'lg', 'xl', 'xl2']);
  });

  group('Scenario: variant 축 enum 멤버 전수 export', () {
    test('button.axes.variant — 9 members on the canvas, source order; '
        'the @behaviourOnly one is named as hidden', () {
      final button = axes['button']!;
      expect(button.variant?.name, 'CoreButtonVariant');
      // `fixed` is @behaviourOnly (CardImage's invisible button): it stays
      // in the enum but is not a pose the canvas offers. It is listed, not
      // silently dropped, so the plugin can retire its member by name
      // instead of finding it unexplained.
      expect(button.variant?.hidden, ['fixed']);
      expect(button.variant?.members, [
        'primary',
        'secondary',
        'tonal',
        'outline',
        'ghost',
        'plain',
        'destructive',
        'menu',
        'menubar',
      ]);
      // `CoreButtonVariant` declares no `static const defaultVariant` today
      // (one of 7 variant enums that don't) — the reader reports that
      // honestly rather than guessing the first member.
      expect(button.variant?.defaultMember, isNull);
    });

    test('tabs.axes.variant — defaultVariant read from the enum body', () {
      final tabs = axes['tabs']!;
      expect(tabs.variant?.members, ['pill', 'underline']);
      expect(tabs.variant?.defaultMember, 'pill');
    });

    test('tabs — a component-owned size ladder lands in other', () {
      // `hasSize` is the reader's answer to one narrow question: does the
      // contract declare `CoreComponentSize get size`? The 2026-09-14
      // redesign narrowed this ladder to a Tabs-owned `CoreTabsSize`
      // (sm/md/lg), so the answer is no and the enum lands in `other`
      // beside `CoreChipSize` and `CoreThemeControllerSize`.
      //
      // That is not the canvas losing the axis — the Tabs builders
      // enumerate `Size` from `sizes.defaultsBySize` themselves, the way
      // every other component with its own ladder does. It only means the
      // reader does not promote it for them.
      final tabs = axes['tabs']!;
      expect(tabs.hasSize, isFalse);
      expect([for (final e in tabs.other) e.name], contains('CoreTabsSize'));
      expect(tabs.enabled, isFalse);
    });

    test('button 4-axis surface = the canvas arithmetic 9×6×2', () {
      final button = axes['button']!;
      expect(button.hasSize, isTrue);
      expect(button.enabled, isTrue);
      expect(button.state, isNull);
      final enabledStates = button.enabled ? 2 : 1;
      expect(
        button.variant!.members.length * sizeMembers.length * enabledStates,
        _kSpecButtonComboCount,
      );
    });
  });

  group('Scenario: state 축 판별 술어 — 정확 일치만', () {
    test('checkbox — neither state nor variant is an axis', () {
      // The widget takes `checked: bool?` and no `variant`, and the
      // builder declares Size / State / Checked for itself. An enum
      // named to the `Core{Component}State` convention would be promoted
      // on sight, so the contract declares none — a promoted one hands
      // the canvas `State=` members the code does not render.
      final checkbox = axes['checkbox']!;
      expect(checkbox.state, isNull);
      expect(checkbox.variant, isNull);
      expect(
        [for (final e in checkbox.other) e.name],
        isNot(contains('CoreCheckboxState')),
      );
      expect(checkbox.enabled, isTrue);
      expect(checkbox.hasSize, isTrue);
    });

    test('navigation_bar — non-convention enums land in other, not state', () {
      final navigationBar = axes['navigation_bar']!;
      expect(navigationBar.state, isNull);
      final otherNames = [for (final e in navigationBar.other) e.name];
      expect(otherNames, contains('CoreNavigationBarMode'));
      final mode = navigationBar.other.firstWhere(
        (e) => e.name == 'CoreNavigationBarMode',
      );
      // `sidebar` is `@Deprecated` (Sidebar replaces it), so it is named
      // as hidden rather than offered to the canvas.
      expect(mode.members, ['bar', 'rail']);
      expect(mode.hidden, ['sidebar']);
    });

    test('an enhanced enum carries its member constructor facts', () {
      // `CoreDisclosureKind` fixes each kind's outline and marker on the
      // enum itself (WCAG 1.4.1 — no style slot may erase the difference).
      // The canvas draws the same three kinds, so it reads those facts
      // here instead of restating them.
      final kind = axes['disclosure_badge']!.other.firstWhere(
        (e) => e.name == 'CoreDisclosureKind',
      );
      expect(kind.fields, {
        'open': {'stroke': 'solid', 'hasMarker': false},
        'commitment': {'stroke': 'solid', 'hasMarker': true},
        'private': {'stroke': 'dashed', 'hasMarker': false},
      });
      final json = axesJson(
        axes['disclosure_badge']!,
        componentSizeMembers: sizeMembers,
      );
      final other = json['other'] as List<Object?>;
      expect(
        other.whereType<Map<String, Object?>>().every(
          (e) => e.keys.join(',') == 'enum,members,hidden,fields',
        ),
        isTrue,
      );
      // A plain enum states no facts — the key is still present, empty.
      final stroke = axes['disclosure_badge']!.other.firstWhere(
        (e) => e.name == 'CoreDisclosureStroke',
      );
      expect(stroke.fields, isEmpty);
    });

    test('a library-private enum is not recorded as an axis', () {
      // `mockup/` holds `CoreMockupDevice` (a public axis the contract
      // takes) beside the layout computation's own `_Edge` — only the
      // public one is a value a caller can pass.
      final names = [for (final e in axes['mockup']!.other) e.name];
      expect(names, contains('CoreMockupDevice'));
      expect(names.where((n) => n.startsWith('_')), isEmpty);
    });

    test('near-miss State names stay out of the state axis', () {
      // `CoreCalendarDateState` ≠ `CoreCalendarState`,
      // `CoreValidationState` ≠ `CoreValidationBadgeState` — both are the
      // loose-suffix promotions the exact-match predicate exists to refuse.
      expect(axes['calendar']!.state, isNull);
      expect(axes['validation_badge']!.state, isNull);
      expect(
        [for (final e in axes['calendar']!.other) e.name],
        contains('CoreCalendarDateState'),
      );
      expect(
        [for (final e in axes['validation_badge']!.other) e.name],
        contains('CoreValidationState'),
      );
    });
  });

  test('axesJson — every key always present (no unions), other sorted', () {
    final json = axesJson(.empty, componentSizeMembers: sizeMembers);
    expect(json.keys.toList(), [
      'variant',
      'size',
      'state',
      'enabled',
      'other',
    ]);
    expect(json['variant'], isNull);
    expect(json['size'], isNull);
    expect(json['state'], isNull);
    expect(json['enabled'], isFalse);
    expect(json['other'], isEmpty);

    for (final component in axes.values) {
      final names = [for (final e in component.other) e.name];
      final sorted = [...names]..sort();
      expect(names, sorted);
    }
  });

  group('Scenario: props.slots — W/W? 슬롯 getter 기계 판독 (#4099)', () {
    test('dialog — single slots and the actions list in source order', () {
      final dialog = axes['dialog']!;
      expect(
        [for (final s in dialog.slots) (s.name, s.required, s.repeated)],
        [
          ('title', false, false),
          ('content', false, false),
          ('leading', false, false),
          ('trailing', false, false),
          ('actions', false, true),
        ],
      );
    });

    test('button — required child + optional leading/trailing', () {
      final button = axes['button']!;
      expect(
        [for (final s in button.slots) (s.name, s.required)],
        [('child', true), ('leading', false), ('trailing', false)],
      );
    });

    test('app_bar — List<W> leading/trailing are repeated, never required', () {
      // `List<W> get leading` is non-nullable but may be empty — a repeated
      // slot is never `required`.
      final appBar = axes['app_bar']!;
      final bySlot = {for (final s in appBar.slots) s.name: s};
      expect(bySlot['leading']?.repeated, isTrue);
      expect(bySlot['leading']?.required, isFalse);
      expect(bySlot['trailing']?.repeated, isTrue);
      expect(bySlot['title']?.repeated, isFalse);
    });

    test('propsJson — slots key always present, empty for slotless', () {
      expect(propsJson(.empty), {'slots': <Object>[]});
      final json = propsJson(axes['dialog']!);
      expect(json.keys.toList(), ['slots']);
      expect((json['slots'] as List).first, {
        'name': 'title',
        'required': false,
        'repeated': false,
      });
      expect((json['slots'] as List).last, {
        'name': 'actions',
        'required': false,
        'repeated': true,
      });
    });
  });
}
