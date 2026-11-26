import 'package:coui_web/coui_web.dart';

class MockupDeviceScreenBrightnessExample extends StatelessComponent {
  const MockupDeviceScreenBrightnessExample({super.key});

  @override
  Component build(BuildContext context) {
    // A dark editor panel — dark whatever the page is — previewing a light
    // app: only the screen takes the light colours.
    return BrightnessScope(
      brightness: CoreBrightness.dark,
      child: Card(
        body: MockupDevice(
          finish: .flat,
          screenBrightness: CoreBrightness.light,
          child: div(
            [
              Text('라이트 앱').titleMedium.onSurface,
              Button(onPressed: () {}, child: const Text('열기')),
            ],
            classes:
                'flex flex-col items-center justify-center h-full '
                'gap-${CoreSpace.scale.space12}',
          ),
        ),
      ),
    );
  }
}
