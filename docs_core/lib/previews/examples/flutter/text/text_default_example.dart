import 'package:coui_flutter/coui_flutter.dart';

/// Default Text preview — single-line basic usage so the docs landing
/// preview shows the simplest possible example (chain only).
class TextDefaultExample extends StatelessWidget {
  const TextDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('다람쥐 헌 쳇바퀴에 타고파').bodyMedium;
  }
}
