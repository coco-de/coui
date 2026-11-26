/// Iconify's internal SVG uses the declared scalar size on both axes.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kOutside = IconName('test-size', 'wide');

DomComponent _host() =>
    find.tag('iconify-icon').evaluate().single.component as DomComponent;

void main() {
  testComponents('the fallback SVG gets a square em viewport by default', (
    tester,
  ) async {
    pumpWithTheme(tester, const Icon(_kOutside));

    expect(_host().attributes?['width'], '1em');
    expect(_host().attributes?['height'], '1em');
    expect(_host().attributes?['icon'], _kOutside.id);
  });

  for (final attributes in <Map<String, String>>[
    {'width': '48'},
    {'height': '32'},
    {'width': '48', 'height': '32'},
    {'width': 'none'},
    {'height': 'unset'},
    {'WIDTH': '2em'},
    {'Height': '2em'},
  ]) {
    testComponents('caller dimensions $attributes retain Iconify semantics', (
      tester,
    ) async {
      pumpWithTheme(tester, Icon(_kOutside, attributes: attributes));

      expect(_host().attributes?['width'], attributes['width']);
      expect(_host().attributes?['height'], attributes['height']);
      for (final entry in attributes.entries) {
        expect(_host().attributes?[entry.key], entry.value);
      }
    });
  }

  testComponents('caller CSS and metadata still reach the original host', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      const Icon(
        _kOutside,
        id: 'caller-icon',
        classes: 'caller-class',
        css: Styles(
          raw: {'font-size': '12px', 'width': '20px', 'height': '30px'},
        ),
        attributes: {'aria-label': 'Wide glyph', 'mode': 'svg'},
      ),
    );

    final host = _host();
    expect(host.id, 'caller-icon');
    expect(host.classes, contains('caller-class'));
    expect(host.styles!.properties['font-size'], '12px');
    expect(host.styles!.properties['width'], '20px');
    expect(host.styles!.properties['height'], '30px');
    expect(host.attributes?['aria-label'], 'Wide glyph');
    expect(host.attributes?['mode'], 'svg');
  });
}
