/// Raw Tabs state layers retain their authored colour and the selected fill.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kHover = CoreColor(0x8012A43C);
const _kPressed = CoreColor(0x40B52E87);
const _kIndicator = CoreColor(0xFF334455);

void _handleSelect(int index) {}

Tabs _tabs(CoreTabsStyle style, {bool enabled = true}) => Tabs(
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
    .where((e) => e.styles?.properties.containsKey('height') ?? false)
    .toList();

List<String> _scopeClasses(DomComponent face) => (face.classes ?? '')
    .split(' ')
    .where((value) => value.startsWith('co-tabs-state-'))
    .toList();

List<String> _rules() => find.tag('style').evaluate().map((e) {
  final element = e.component as DomComponent;
  return element.children!.whereType<RawText>().map((e) => e.text).join();
}).toList();

void main() {
  for (final duration in [Duration.zero, const Duration(milliseconds: 250)]) {
    testComponents('raw state colours retain the resolved motion ($duration)', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        _tabs(
          CoreTabsStyle(
            hoverStateLayerColor: _kHover,
            pressedStateLayerColor: _kPressed,
            indicatorTransitionDuration: duration,
          ),
        ),
      );

      final rules = _rules().single;
      expect(rules, contains('@property --co-tabs-state-layer-color { '));
      expect(rules, contains(r'syntax: "\3c color\3e";'));
      expect(rules, contains('inherits: false; initial-value: transparent;'));
      expect(rules, contains('--co-tabs-state-layer-color:transparent;'));
      expect(
        rules,
        contains('linear-gradient(var(--co-tabs-state-layer-color),'),
      );
      expect(
        rules,
        contains('transition-property:all,--co-tabs-state-layer-color;'),
      );
      expect(
        rules,
        contains('transition-timing-function:var(--easing-ease-in-out);'),
      );
      for (final face in _faces()) {
        expect(
          face.styles!.properties['transition-duration'],
          'var(--coui-duration-${duration.inMilliseconds})',
        );
      }
    });
  }

  testComponents(
    'raw washes cover enabled faces and preserve a raw pill fill',
    (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        _tabs(
          const CoreTabsStyle(
            hoverStateLayerColor: _kHover,
            pressedStateLayerColor: _kPressed,
            activeIndicatorColor: _kIndicator,
          ),
        ),
      );

      final faces = _faces();
      expect(faces, hasLength(3));
      expect(_scopeClasses(faces[0]), hasLength(1));
      expect(_scopeClasses(faces[1]), _scopeClasses(faces[0]));
      expect(_scopeClasses(faces[2]), isEmpty);
      expect(
        faces[0].styles!.properties['background-color'],
        _kIndicator.toValue(),
      );
      final rules = _rules().single;
      expect(rules, contains(_kHover.toValue()));
      expect(rules, contains(_kPressed.toValue()));
      expect(rules, contains('background-image:linear-gradient('));
      expect(rules, isNot(contains('background-color:')));
      expect(rules.indexOf(':hover'), lessThan(rules.indexOf(':active')));
      for (final face in faces) {
        expect(face.classes, isNot(contains('hover:bg-')));
        expect(face.classes, isNot(contains('active:bg-')));
      }
    },
  );

  for (final hoverOnly in [true, false]) {
    testComponents('a mixed raw/token pair uses one layer path ($hoverOnly)', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        _tabs(
          CoreTabsStyle(
            hoverStateLayerColor: hoverOnly ? _kHover : null,
            pressedStateLayerColor: hoverOnly ? null : _kPressed,
          ),
        ),
      );

      final rules = _rules().single;
      expect(
        rules,
        contains(
          (hoverOnly ? _kHover : CoreTabsStyle.defaultHoverStateLayerColor)
              .toValue(),
        ),
      );
      expect(
        rules,
        contains(
          (hoverOnly ? CoreTabsStyle.defaultPressedStateLayerColor : _kPressed)
              .toValue(),
        ),
      );
      expect(_scopeClasses(_faces()[1]), hasLength(1));
    });
  }

  testComponents('explicit transparent washes keep the selected fill', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      _tabs(
        const CoreTabsStyle(
          hoverStateLayerColor: CoreColor.transparent,
          pressedStateLayerColor: CoreColor.transparent,
          activeIndicatorColor: _kIndicator,
        ),
      ),
    );

    expect(_rules().single, contains(CoreColor.transparent.toValue()));
    expect(
      _faces()[0].styles!.properties['background-color'],
      _kIndicator.toValue(),
    );
  });

  testComponents('a disabled bar has no state layer rules or classes', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      _tabs(
        const CoreTabsStyle(
          hoverStateLayerColor: _kHover,
          pressedStateLayerColor: _kPressed,
        ),
        enabled: false,
      ),
    );

    expect(_rules(), isEmpty);
    expect(_faces().expand(_scopeClasses), isEmpty);
  });

  testComponents(
    'default token faces compose fills through their owned scope',
    (
      tester,
    ) async {
      pumpWithTheme(tester, _tabs(const CoreTabsStyle()));

      expect(_rules(), hasLength(1));
      expect(_scopeClasses(_faces()[0]), hasLength(1));
      expect(_faces()[0].classes, isNot(contains('hover:bg-')));
      expect(_faces()[0].classes, isNot(contains('active:bg-')));
      expect(
        _faces()[0].styles!.properties['--co-tabs-token-hover-fill'],
        contains('rgb(var(--coui-on-surface)) 8%'),
      );
    },
  );

  testComponents('a reused const configuration gets distinct private scopes', (
    tester,
  ) async {
    const shared = Tabs(
      selectedIndex: 0,
      onChanged: _handleSelect,
      tabsStyle: CoreTabsStyle(
        hoverStateLayerColor: _kHover,
        pressedStateLayerColor: _kPressed,
      ),
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
    expect(_scopeClasses(faces[0]), hasLength(1));
    expect(_scopeClasses(faces[1]), hasLength(1));
    expect(_scopeClasses(faces[0]), isNot(_scopeClasses(faces[1])));
    expect(_rules(), hasLength(2));
  });

  testComponents('caller gradient and classes remain on the public tablist', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      _tabs(
        const CoreTabsStyle(
          hoverStateLayerColor: _kHover,
          pressedStateLayerColor: _kPressed,
        ),
      ).copyWith(
        id: 'caller-tabs',
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
        .singleWhere((e) => e.id == 'caller-tabs');
    expect(root.classes, contains('caller-paint'));
    expect(
      root.styles!.properties['background-image'],
      'linear-gradient(#123456,#abcdef)',
    );
    expect(_scopeClasses(root), isEmpty);
    expect(_rules().single, isNot(contains('#caller-tabs')));
  });

  testComponents('raw theme wash follows the same merged style as the faces', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      Theme(
        data: ThemeData.coui.copyWith(
          coreComponentTheme: const CoreComponentTheme(
            tabs: CoreTabsTheme(
              style: CoreTabsStyle(
                hoverStateLayerColor: _kHover,
                pressedStateLayerColor: _kPressed,
              ),
            ),
          ),
        ),
        child: _tabs(const CoreTabsStyle()),
      ),
    );

    expect(_rules().single, contains(_kHover.toValue()));
    expect(_rules().single, contains(_kPressed.toValue()));
    expect(_scopeClasses(_faces()[0]), hasLength(1));
  });

  testComponents(
    'custom token washes use composed fill values without a raw gradient',
    (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        _tabs(
          const CoreTabsStyle(
            hoverStateLayerColor: CoreColor.token(
              CoreColors.error,
              opacity: 0.25,
            ),
            pressedStateLayerColor: CoreColor.token(
              CoreColors.primary,
              opacity: 0.5,
            ),
          ),
        ),
      );

      expect(_rules(), hasLength(1));
      expect(_rules().single, isNot(contains('background-image:')));
      expect(_scopeClasses(_faces()[0]), hasLength(1));
      expect(_faces()[0].classes, isNot(contains('hover:bg-')));
      expect(_faces()[0].classes, isNot(contains('active:bg-')));
      expect(
        _faces()[0].styles!.properties['--co-tabs-token-hover-fill'],
        contains('rgb(var(--coui-error)) 25%'),
      );
      expect(
        _faces()[0].styles!.properties['--co-tabs-token-pressed-fill'],
        contains('rgb(var(--coui-primary)) 50%'),
      );
    },
  );
}
