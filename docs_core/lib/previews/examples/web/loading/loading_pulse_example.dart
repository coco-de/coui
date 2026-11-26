import 'package:coui_web/coui_web.dart';

class LoadingPulseExample extends StatelessComponent {
  const LoadingPulseExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Loading(variant: CoreLoadingVariant.pulse);
  }
}
