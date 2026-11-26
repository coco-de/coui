// Banner's wrap and the two colours the redesign moved, read off the markup
// the component emits.
//
// The markup is what the browser lays out, so this file pins the shape the
// layout depends on: the icon outside the wrapping box, the message column
// growing from its floor, the trailing group at its own width, and the two
// gaps. Whether Chrome actually wraps there is the probe's job
// (`tool/parity/test/web/banner_wrap_probe_test.dart`); this file cannot see
// a laid-out rect.
import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/display/banner/banner.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Every `<div>` the banner rendered, outermost first.
List<DomComponent> _divs() => find
    .tag('div')
    .evaluate()
    .map((element) => element.component)
    .whereType<DomComponent>()
    .toList();

/// The div whose className contains every class in [classes].
DomComponent _divWith(List<String> classes) => _divs().firstWhere((div) {
  final own = (div.classes ?? '').split(' ').toSet();
  return classes.every(own.contains);
});

/// The direct child divs of the element whose component is [parent].
List<DomComponent> _childDivs(DomComponent parent) {
  final element = find
      .tag('div')
      .evaluate()
      .firstWhere((e) => identical(e.component, parent));
  final out = <DomComponent>[];
  void visit(Element e) {
    e.visitChildren((child) {
      final c = child.component;
      if (c is DomComponent && c.tag == 'div') {
        out.add(c);
      } else {
        visit(child);
      }
    });
  }

  visit(element);
  return out;
}

void _pumpBanner(
  ComponentTester tester, {
  CoreBannerVariant variant = CoreBannerVariant.info,
  CoreBannerEmphasis emphasis = CoreBannerEmphasis.weak,
  bool withAction = true,
}) {
  pumpWithTheme(
    tester,
    Banner(
      message: const Component.text('Message'),
      description: const Component.text('Description'),
      variant: variant,
      emphasis: emphasis,
      onDismiss: () {},
      action: withAction
          ? Button(
              variant: .outline,
              onPressed: () {},
              child: const Component.text('Upgrade'),
            )
          : null,
    ),
  );
}

void main() {
  group('Banner message', () {
    testComponents('the title is labelLarge with no weight overlay', (
      tester,
    ) async {
      _pumpBanner(tester);
      final title = _divWith(['text-label-large']);
      expect(title.classes, isNot(contains('font-')));
      expect(title.styles?.properties['font-weight'], isNull);
    });

    for (final variant in CoreBannerVariant.values) {
      testComponents('weak $variant description is onSurfaceVariant', (
        tester,
      ) async {
        _pumpBanner(tester, variant: variant);
        final description = _divWith(['text-body-small']);
        expect(
          description.classes!.split(' '),
          contains('text-on-surface-variant'),
        );
      });
    }
  });

  group('Banner trailing wrap', () {
    testComponents('the body wraps, and the icon is out of its flow', (
      tester,
    ) async {
      _pumpBanner(tester);
      final root = _divs().first;
      final body = _divWith(['flex-wrap']);
      // The body is a direct child of the root, beside the icon span.
      expect(_childDivs(root).where((d) => d.tag == 'div'), contains(body));
      expect(body.classes!.split(' '), containsAll(['flex-1', 'min-w-0']));
      expect(body.styles?.properties['row-gap'], 'var(--coui-space-8)');
      expect(body.styles?.properties['column-gap'], 'var(--coui-space-12)');

      final children = _childDivs(body);
      expect(children, hasLength(2), reason: 'message column + trailing');
      final content = children.first;
      expect(
        content.styles?.properties['flex'],
        '1 1 var(--coui-layout-240)',
      );
      expect(
        content.styles?.properties['min-width'],
        'min(var(--coui-layout-240), 100%)',
      );
      final trailing = children.last;
      expect(trailing.classes!.split(' '), contains('shrink-0'));
    });

    testComponents('the icon hangs off the message column, centred on it', (
      tester,
    ) async {
      _pumpBanner(tester);
      final spans = find
          .tag('span')
          .evaluate()
          .map((e) => e.component)
          .whereType<DomComponent>()
          .where((c) => c.attributes?['aria-hidden'] == 'true')
          .toList();
      // The in-flow spacer keeps the icon's width (16) in the root row.
      final spacer = spans.firstWhere(
        (c) => c.styles?.properties['width'] == '1.0rem',
      );
      expect(spacer.classes, contains('shrink-0'));
      // The glyph is positioned over the column's full height, outside its
      // start edge by the icon gap, and centres itself in that box.
      final icon = spans.firstWhere(
        (c) => (c.classes ?? '').split(' ').contains('absolute'),
      );
      expect(icon.classes!.split(' '), containsAll(['items-center']));
      expect(icon.styles?.properties['top'], '0');
      expect(icon.styles?.properties['bottom'], '0');
      expect(
        icon.styles?.properties['inset-inline-end'],
        'calc(100% + var(--coui-space-12))',
      );
      final body = _divWith(['flex-wrap']);
      final content = _childDivs(body).first;
      expect(content.classes!.split(' '), contains('relative'));
    });

    testComponents('a dismiss-only banner keeps the dismiss gap on one line', (
      tester,
    ) async {
      _pumpBanner(tester, withAction: false);
      final body = _divWith(['flex-wrap']);
      expect(body.styles?.properties['column-gap'], 'var(--coui-space-8)');
    });
  });
}
