/// Token Tabs compose washes over their existing fill with the shared motion.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kHoverFill = '--co-tabs-token-hover-fill';
const _kPressedFill = '--co-tabs-token-pressed-fill';
const _kAlphaIndicator = CoreColor(0x80334455);
const _kTokenStyle = CoreTabsStyle(
  hoverStateLayerColor: CoreColor.token(CoreColors.error, opacity: 0.25),
  pressedStateLayerColor: CoreColor.token(CoreColors.primary, opacity: 0.5),
);

void _handleSelect(int index) {}

Tabs _tabs(
  CoreTabsStyle style, {
  CoreTabVariant variant = CoreTabVariant.pill,
  bool enabled = true,
}) => Tabs(
  variant: variant,
  selectedIndex: 0,
  onChanged: enabled ? _handleSelect : null,
  tabsStyle: style,
  tabs: const [
    CoreTabItem<Component>(label: 'Selected'),
    CoreTabItem<Component>(label: 'Inactive'),
    CoreTabItem<Component>(label: 'Disabled', enabled: false),
  ],
);

List<DomComponent> _faces() => find
    .tag('span')
    .evaluate()
    .map((e) => e.component as DomComponent)
    .where((e) => e.styles?.properties.containsKey('padding') ?? false)
    .toList();

List<String> _scopes(DomComponent face) => (face.classes ?? '')
    .split(' ')
    .where((value) => value.startsWith('co-tabs-state-'))
    .toList();

List<String> _rules() => find.tag('style').evaluate().map((e) {
  final element = e.component as DomComponent;
  return element.children!.whereType<RawText>().map((e) => e.text).join();
}).toList();

