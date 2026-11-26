import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kProxyScale = 1.5;
const _kProxyElevation = 8.0;
const _kTrackOffsetY = 12.0;
const _kSettleOffsetY = 44.0;
const _kChrome = WebElementChrome(className: 'row');
const _kResolved = ResolvedSortable(
  root: _kChrome,
  item: _kChrome,
  handle: _kChrome,
  handleRing: _kChrome,
  removeButtonStyle: CoreButtonStyle(),
  iconStyle: CoreIconStyle(),
  handleFocusOutlineStyle: null,
);

void main() {
  group('Sortable drag proxy (#2362)', () {
    test('CoreSortableStyle carries proxyScale / proxyElevation', () {
      const style = CoreSortableStyle(
        proxyScale: _kProxyScale,
        proxyElevation: _kProxyElevation,
      );
      expect(style.proxyScale, equals(_kProxyScale));
      expect(style.proxyElevation, equals(_kProxyElevation));
    });

    test('composeSortableItem lifts the drag source (scale + shadow)', () {
      final lifted = composeSortableItem(
        _kResolved,
        shiftPx: 0,
        isDragSource: true,
        suppressTransition: true,
        sessionActive: true,
        dragOffsetY: _kTrackOffsetY,
        proxyScale: _kProxyScale,
        proxyElevation: _kProxyElevation,
      );
      final props = lifted.inlineStyles?.properties ?? const {};
      // The source follows the pointer and lifts; the elevation becomes a
      // rem box-shadow. While suppressed, the transition drops so the
      // row tracks the pointer without lag.
      expect(
        props['transform'],
        equals('translate(0.0px, ${_kTrackOffsetY}px) scale($_kProxyScale)'),
      );
      expect(props['box-shadow'], contains('rem'));
      expect(props['transition'], equals('none'));
    });

    test('composeSortableItem re-enables the settle transition on release', () {
      final settling = composeSortableItem(
        _kResolved,
        shiftPx: 0,
        isDragSource: true,
        suppressTransition: false,
        sessionActive: false,
        dragOffsetY: _kSettleOffsetY,
        proxyScale: _kProxyScale,
        proxyElevation: _kProxyElevation,
      );
      final props = settling.inlineStyles?.properties ?? const {};
      // Release settle — the transform animates into the target slot via
      // the base `transition-transform` class (no inline suppression).
      expect(
        props['transform'],
        equals('translate(0.0px, ${_kSettleOffsetY}px) scale($_kProxyScale)'),
      );
      expect(props.containsKey('transition'), isFalse);
    });

    test('composeSortableItem drops pointer events during the session', () {
      final row = composeSortableItem(
        _kResolved,
        shiftPx: 0,
        isDragSource: false,
        suppressTransition: false,
        sessionActive: true,
        dragOffsetY: 0,
        proxyScale: _kProxyScale,
        proxyElevation: _kProxyElevation,
      );
      final props = row.inlineStyles?.properties ?? const {};
      // Stale-hover suppression — no row may match `:hover` (or receive
      // the JS hover recolour) while a drag session is active.
      expect(props['pointer-events'], equals('none'));
    });

    test('composeSortableItem leaves a non-source row unlifted', () {
      final base = composeSortableItem(
        _kResolved,
        shiftPx: 0,
        isDragSource: false,
        suppressTransition: false,
        sessionActive: false,
        dragOffsetY: 0,
        proxyScale: _kProxyScale,
        proxyElevation: _kProxyElevation,
      );
      // No runtime layer (not dragged, no shift) → base chrome unchanged.
      expect(identical(base, _kChrome), isTrue);
    });

    testComponents(
      'renders with a custom proxy style without errors',
      (tester) async {
        pumpWithTheme(
          tester,
          Sortable(
            itemCount: 2,
            itemBuilder: (index, handle, remove) =>
                div([Component.text('item $index')]),
            sortableStyle: const CoreSortableStyle(
              proxyScale: _kProxyScale,
              proxyElevation: _kProxyElevation,
            ),
          ),
        );
        expect(find.tag('div'), findsComponents);
      },
    );
  });
}
