/// Returns a Web code snippet string for the Mockup component.
String mockupCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class MockupChainExample extends StatefulComponent {
  const MockupChainExample({super.key});

  @override
  State<MockupChainExample> createState() => _MockupChainExampleState();
}

class _MockupChainExampleState extends State<MockupChainExample> {
  @override
  Component build(BuildContext context) {
    return MockupBrowser(
      addressBar: 'https://coui.dev',
      child: Text('페이지 콘텐츠'),
    ).radius8.primary;
  }
}''',
    'browser' =>
      '''
class MockupBrowserExample extends StatefulComponent {
  const MockupBrowserExample({super.key});

  @override
  State<MockupBrowserExample> createState() => _MockupBrowserExampleState();
}

class _MockupBrowserExampleState extends State<MockupBrowserExample> {
  @override
  Component build(BuildContext context) {
    return div([
      MockupBrowser(
        addressBar: 'example.com',
        child: div([const Text('콘텐츠')], classes: 'flex items-center justify-center h-full'),
      ),
    ], styles: Styles(raw: {'width': '380px', 'height': '200px', 'max-width': '100%'}));
  }
}''',
    'code' =>
      '''
class MockupCodeExample extends StatefulComponent {
  const MockupCodeExample({super.key});

  @override
  State<MockupCodeExample> createState() => _MockupCodeExampleState();
}

class _MockupCodeExampleState extends State<MockupCodeExample> {
  @override
  Component build(BuildContext context) {
    return MockupCode.fromString(
      "void main() {\\n  print('Hello!');\\n}",
      showLineNumbers: true,
    );
  }
}''',
    'app' =>
      '''
class MockupAppExample extends StatefulComponent {
  const MockupAppExample({super.key});

  @override
  State<MockupAppExample> createState() => _MockupAppExampleState();
}

class _MockupAppExampleState extends State<MockupAppExample> {
  @override
  Component build(BuildContext context) {
    return MockupBrowser(
      addressBar: null,
      child: Text('앱 콘텐츠').bodyMedium.onSurface,
    );
  }
}''',
    'tablet' =>
      '''
class MockupDeviceTabletExample extends StatefulComponent {
  const MockupDeviceTabletExample({super.key});

  @override
  State<MockupDeviceTabletExample> createState() => _MockupDeviceTabletExampleState();
}

class _MockupDeviceTabletExampleState extends State<MockupDeviceTabletExample> {
  @override
  Component build(BuildContext context) {
    return MockupDevice(
      device: .tablet,
      child: Text('앱 화면').bodyMedium.onSurface,
    );
  }
}''',
    'landscape' =>
      '''
class MockupDeviceLandscapeExample extends StatefulComponent {
  const MockupDeviceLandscapeExample({super.key});

  @override
  State<MockupDeviceLandscapeExample> createState() => _MockupDeviceLandscapeExampleState();
}

class _MockupDeviceLandscapeExampleState extends State<MockupDeviceLandscapeExample> {
  @override
  Component build(BuildContext context) {
    return MockupDevice(
      orientation: .landscape,
      child: Text('앱 화면').bodyMedium.onSurface,
    );
  }
}''',
    _ =>
      '''
class MockupDeviceExample extends StatefulComponent {
  const MockupDeviceExample({super.key});

  @override
  State<MockupDeviceExample> createState() => _MockupDeviceExampleState();
}

class _MockupDeviceExampleState extends State<MockupDeviceExample> {
  @override
  Component build(BuildContext context) {
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

/// Snippet for the MockupCode docs page — the parent `code` example.
String mockupCodePageCode(String? variant) {
  return switch (variant) {
    'tones' =>
      '''
class MockupCodeTonesExample extends StatelessComponent {
  const MockupCodeTonesExample({super.key});

  @override
  Component build(BuildContext context) {
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
    _ => mockupCode('code'),
  };
}

/// Snippet for the MockupDevice docs page — the parent phone example.
String mockupDeviceCode(String? variant) {
  return switch (variant) {
    'flat' =>
      '''
class MockupDeviceFlatExample extends StatefulComponent {
  const MockupDeviceFlatExample({super.key});

  @override
  State<MockupDeviceFlatExample> createState() => _MockupDeviceFlatExampleState();
}

class _MockupDeviceFlatExampleState extends State<MockupDeviceFlatExample> {
  @override
  Component build(BuildContext context) {
    return MockupDevice(
      finish: .flat,
      child: Text('앱 화면').bodyMedium.onSurface,
    );
  }
}''',
    'screen-brightness' =>
      '''
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
                'gap-\${CoreSpace.scale.space12}',
          ),
        ),
      ),
    );
  }
}''',
    _ => mockupCode(null),
  };
}
