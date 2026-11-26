import 'package:flutter/material.dart' as m;
import 'package:coui_flutter/coui_flutter.dart' as c;

void main() => m.runApp(const m.MaterialApp(home: IndicatorPreview()));

class IndicatorPreview extends m.StatefulWidget {
  const IndicatorPreview({super.key});
  @override
  m.State<IndicatorPreview> createState() => _IndicatorPreviewState();
}

class _IndicatorPreviewState extends m.State<IndicatorPreview> {
  int horizontal = 0;
  int vertical = 0;
  int round = 0;
  @override
  m.Widget build(m.BuildContext context) => c.Theme(
    data: const c.ThemeData(),
    child: m.Scaffold(
      body: m.Padding(
        padding: const m.EdgeInsets.all(32),
        child: m.Column(
          crossAxisAlignment: m.CrossAxisAlignment.start,
          children: [
            m.Text('Horizontal 18 × 6: ${horizontal + 1}'),
            c.DotIndicator(
              index: horizontal,
              length: 3,
              onChanged: (index) => setState(() => horizontal = index),
              dotIndicatorStyle: const c.CoreDotIndicatorStyle(
                dotSize: 6,
                activeLength: 18,
                spacing: 6,
                padding: c.CoreEdgeInsets.zero,
                activeColor: c.CoreColor(0xff4f46e5),
                inactiveColor: c.CoreColor(0xffd1d5db),
              ),
            ),
            m.Text('Vertical 6 × 18: ${vertical + 1}'),
            c.DotIndicator(
              direction: c.CoreAxis.vertical,
              index: vertical,
              length: 3,
              onChanged: (index) => setState(() => vertical = index),
              dotIndicatorStyle: const c.CoreDotIndicatorStyle(
                dotSize: 6,
                activeLength: 18,
                spacing: 6,
                padding: c.CoreEdgeInsets.zero,
                activeColor: c.CoreColor(0xff4f46e5),
                inactiveColor: c.CoreColor(0xffd1d5db),
              ),
            ),
            m.Text('Default round: ${round + 1}'),
            c.DotIndicator(
              index: round,
              length: 3,
              onChanged: (index) => setState(() => round = index),
              dotIndicatorStyle: const c.CoreDotIndicatorStyle(
                dotSize: 6,
                spacing: 6,
                padding: c.CoreEdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
