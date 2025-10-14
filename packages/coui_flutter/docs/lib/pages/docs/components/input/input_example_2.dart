import 'package:coui_flutter/coui_flutter.dart';

class InputExample2 extends StatefulWidget {
  const InputExample2({super.key});

  @override
  State<InputExample2> createState() => _InputExample2State();
}

class _InputExample2State extends State<InputExample2> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      features: [
        InputFeature.leading(
          StatedWidget.builder(
            builder: (context, states) {
              if (states.hovered) {
                return const Icon(Icons.search);
              } else {
                return const Icon(Icons.search).iconMutedForeground();
              }
            },
          ),
          visibility: InputFeatureVisibility.textEmpty,
        ),
        InputFeature.clear(
          visibility: (InputFeatureVisibility.textNotEmpty &
                  InputFeatureVisibility.focused) |
              InputFeatureVisibility.hovered,
        ),
      ],
      initialValue: 'Hello World!',
      placeholder: const Text('Search something...'),
    );
  }
}
