import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/surface_style_scope.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:jaspr/jaspr.dart';

/// Rebuilds structural material chrome when the document's CSS axis changes.
/// An inherited scope wins over the document; server rendering stays scoped
/// to its request. Ordinary colour/blur changes continue to use CSS alone.
class SurfaceStyleBuilder extends StatefulComponent {
  /// Creates a scoped structural material observer.
  const SurfaceStyleBuilder({
    required this.builder,
    this.appBarScrollEdges = false,
    super.key,
  });

  /// The chrome subtree rebuilt when the active material changes.
  final Component Function(BuildContext context) builder;

  /// Retains the shared scroll-edge and centered-title DOM driver.
  final bool appBarScrollEdges;

  @override
  State<SurfaceStyleBuilder> createState() => _SurfaceStyleBuilderState();
}

class _SurfaceStyleBuilderState extends State<SurfaceStyleBuilder> {
  late CoreSurfaceStyleId _documentStyle;
  void Function()? _stop;
  void Function()? _stopScroll;

  @override
  void initState() {
    super.initState();
    _documentStyle = SurfaceStyleScope.currentSurfaceStyle();
    if (component.appBarScrollEdges) _stopScroll = listenForAppBarScrollEdges();
    _stop = listenForSurfaceStyleChange(() {
      final next = SurfaceStyleScope.currentSurfaceStyle();
      if (mounted && next != _documentStyle) {
        setState(() => _documentStyle = next);
      }
    });
  }

  @override
  Component build(BuildContext context) => SurfaceStyleScope(
    surfaceStyle:
        context
            .dependOnInheritedComponentOfExactType<SurfaceStyleScope>()
            ?.surfaceStyle ??
        _documentStyle,
    child: Builder(builder: component.builder),
  );

  @override
  void dispose() {
    _stop?.call();
    _stopScroll?.call();
    super.dispose();
  }
}
