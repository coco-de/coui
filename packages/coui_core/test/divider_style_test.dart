/// Tests for [CoreDividerStyle] — with the `childAlignment` axis (#4200)
/// as the field under scrutiny.
///
/// `verify_contracts.sh [8/8]` already greps `CoreXxxStyle` fields against
/// the four boilerplate bodies, but a shell grep and a value test fail on
/// different things: the grep sees a *mention*, this file sees the
/// *behaviour*. Dropping `childAlignment` from `Object.hash` while leaving
/// it in `==` would keep two unequal styles hashing alike, and a field
/// missing from equality is precisely the failure that stops a theme
/// rebuild from ever happening (`core/theme-axis-composition.md`).
library;

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kThickness = 2.0;
const _kIndent = 12.0;
const _kChildPadding = CoreEdgeInsets.symmetric(horizontal: 4);

void main() {
  group('CoreDividerStyle.childAlignment — value semantics', () {
    test('two alignments make two unequal styles', () {
      const start = CoreDividerStyle(childAlignment: .start);
      const end = CoreDividerStyle(childAlignment: .end);

      expect(start, isNot(end));
    });

    test('differing alignment changes hashCode', () {
      const start = CoreDividerStyle(childAlignment: .start);
      const end = CoreDividerStyle(childAlignment: .end);

      expect(start.hashCode, isNot(end.hashCode));
    });

    test('an explicit alignment differs from leaving it unset', () {
      const unset = CoreDividerStyle();
      const centered = CoreDividerStyle(childAlignment: .center);

      // `center` is the *default* the resolver falls back to, but the
      // style value itself must still distinguish "unspecified" from
      // "explicitly centred" — otherwise a theme that states centring
      // could never win over a widget-level override chain.
      expect(unset, isNot(centered));
    });

    test('same alignment with same other fields stays equal', () {
      const a = CoreDividerStyle(thickness: _kThickness, childAlignment: .end);
      const b = CoreDividerStyle(thickness: _kThickness, childAlignment: .end);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CoreDividerStyle.merge', () {
    test('non-null childAlignment in other wins', () {
      const base = CoreDividerStyle(childAlignment: .start);
      const patch = CoreDividerStyle(childAlignment: .end);

      expect(base.merge(patch).childAlignment, CoreDividerChildAlignment.end);
    });

    test('null childAlignment in other does not erase the receiver', () {
      const base = CoreDividerStyle(childAlignment: .start);

      expect(
        base.merge(const CoreDividerStyle()).childAlignment,
        CoreDividerChildAlignment.start,
      );
    });

    test('merging keeps the neighbouring fields intact', () {
      const base = CoreDividerStyle(
        thickness: _kThickness,
        indent: _kIndent,
        childPadding: _kChildPadding,
      );
      final merged = base.merge(
        const CoreDividerStyle(childAlignment: .end),
      );

      expect(merged.childAlignment, CoreDividerChildAlignment.end);
      expect(merged.thickness, _kThickness);
      expect(merged.indent, _kIndent);
      expect(merged.childPadding, _kChildPadding);
    });
  });

  group('CoreDividerStyle.copyWith', () {
    test('overrides childAlignment and preserves every other field', () {
      const base = CoreDividerStyle(
        color: CoreColor(0xFFFF0000),
        thickness: _kThickness,
        indent: _kIndent,
        endIndent: _kIndent,
        childAlignment: .start,
        childPadding: _kChildPadding,
      );
      final copy = base.copyWith(childAlignment: .end);

      expect(copy.childAlignment, CoreDividerChildAlignment.end);
      expect(copy.color, base.color);
      expect(copy.thickness, base.thickness);
      expect(copy.indent, base.indent);
      expect(copy.endIndent, base.endIndent);
      expect(copy.childPadding, base.childPadding);
    });

    test('omitting childAlignment preserves it', () {
      const base = CoreDividerStyle(childAlignment: .start);

      expect(
        base.copyWith(thickness: _kThickness).childAlignment,
        CoreDividerChildAlignment.start,
      );
    });
  });

  group('CoreDividerChildAlignment weights', () {
    // Both platforms read these two numbers instead of keeping their own
    // switch, so this is the single place a swapped leading/trailing
    // mapping can hide. A test that only looked at `center` would pass
    // through such a swap unharmed — hence the asymmetric cases.
    test('center shares the leftover extent', () {
      expect(CoreDividerChildAlignment.center.leadingFlex, 1);
      expect(CoreDividerChildAlignment.center.trailingFlex, 1);
    });

    test('start collapses the leading segment', () {
      expect(CoreDividerChildAlignment.start.leadingFlex, 0);
      expect(CoreDividerChildAlignment.start.trailingFlex, 1);
    });

    test('end collapses the trailing segment', () {
      expect(CoreDividerChildAlignment.end.leadingFlex, 1);
      expect(CoreDividerChildAlignment.end.trailingFlex, 0);
    });

    test('the design-system default is center', () {
      expect(
        CoreDividerStyle.defaultChildAlignment,
        CoreDividerChildAlignment.center,
      );
    });
  });
}
