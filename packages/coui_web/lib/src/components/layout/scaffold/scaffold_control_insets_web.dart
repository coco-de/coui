import 'dart:async';
import 'dart:js_interop';

import 'package:coui_core/coui_core.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

/// Reads browser safe-area geometry on mount and viewport changes.
class ScaffoldControlInsets extends StatefulComponent {
  /// Creates a safe-area measurement host.
  const ScaffoldControlInsets({required this.builder, super.key});

  /// Builds with the current physical browser insets.
  final Component Function(BuildContext, CoreEdgeInsets, double) builder;
  @override
  State<ScaffoldControlInsets> createState() => _ScaffoldControlInsetsState();
}

class _ScaffoldControlInsetsState extends State<ScaffoldControlInsets> {
  CoreEdgeInsets _insets = CoreEdgeInsets.zero;
  double _height = double.infinity;
  web.HTMLElement? _probe;
  late final JSFunction _listener;
  Timer? _mount;

  @override
  void initState() {
    super.initState();
    _listener = ((web.Event _) => _measure()).toJS;
    web.window.addEventListener('resize', _listener);
    web.window.visualViewport?.addEventListener('resize', _listener);
    _mount = Timer(Duration.zero, _measure);
  }

  void _measure() {
    if (!mounted) return;
    final probe = _probe ??= web.HTMLDivElement()
      ..style.cssText =
          'position:fixed;visibility:hidden;pointer-events:none;'
          'padding:env(safe-area-inset-top,0px) env(safe-area-inset-right,0px) '
          'env(safe-area-inset-bottom,0px) env(safe-area-inset-left,0px);';
    if (!probe.isConnected) web.document.body?.appendChild(probe);
    final css = web.window.getComputedStyle(probe);
    double px(String value) => double.tryParse(value.replaceAll('px', '')) ?? 0;
    final next = CoreEdgeInsets.fromLTRB(
      px(css.paddingLeft),
      px(css.paddingTop),
      px(css.paddingRight),
      px(css.paddingBottom),
    );
    final height =
        web.window.visualViewport?.height ?? web.window.innerHeight.toDouble();
    if (next != _insets || height != _height) {
      setState(() {
        _insets = next;
        _height = height;
      });
    }
  }

  @override
  void dispose() {
    _mount?.cancel();
    web.window.removeEventListener('resize', _listener);
    web.window.visualViewport?.removeEventListener('resize', _listener);
    _probe?.remove();
    super.dispose();
  }

  @override
  Component build(BuildContext context) =>
      component.builder(context, _insets, _height);
}
