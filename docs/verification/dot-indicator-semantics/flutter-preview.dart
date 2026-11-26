import 'package:coui_flutter/coui_flutter.dart' as c;
import 'package:flutter/material.dart' as m;

void main() => m.runApp(const m.MaterialApp(home: Demo()));

class Demo extends m.StatefulWidget {
  const Demo({super.key});
  @override
  m.State<Demo> createState() => _DemoState();
}

class _DemoState extends m.State<Demo> {
  int selected = 0;
  @override
  m.Widget build(m.BuildContext context) => c.Theme(
    data: const c.ThemeData(),
    child: m.Scaffold(
      body: m.Padding(
        padding: const m.EdgeInsets.all(32),
        child: m.Column(
          crossAxisAlignment: m.CrossAxisAlignment.start,
          children: [
            m.Text('Interactive: ${selected + 1}'),
            c.DotIndicator(
              index: selected,
              length: 3,
              onChanged: (index) => setState(() => selected = index),
            ),
            const m.Text('Passive'),
            const c.DotIndicator(index: 1, length: 3),
            const m.Text('Carousel'),
            m.SizedBox(
              width: 300,
              height: 140,
              child: c.Carousel(
                items: const [m.Text('one'), m.Text('two'), m.Text('three')],
                transition: const c.CarouselTransition.sliding(),
                wrap: false,
                showNavigation: false,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
