import 'package:coui_flutter/coui_flutter.dart';

/// Keeps the material control active when a palette demo creates a new theme.
ThemeData applyPreviewSurface(BuildContext context, ThemeData base) =>
    applySurfaceStyle(
      base,
      surfaceStyle: SurfaceStyleScope.of(context),
      highContrast: MediaQuery.maybeOf(context)?.highContrast ?? false,
      reduceTransparency: Theme.of(context).reduceTransparency,
    );

/// A quiet reference pattern that makes transparent materials observable.
class SurfacePreviewBackground extends StatelessWidget {
  /// Paints behind the story without adding a surface or intercepting input.
  const SurfacePreviewBackground({required this.child, super.key});

  /// The actual catalog story.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      // Keep the child's position stable while changing material so a
      // selection, an open menu or a scroll position is not reset.
      painter: SurfaceStyleScope.of(context) == .liquidGlass
          ? _SurfaceReferencePainter(
              primary: scheme.primary.toValue(),
              secondary: scheme.tertiary.toValue(),
            )
          : null,
      child: child,
    );
  }
}

class _SurfaceReferencePainter extends CustomPainter {
  const _SurfaceReferencePainter({
    required this.primary,
    required this.secondary,
  });

  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: .18),
            secondary.withValues(alpha: .28),
          ],
        ).createShader(rect),
    );
    final grid = Paint()
      ..color = primary.withValues(alpha: .18)
      ..strokeWidth = 1;
    const step = 48.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(_SurfaceReferencePainter oldDelegate) =>
      primary != oldDelegate.primary || secondary != oldDelegate.secondary;
}

/// Scrollable content beneath the normal AppBar and NavigationBar stories.
///
/// Material still comes exclusively from the catalog's material control.
class SurfaceChromePreview extends StatefulWidget {
  /// Creates a preview with either or both kinds of navigation chrome.
  const SurfaceChromePreview({this.header, this.footer, super.key});

  /// The AppBar being demonstrated.
  final Widget? header;

  /// The NavigationBar being demonstrated.
  final Widget? footer;

  @override
  State<SurfaceChromePreview> createState() => _SurfaceChromePreviewState();
}

class _SurfaceChromePreviewState extends State<SurfaceChromePreview> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PrimaryScrollController(
    controller: _scroll,
    // Keep content below navigation at rest and scroll it beneath the clear
    // host, as a native navigation container does with its content insets.
    child: Stack(
      fit: StackFit.expand,
      children: [
        ListView.builder(
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(
            CoreSpace.space16,
            widget.header == null ? CoreSpace.space16 : CoreSize.size80,
            CoreSpace.space16,
            CoreSpace.space104,
          ),
          itemCount: 16,
          itemBuilder: (context, index) => Container(
            height: 160,
            margin: const EdgeInsets.only(bottom: CoreSpace.space16),
            padding: const EdgeInsets.all(CoreSpace.space20),
            alignment: Alignment.bottomLeft,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CoreRadius.radius24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: index.isEven
                    ? const [Color(0xFF245A84), Color(0xFF51A59D)]
                    : const [Color(0xFF8D465D), Color(0xFFC58C67)],
              ),
            ),
            child: Text(
              'Collection ${index + 1}',
              style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 24),
            ),
          ),
        ),
        if (widget.header != null)
          Align(alignment: Alignment.topCenter, child: widget.header),
        if (widget.footer != null)
          Align(alignment: Alignment.bottomCenter, child: widget.footer),
      ],
    ),
  );
}
