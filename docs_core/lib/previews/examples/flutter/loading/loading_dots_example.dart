import 'package:coui_flutter/coui_flutter.dart';

class LoadingDotsExample extends StatelessWidget {
  const LoadingDotsExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Loading(variant: CoreLoadingVariant.dots);
  }
}
