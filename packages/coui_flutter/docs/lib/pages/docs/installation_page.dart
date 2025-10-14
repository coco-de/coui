// ignore_for_file: library_private_types_in_public_api
import 'package:coui_flutter/coui_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../docs_page.dart';

class InstallationPage extends StatefulWidget {
  const InstallationPage({super.key});

  @override
  _InstallationPageState createState() => _InstallationPageState();
}

class _InstallationPageState extends State<InstallationPage> {
  final OnThisPage _manualKey = OnThisPage();
  final OnThisPage _experimentalKey = OnThisPage();
  @override
  Widget build(BuildContext context) {
    return DocsPage(
      name: 'installation',
      onThisPage: {
        'Stable Version': _manualKey,
        'Experimental Version': _experimentalKey,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Installation').h1(),
          const Text(
            'Install and configure coui_flutter in your project.',
          ).lead(),
          const Text('Stable Version').h2().anchored(_manualKey),
          const Gap(32),
          Steps(
            children: [
              StepItem(
                content: [
                  const Text(
                    'Create a new Flutter project using the following command:',
                  ).p(),
                  const CodeSnippet(
                    code: 'flutter create my_app\ncd my_app',
                    mode: 'shell',
                  ).p(),
                ],
                title: const Text('Creating a new Flutter project'),
              ),
              StepItem(
                content: [
                  const Text(
                    'Next, add the coui_flutter dependency to your project.',
                  ).p(),
                  const CodeSnippet(
                    code: 'flutter pub add coui_flutter',
                    mode: 'shell',
                  ).p(),
                ],
                title: const Text('Adding the dependency'),
              ),
              StepItem(
                content: [
                  const Text(
                    'Now, you can import the package in your Dart code.',
                  ).p(),
                  const CodeSnippet(
                    code: 'import \'package:coui_flutter/coui_flutter.dart\';',
                    mode: 'dart',
                  ).p(),
                ],
                title: const Text('Importing the package'),
              ),
              StepItem(
                content: [
                  const Text(
                    'Add the CouiApp widget to your main function.',
                  ).p(),
                  const CodeSnippet(
                    code: '''
void main() {
  runApp(
    CouiApp(
      title: 'My App',
      home: MyHomePage(),
      theme: ThemeData(
        colorScheme: ColorSchemes.darkZinc(),
        radius: 0.5,
      ),
    ),
  );
}
                    ''',
                    mode: 'dart',
                  ).p(),
                ],
                title: const Text('Adding the CouiApp widget'),
              ),
              StepItem(
                content: [
                  const Text('Run the app using the following command:').p(),
                  const CodeSnippet(code: 'flutter run', mode: 'shell').p(),
                ],
                title: const Text('Run the app'),
              ),
            ],
          ),
          const Text('Experimental Version').h2().anchored(_experimentalKey),
          const Text('Experimental versions are available on GitHub.').p(),
          const Text(
            'To use an experimental version, use git instead of version number in your '
            'pubspec.yaml file:',
          ).p(),
          const CodeSnippet(
            // code: 'coui_flutter:\n'
            //     '  git:\n'
            //     '    url: "https://github.com/coco-de/coui.git"',
            code: 'dependencies:\n'
                '  coui_flutter:\n'
                '    git:\n'
                '      url: "https://github.com/coco-de/coui.git"',
            mode: 'yaml',
          ).p(),
          const Text('See ')
              .thenButton(
                child: const Text('this page'),
                onPressed: () {
                  launchUrlString(
                    'https://dart.dev/tools/pub/dependencies#git-packages',
                  );
                },
              )
              .thenText(' for more information.')
              .p(),
          const Gap(16),
          const Alert(
            content: Text(
              'Experimental versions may contain breaking changes and are not recommended for production use. '
              'This version is intended for testing and development purposes only.',
            ),
            destructive: true,
            leading: Icon(Icons.warning),
            title: Text('Warning'),
          ),
        ],
      ),
    );
  }
}