void main() {
  for (final opacity in [0.0, 0.005, 0.009]) {
    for (final indicator in <CoreColor?>[
      null,
      const CoreColor(0xFF334455),
      _kAlphaIndicator,
    ]) {
      testComponents(
        'zero Web wash keeps the selected base ($opacity, $indicator)',
        (
          tester,
        ) async {
          pumpWithTheme(
            tester,
            _tabs(
              CoreTabsStyle(
                hoverStateLayerColor: CoreColor.token(
                  CoreColors.error,
                  opacity: opacity,
                ),
                pressedStateLayerColor: CoreColor.token(
                  CoreColors.primary,
                  opacity: opacity,
                ),
                activeIndicatorColor: indicator,
              ),
            ),
          );
          final face = _faces().first;
          final base =
              indicator?.toValue() ?? 'rgb(var(--coui-surface-raised))';
          expect(
            face.styles!.properties[_kHoverFill],
            'color-mix(in srgb, rgb(var(--coui-error)) 0%, $base)',
          );
          expect(
            face.styles!.properties[_kPressedFill],
            'color-mix(in srgb, rgb(var(--coui-primary)) 0%, $base)',
          );
          expect(
            face.styles!.properties['background-color'],
            indicator?.toValue(),
          );
        },
      );
    }
  }

  testComponents('default washes retain the selected pill base', (
    tester,
  ) async {
    pumpWithTheme(tester, _tabs(const CoreTabsStyle()));

    final faces = _faces();
    expect(faces, hasLength(3));
    expect(faces[0].classes, contains('bg-surface-raised'));
    expect(
      faces[0].styles!.properties[_kHoverFill],
      'color-mix(in srgb, rgb(var(--coui-on-surface)) 8%, '
      'rgb(var(--coui-surface-raised)))',
    );
    expect(
      faces[1].styles!.properties[_kPressedFill],
      'color-mix(in srgb, rgb(var(--coui-on-surface)) 16%, '
      'rgba(0, 0, 0, 0.00))',
    );
    expect(_scopes(faces[0]), _scopes(faces[1]));
    expect(_scopes(faces[0]), hasLength(1));
    expect(_scopes(faces[2]), isEmpty);
    expect(faces[0].classes, isNot(contains('hover:bg-')));
    expect(faces[0].classes, isNot(contains('active:bg-')));
    final rules = _rules().single;
    expect(rules, contains('background-color:var($_kHoverFill) !important;'));
    expect(rules, contains('background-color:var($_kPressedFill) !important;'));
    expect(rules.indexOf(':hover'), lessThan(rules.indexOf(':active')));
    expect(rules, isNot(contains('background-image:')));
    expect(rules, isNot(contains('@property')));
  });

  testComponents('caller alpha indicator stays inline under composed states', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      _tabs(_kTokenStyle.copyWith(activeIndicatorColor: _kAlphaIndicator)),
    );

    final face = _faces().first;
    expect(
      face.styles!.properties['background-color'],
      _kAlphaIndicator.toValue(),
    );
    expect(
      face.styles!.properties[_kHoverFill],
      'color-mix(in srgb, rgb(var(--coui-error)) 25%, '
      'rgba(51, 68, 85, 0.50))',
    );
    expect(
      _rules().single,
      contains('background-color:var($_kHoverFill) !important;'),
    );
  });

  testComponents(
    'fractional token alpha keeps its existing Web representation',
    (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        _tabs(
          const CoreTabsStyle(
            hoverStateLayerColor: CoreColor.token(
              CoreColors.error,
              opacity: 0.255,
            ),
            pressedStateLayerColor: CoreColor.token(
              CoreColors.primary,
              opacity: 0.375,
            ),
          ),
        ),
      );

      final face = _faces().first;
      expect(
        face.styles!.properties[_kHoverFill],
        contains('rgb(var(--coui-error)) 25%'),
      );
      expect(
        face.styles!.properties[_kPressedFill],
        contains('rgb(var(--coui-primary)) 37%'),
      );
      expect(face.styles!.properties[_kHoverFill], isNot(contains(' 26%')));
      expect(face.styles!.properties[_kPressedFill], isNot(contains(' 38%')));
    },
  );

  testComponents('underline washes use transparent base and retain indicator', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      _tabs(
        _kTokenStyle.copyWith(
          activeIndicatorColor: const CoreColor.token(CoreColors.primary),
        ),
        variant: CoreTabVariant.underline,
      ),
    );

    for (final face in _faces().take(2)) {
      expect(
        face.styles!.properties[_kHoverFill],
        'color-mix(in srgb, rgb(var(--coui-error)) 25%, rgba(0, 0, 0, 0.00))',
      );
      expect(face.styles!.properties['background-color'], isNull);
    }
    final indicators = _faces()
        .expand((face) => face.children!.whereType<DomComponent>())
        .where((e) => e.styles?.properties['position'] == 'absolute');
    expect(indicators, hasLength(3));
    expect(indicators.first.classes, contains('bg-primary'));
    for (final indicator in indicators) {
      expect(
        indicator.styles!.properties['transition-timing-function'],
        'var(--easing-ease-in-out)',
      );
    }
  });

  for (final duration in [Duration.zero, const Duration(milliseconds: 250)]) {
    testComponents(
      'token faces use CoreMove and resolved duration ($duration)',
      (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          _tabs(_kTokenStyle.copyWith(indicatorTransitionDuration: duration)),
        );

        for (final face in _faces()) {
          expect(
            face.styles!.properties['transition-timing-function'],
            'var(--easing-ease-in-out)',
          );
          expect(
            face.styles!.properties['transition-duration'],
            'var(--coui-duration-${duration.inMilliseconds})',
          );
        }
      },
    );
  }

  testComponents('a disabled token bar has no wash scopes or fill properties', (
    tester,
  ) async {
    pumpWithTheme(tester, _tabs(_kTokenStyle, enabled: false));

    expect(_rules(), isEmpty);
    for (final face in _faces()) {
      expect(_scopes(face), isEmpty);
      expect(face.styles!.properties[_kHoverFill], isNull);
      expect(face.styles!.properties[_kPressedFill], isNull);
      expect(
        face.styles!.properties['transition-timing-function'],
        'var(--easing-ease-in-out)',
      );
    }
  });

  testComponents('reused const token Tabs own independent state scopes', (
    tester,
  ) async {
    const shared = Tabs(
      selectedIndex: 0,
      onChanged: _handleSelect,
      tabsStyle: _kTokenStyle,
      tabs: [CoreTabItem<Component>(label: 'Selected')],
    );
    pumpWithTheme(
      tester,
      const div([
        div([shared]),
        div([shared]),
      ]),
    );

    final faces = _faces();
    expect(faces, hasLength(2));
    expect(_scopes(faces[0]), hasLength(1));
    expect(_scopes(faces[1]), hasLength(1));
    expect(_scopes(faces[0]), isNot(_scopes(faces[1])));
    expect(_rules(), hasLength(2));
  });

  testComponents('caller root gradient is retained outside the face scope', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      _tabs(_kTokenStyle).copyWith(
        id: 'caller-token-tabs',
        classes: 'caller-paint',
        css: const Styles(
          raw: {'background-image': 'linear-gradient(#123456,#abcdef)'},
        ),
      ),
    );

    final root = find
        .tag('div')
        .evaluate()
        .map((e) => e.component as DomComponent)
        .singleWhere((e) => e.id == 'caller-token-tabs');
    expect(root.classes, contains('caller-paint'));
    expect(
      root.styles!.properties['background-image'],
      'linear-gradient(#123456,#abcdef)',
    );
    expect(_scopes(root), isEmpty);
    expect(_scopes(_faces().first), hasLength(1));
    expect(_rules().single, isNot(contains('#caller-token-tabs')));
  });
}
