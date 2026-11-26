import 'package:coui_flutter/coui_flutter.dart';

class ProgressIndeterminateExample extends StatelessWidget {
  const ProgressIndeterminateExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      child: Progress(),
    );
  }
}
