import 'package:coui_web/coui_web.dart';

class LoadingBarExample extends StatelessComponent {
  const LoadingBarExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Loading(variant: CoreLoadingVariant.bar);
  }
}
