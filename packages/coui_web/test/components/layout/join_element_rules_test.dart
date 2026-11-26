import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/layout/join/join_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

void main() {
  for (final vertical in [false, true]) {
    for (final count in [0, 1, 2, 3]) {
      for (final radius in [null, CoreRadius.radius16]) {
        testComponents('the Element guard alone changes selectors '
            '($vertical, $count, $radius)', (tester) async {
          late String legacy;
          late String guarded;
          late String scope;
          final style = radius == null
              ? null
              : CoreJoinStyle(borderRadius: CoreBorderRadius.all(radius));
          pumpWithTheme(
            tester,
            Builder(
              builder: (context) {
                final resolved = resolveJoin(
                  context,
                  vertical: vertical,
                  count: count,
                  joinStyle: style,
                );
                scope = resolved.root.className
                    .split(' ')
                    .singleWhere((value) => value.startsWith('co-join-rule-'));
                legacy = resolveJoinCss(
                  context,
                  scopeId: 'caller-join',
                  vertical: vertical,
                  count: count,
                  joinStyle: style,
                );
                guarded = resolveJoinElementCss(
                  context,
                  join: resolved,
                  scopeId: 'caller-join',
                  vertical: vertical,
                  count: count,
                  joinStyle: style,
                );
                return const div([]);
              },
            ),
          );
          expect(legacy, isNot(contains(':where')));
          expect(guarded, contains('#caller-join:where(.$scope)'));
          expect(guarded.replaceAll(':where(.$scope)', ''), legacy);
          expect(
            guarded,
            contains(vertical ? 'min-width: 100%;' : 'min-height: 100%;'),
          );
          expect(
            guarded,
            isNot(contains(vertical ? 'min-height:' : 'min-width:')),
          );
        });
      }
    }
  }

  testComponents(
    'the public const bundle and direct legacy calls remain usable',
    (tester) async {
      const bundle = ResolvedJoin(
        root: WebElementChrome(className: 'caller'),
        items: [],
      );
      late String legacy;
      late String publicBundle;
      late String otherId;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            legacy = resolveJoinCss(
              context,
              scopeId: 'first',
              vertical: false,
              count: 1,
            );
            publicBundle = resolveJoinElementCss(
              context,
              join: bundle,
              scopeId: 'first',
              vertical: false,
              count: 1,
            );
            otherId = resolveJoinCss(
              context,
              scopeId: 'second',
              vertical: true,
              count: 3,
            );
            return const div([]);
          },
        ),
      );
      expect(publicBundle, legacy);
      expect(legacy, contains('#first > div > *'));
      expect(otherId, contains('#second > div:first-of-type > *'));
      expect(otherId, isNot(contains('#first')));
    },
  );
}
