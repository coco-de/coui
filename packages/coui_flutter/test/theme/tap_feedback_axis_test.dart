import 'dart:convert';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/clickable_feedback.dart';

/// Platform channel method name `SystemSound.play` sends.
const _kPlaySoundMethod = 'SystemSound.play';

/// Pinned so the sound path is on regardless of what the host reports —
/// `Clickable` only plays on a mobile platform, so a desktop default
/// would make every assertion below pass for the wrong reason.
const TargetPlatform _kMobile = TargetPlatform.iOS;

/// Enough pages that a plain page-number button is rendered and
/// tappable without any of the skip / ellipsis affordances collapsing.
const _kTotalPages = 5;

/// Records every platform-channel method the framework sends.
///
/// Returns a getter rather than the list itself because the recorder
/// rebuilds the list on each call (`avoid-collection-mutating-methods`),
/// so a captured reference would go stale after the first entry.
List<String> Function() _recordPlatformCalls(WidgetTester tester) {
  var calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      calls = [...calls, call.method];

      return null;
    },
  );

  return () => calls;
}

/// Records every message sent on the accessibility channel — the
/// transport `RenderObject.sendSemanticsEvent` ends up on.
List<Object?> Function() _recordSemanticsEvents(WidgetTester tester) {
  var events = <Object?>[];
  tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
    SystemChannels.accessibility,
    (message) async {
      events = [...events, message];

      return null;
    },
  );

  return () => events;
}

ThemeData _theme({required bool tapSoundEnabled}) => ThemeData.fromCore(
  CoreThemePresets.light.copyWith(tapSoundEnabled: tapSoundEnabled),
  platform: _kMobile,
);

Future<void> _pumpApp(
  WidgetTester tester,
  Widget child, {
  required ThemeData theme,
  CoreSurfaceStyleId style = CoreSurfaceStyleId.defaultId,
}) => tester.pumpWidget(
  CoUIApp(
    theme: theme,
    surfaceStyle: style,
    home: Center(child: child),
  ),
);

/// Painted press feedback and its resolved motion policy.
ClickableFeedback _pressWrapper(WidgetTester tester) =>
    clickableFeedback(tester).single;

