import 'package:coui_web/coui_web.dart';

class LoadingDotsExample extends StatelessComponent {
  const LoadingDotsExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Loading(variant: CoreLoadingVariant.dots);
  }
}
