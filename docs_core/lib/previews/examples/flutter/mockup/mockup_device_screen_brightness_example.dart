import 'package:coui_flutter/coui_flutter.dart';

class MockupDeviceScreenBrightnessExample extends StatelessWidget {
  const MockupDeviceScreenBrightnessExample({super.key});

  @override
  Widget build(BuildContext context) {
    // A dark editor panel — dark whatever the page is — previewing a light
    // app: only the screen takes the light colours.
    return BrightnessScope(
      brightness: CoreBrightness.dark,
      child: Card(
        body: MockupDevice(
          finish: .flat,
          screenBrightness: CoreBrightness.light,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: CoreSpace.space12,
              children: [
                Text('라이트 앱').titleMedium.onSurface,
                Button(onPressed: () {}, child: const Text('열기')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