void main() {
  group('the theme reaches a button the caller has no parameter for', () {
    // `Pagination` builds its page buttons itself, composing `Clickable`
    // without passing `enableFeedback` — so an app holding a
    // `Pagination` has no widget-level way to silence them. That is the
    // gap the axis exists to close, which is why the reach test uses
    // this component rather than a `Button` the test could configure.
    testWidgets('a pagination page number falls silent when the theme '
        'turns the sound off', (tester) async {
      final calls = _recordPlatformCalls(tester);
      await _pumpApp(
        tester,
        Pagination(page: 1, totalPages: _kTotalPages, onPageChanged: (_) {}),
        theme: _theme(tapSoundEnabled: false),
      );

      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      expect(
        calls().where((m) => m == _kPlaySoundMethod),
        isEmpty,
        reason:
            'the app stated silence at its root; a button CoUI built '
            'for itself is exactly the one the caller cannot reach, so '
            'it is the one that has to obey the theme',
      );
    });

    testWidgets('and still sounds when the theme says nothing', (tester) async {
      final calls = _recordPlatformCalls(tester);
      await _pumpApp(
        tester,
        Pagination(page: 1, totalPages: _kTotalPages, onPageChanged: (_) {}),
        theme: _theme(tapSoundEnabled: true),
      );

      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      expect(
        calls().where((m) => m == _kPlaySoundMethod),
        isNotEmpty,
        reason:
            'the default has to stay the platform default — otherwise '
            'the previous test passes because nothing ever sounds, and '
            'proves nothing about the switch',
      );
    });
  });

  group('the switch is audio only — it does not take the press chrome', () {
    // The tests that pin press chrome today all leave the axis at its
    // default, where `x && true == x` — so an implementation that ANDed
    // the axis into `Button.enableFeedback` would leave every one of
    // them green. These two turn the axis off, which is the only state
    // that can tell the two implementations apart.
    testWidgets('the press shrink survives a theme with the sound off', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        Button(onPressed: () {}, child: const Text('Primary')),
        theme: _theme(tapSoundEnabled: false),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Button)),
      );
      addTearDown(() async {
        await gesture.up();
      });
      await tester.pumpAndSettle();

      final scale = clickableFeedback(tester).single;
      expect(
        scale.scale,
        CoreHoverStyle.defaultScaleDownFactor,
        reason:
            'silencing an app must not also flatten every press '
            'animation in it — that is a visual regression wearing an '
            "audio switch's name",
      );
    });

    testWidgets('the neo-brutalism press shift survives it too', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        Button(onPressed: () {}, child: const Text('Primary')),
        theme: _theme(tapSoundEnabled: false),
        style: CoreSurfaceStyleId.neoBrutalism,
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Button)),
      );
      addTearDown(() async {
        await gesture.up();
      });
      await tester.pumpAndSettle();

      expect(
        _pressWrapper(tester).transform,
        isNot(Matrix4.identity()),
        reason:
            'this style carries the press signal in the shift rather '
            'than the shrink, so it is the case a shrink-only check '
            'would miss',
      );
    });
  });

  group('the value survives every seat it has to pass through', () {
    test('fromCore projects it — the factory is a selective copy', () {
      final theme = ThemeData.fromCore(
        CoreThemePresets.light.copyWith(tapSoundEnabled: false),
      );

      expect(theme.tapSoundEnabled, isFalse);
    });

    test('the platform default is the sound, not silence', () {
      expect(const ThemeData().tapSoundEnabled, isTrue);
      expect(const ThemeData.dark().tapSoundEnabled, isTrue);
      expect(
        ThemeData.fromCore(CoreThemePresets.light).tapSoundEnabled,
        isTrue,
      );
    });

    test('copyWith sets it, and leaves it alone when unmentioned', () {
      const on = ThemeData();
      final off = on.copyWith(tapSoundEnabled: () => false);

      expect(off.tapSoundEnabled, isFalse);
      expect(
        off.copyWith(scaling: () => 2).tapSoundEnabled,
        isFalse,
        reason: 'an unmentioned field must survive an unrelated copyWith',
      );
    });

    test('lerp carries it to both ends of a theme transition', () {
      // Built through `fromCore` because `lerp` interpolates the colour
      // scheme, which refuses unresolved tokens — the bare default
      // constructor cannot reach this path at all.
      final on = _theme(tapSoundEnabled: true);
      final off = _theme(tapSoundEnabled: false);

      expect(ThemeData.lerp(off, on, 0).tapSoundEnabled, isFalse);
      expect(
        ThemeData.lerp(off, on, 1).tapSoundEnabled,
        isTrue,
        reason:
            'lerp rebuilds the theme from scratch — a field omitted here '
            'reverts to the default for the whole crossfade, so the '
            'sound would come back only while a transition runs',
      );
    });

    test('two themes differing only in this are not equal', () {
      const on = ThemeData();
      const off = ThemeData(tapSoundEnabled: false);

      expect(on, isNot(off));
      expect(on.hashCode, isNot(off.hashCode));
    });

    test('the core carrier round-trips it through JSON', () {
      final json = TokenSerialization.toJson(
        CoreThemePresets.light.copyWith(tapSoundEnabled: false),
      );

      expect(TokenSerialization.fromJson(json).tapSoundEnabled, isFalse);
    });

    test('a payload written before the key existed still means sound', () {
      final json = TokenSerialization.toJson(CoreThemePresets.light);
      // Rebuild the map without the key rather than deleting a literal
      // `"tapSoundEnabled":false` from the text. The preset serialises
      // `true`, so matching the `false` spelling removed nothing and this
      // test read a payload that still carried the key — it asserted the
      // default of a value that was present, never the absent-key path.
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final stripped = jsonEncode({
        for (final entry in decoded.entries)
          if (entry.key != 'tapSoundEnabled') entry.key: entry.value,
      });

      // The premise has to hold, or the assertion below proves nothing.
      expect(stripped, isNot(contains('tapSoundEnabled')));
      expect(TokenSerialization.fromJson(stripped).tapSoundEnabled, isTrue);
    });
  });

  group('changing it reaches what already built', () {
    testWidgets('a dependent rebuilds when the theme swaps', (tester) async {
      // `==` is what `_InheritedTheme.updateShouldNotify` asks. A field
      // left out of it makes the new theme compare equal to the old one,
      // so nothing is marked dirty and the screen keeps the old value
      // while the theme holds the new one — the failure mode
      // `theme-axis-composition.md` calls out as the expensive one.
      //
      // The probe instance is reused across both pumps on purpose: an
      // identical child short-circuits `updateChild`, so the only thing
      // that can rebuild it is the inherited notification itself.
      var seen = <bool>[];
      final probe = _AxisProbe(record: (v) => seen = [...seen, v]);

      await tester.pumpWidget(_scope(tapSoundEnabled: true, child: probe));
      await tester.pumpWidget(_scope(tapSoundEnabled: false, child: probe));

      expect(seen, [true, false]);
    });
  });

  group('the accessibility event is not part of the bargain', () {
    testWidgets('a tap still announces itself with the sound turned off', (
      tester,
    ) async {
      // `Clickable` sends the semantics tap event and plays the sound in
      // the same method. Gating the method instead of the sound line
      // would trade an audio preference for an accessibility loss, and
      // nothing on screen would show it happened.
      // Disposed inline rather than through `addTearDown` — the
      // framework verifies handles at the end of the test *body*, before
      // tear-downs run.
      final handle = tester.ensureSemantics();

      final events = _recordSemanticsEvents(tester);
      final calls = _recordPlatformCalls(tester);
      await _pumpApp(
        tester,
        Button(onPressed: () {}, child: const Text('Primary')),
        theme: _theme(tapSoundEnabled: false),
      );

      await tester.tap(find.byType(Button));
      await tester.pumpAndSettle();

      expect(
        calls().where((m) => m == _kPlaySoundMethod),
        isEmpty,
        reason: 'the axis is off, so this tap must be silent',
      );
      expect(
        events().whereType<Map<Object?, Object?>>().where(
          (e) => e['type'] == 'tap',
        ),
        isNotEmpty,
        reason:
            'the tap event is what tells assistive technology a tap '
            'happened — it is not feedback an app can decline',
      );

      handle.dispose();
    });
  });
}

Widget _scope({required bool tapSoundEnabled, required Widget child}) => Theme(
  data: ThemeData(tapSoundEnabled: tapSoundEnabled),
  child: Directionality(textDirection: .ltr, child: child),
);

/// Reports the axis value every time it builds.
class _AxisProbe extends StatelessWidget {
  const _AxisProbe({required this.record});

  final ValueChanged<bool> record;

  @override
  Widget build(BuildContext context) {
    record(Theme.of(context).tapSoundEnabled);

    return const SizedBox.shrink();
  }
}
