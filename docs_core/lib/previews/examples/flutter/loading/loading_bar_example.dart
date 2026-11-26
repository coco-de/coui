import 'package:coui_flutter/coui_flutter.dart';

class LoadingBarExample extends StatelessWidget {
  const LoadingBarExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Loading(variant: CoreLoadingVariant.bar);
  }
}
