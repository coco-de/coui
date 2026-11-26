/// Returns a Flutter code snippet string for the Mockup component.
String mockupCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class MockupChainExample extends StatefulWidget {
  const MockupChainExample({super.key});

  @override
  State<MockupChainExample> createState() => _MockupChainExampleState();
}

class _MockupChainExampleState extends State<MockupChainExample> {
  @override
  Widget build(BuildContext context) {
    return MockupBrowser(
      addressBar: 'https://dev',
      child: const Text('페이지 콘텐츠'),
    ).radius8.primary;
  }
}''',
    'browser' =>
      '''
class MockupBrowserExample extends StatefulWidget {
  const MockupBrowserExample({super.key});

  @override
  State<MockupBrowserExample> createState() => _MockupBrowserExampleState();
}

class _MockupBrowserExampleState extends State<MockupBrowserExample> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 380,
      height: 200,
      child: MockupBrowser(
        addressBar: 'example.com',
        child: Center(child: Text('콘텐츠')),
      ),
    );
  }
}''',
    'code' =>
      '''
class MockupCodeExample extends StatefulWidget {
  const MockupCodeExample({super.key});

  @override
  State<MockupCodeExample> createState() => _MockupCodeExampleState();
}

class _MockupCodeExampleState extends State<MockupCodeExample> {
  @override
  Widget build(BuildContext context) {
    return MockupCode.fromString(
      "void main() {\\n  print('Hello!');\\n}",
    );
  }
}''',
    'app' =>
      '''
class MockupAppExample extends StatefulWidget {
  const MockupAppExample({super.key});

  @override
  State<MockupAppExample> createState() => _MockupAppExampleState();
}

class _MockupAppExampleState extends State<MockupAppExample> {
  @override
  Widget build(BuildContext context) {
    return MockupBrowser(
      addressBar: null,
      child: Text('앱 콘텐츠').bodyMedium.onSurface,
    );
  }
}''',
    'tablet' =>
      '''
class MockupDeviceTabletExample extends StatefulWidget {
  const MockupDeviceTabletExample({super.key});

  @override
  State<MockupDeviceTabletExample> createState() => _MockupDeviceTabletExampleState();
}

class _MockupDeviceTabletExampleState extends State<MockupDeviceTabletExample> {
  @override
  Widget build(BuildContext context) {
    return MockupDevice(
      device: .tablet,
      child: Text('앱 화면').bodyMedium.onSurface,
    );
  }
}''',
    'landscape' =>
      '''
class MockupDeviceLandscapeExample extends StatefulWidget {
  const MockupDeviceLandscapeExample({super.key});

  @override
  State<MockupDeviceLandscapeExample> createState() => _MockupDeviceLandscapeExampleState();
}

class _MockupDeviceLandscapeExampleState extends State<MockupDeviceLandscapeExample> {
  @override
  Widget build(BuildContext context) {
    return MockupDevice(
      orientation: .landscape,
      child: Text('앱 화면').bodyMedium.onSurface,
    );
  }
}''',
    _ =>
      '''
class MockupDeviceExample extends StatefulWidget {
  const MockupDeviceExample({super.key});

  @override
  State<MockupDeviceExample> createState() => _MockupDeviceExampleState();
}

class _MockupDeviceExampleState extends State<MockupDeviceExample> {
  @override
  Widget build(BuildContext context) {
    return MockupDevice(
      showCamera: true,
      showStatusBar: true,
      showGestureBar: true,
      child: Text('앱 화면').bodyMedium.onSurface,
    );
  }
}''',
  };
}

/// Snippet for the MockupBrowser docs page — the parent `browser` example.
String mockupBrowserCode(String? variant) {
  return switch (variant) {
    _ => mockupCode('browser'),
  };
}

/// Snippet for the MockupCode docs page — `MockupCodeExample`.
String mockupCodePageCode(String? variant) {
  return switch (variant) {
    'tones' =>
      '''
class MockupCodeTonesExample extends StatelessWidget {
  const MockupCodeTonesExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MockupCode.fromList(const [
      CoreCodeLine(text: '> flutter run', prefix: '1', tone: .muted),
      CoreCodeLine(text: 'Building web application...', prefix: '2'),
      CoreCodeLine(text: 'http://localhost:8080', prefix: '3', tone: .link),
      CoreCodeLine(text: 'Built in 12.4s', prefix: '4', tone: .success),
      CoreCodeLine(text: '2 unused imports', prefix: '5', tone: .warning),
      CoreCodeLine(text: 'lib/main.dart:12 failed', prefix: '6', tone: .error),
    ]);
  }
}''',
    _ =>
      '''
class MockupCodeExample extends StatefulWidget {
  const MockupCodeExample({super.key});

  @override
  State<MockupCodeExample> createState() => _MockupCodeExampleState();
}

class _MockupCodeExampleState extends State<MockupCodeExample> {
  @override
  Widget build(BuildContext context) {
    return MockupCode.fromString(
      "void main() {\\n  print('Hello!');\\n}",
      showLineNumbers: true,
    );
  }
}''',
  };
}

/// Snippet for the MockupDevice docs page — the parent phone example.
String mockupDeviceCode(String? variant) {
  return switch (variant) {
    'flat' =>
      '''
class MockupDeviceFlatExample extends StatefulWidget {
  const MockupDeviceFlatExample({super.key});

  @override
  State<MockupDeviceFlatExample> createState() => _MockupDeviceFlatExampleState();
}

class _MockupDeviceFlatExampleState extends State<MockupDeviceFlatExample> {
  @override
  Widget build(BuildContext context) {
    return MockupDevice(
      finish: .flat,
      child: Text('앱 화면').bodyMedium.onSurface,
    );
  }
}''',
    'screen-brightness' =>
      '''
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
}''',
    _ => mockupCode(null),
  };
}
