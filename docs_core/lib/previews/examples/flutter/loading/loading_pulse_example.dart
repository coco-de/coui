import 'package:coui_flutter/coui_flutter.dart';

class LoadingPulseExample extends StatelessWidget {
  const LoadingPulseExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Loading(variant: CoreLoadingVariant.pulse);
  }
}
