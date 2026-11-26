import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client;

void main() {
  client.Jaspr.initializeApp();
  client.runApp(Theme.defaults(child: const IndicatorPreview()));
}

class IndicatorPreview extends StatefulComponent {
  const IndicatorPreview({super.key});
  @override
  State<IndicatorPreview> createState() => _IndicatorPreviewState();
}

class _IndicatorPreviewState extends State<IndicatorPreview> {
  int horizontal = 0;
  int vertical = 0;
  int round = 0;
  int wide = 0;
  int long = 0;
  static const style = CoreDotIndicatorStyle(
    dotSize: 6,
    activeLength: 18,
    spacing: 6,
    padding: CoreEdgeInsets.zero,
    activeColor: CoreColor(0xff4f46e5),
    inactiveColor: CoreColor(0xffd1d5db),
  );

  @override
  Component build(BuildContext context) => div([
    p([text('Horizontal 18 × 6: ${horizontal + 1}')]),
    DotIndicator(
      index: horizontal,
      length: 3,
      onChanged: (value) => setState(() => horizontal = value),
      dotIndicatorStyle: style,
    ),
    p([text('Vertical 6 × 18: ${vertical + 1}')]),
    DotIndicator(
      direction: CoreAxis.vertical,
      index: vertical,
      length: 3,
      onChanged: (value) => setState(() => vertical = value),
      dotIndicatorStyle: style,
    ),
    p([text('Default round')]),
    DotIndicator(
      index: 0,
      length: 3,
      dotIndicatorStyle: const CoreDotIndicatorStyle(dotSize: 6),
    ),
    p([text('Interactive round: ${round + 1}')]),
    DotIndicator(
      index: round,
      length: 3,
      onChanged: (value) => setState(() => round = value),
      dotIndicatorStyle: const CoreDotIndicatorStyle(
        dotSize: 6,
        spacing: 6,
        padding: CoreEdgeInsets.zero,
      ),
    ),
    p([text('Wide spacing: ${wide + 1}')]),
    DotIndicator(
      index: wide,
      length: 3,
      onChanged: (value) => setState(() => wide = value),
      dotIndicatorStyle: const CoreDotIndicatorStyle(
        dotSize: 6,
        spacing: 30,
        padding: CoreEdgeInsets.zero,
      ),
    ),
    p([text('Long marker: ${long + 1}')]),
    DotIndicator(
      index: long,
      length: 3,
      onChanged: (value) => setState(() => long = value),
      dotIndicatorStyle: const CoreDotIndicatorStyle(
        dotSize: 6,
        activeLength: 60,
        spacing: 6,
        padding: CoreEdgeInsets.zero,
      ),
    ),
  ]);
}
