import 'package:coui_web/coui_web.dart';

/// Default Text preview — single-line basic usage so the docs landing
/// preview shows the simplest possible example. Other facets of the
/// component are split into dedicated variants for side-by-side
/// comparison.
class TextDefaultExample extends StatelessComponent {
  const TextDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Text('다람쥐 헌 쳇바퀴에 타고파').bodyMedium;
  }
}
