import 'package:coui_flutter/coui_flutter.dart';

class HoverCardExample1 extends StatelessWidget {
  const HoverCardExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      child: LinkButton(child: const Text('@flutter'), onPressed: () {}),
      hoverBuilder: (context) {
        return const SurfaceCard(
          child: Basic(
            content: Text(
              'The Flutter SDK provides the tools to build beautiful apps for mobile, web, and desktop from a single codebase.',
            ),
            leading: FlutterLogo(),
            title: Text('@flutter'),
          ),
        ).sized(width: 300);
      },
    );
  }
}
