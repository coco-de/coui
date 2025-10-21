import 'package:docs/pages/docs_page.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

class WebPreloaderPage extends StatelessWidget {
  const WebPreloaderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DocsPage(
      name: 'web_preloader',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Web Preloader').h1(),
          const Text('Customize how flutter load your web application').lead(),
          const Gap(32),
          Steps(
            children: [
              StepItem(
                content: [
                  const Text(
                    'If you don\'t have a web directory, create one.',
                  ).p(),
                  const CodeSnippet(
                    code: 'flutter create . --platforms=web',
                    mode: 'shell',
                  ).p(),
                  const Text(
                    '* If you\'re using legacy flutter web, you need to upgrade it using the command above. ',
                  )
                      .thenButton(
                        child: const Text('Click here for more information.'),
                        onPressed: () {
                          openInNewTab(
                            'https://docs.flutter.dev/platform-integration/web/initialization#upgrade-an-older-project',
                          );
                        },
                      )
                      .italic()
                      .muted()
                      .withPadding(top: 8),
                ],
                title: const Text('Creating a web directory'),
              ),
              StepItem(
                content: [
                  const Text(
                    'Next, select and copy one of these pre-made preloaders:',
                  ).p(),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Standard Preloader'),
                      Gap(8),
                      CodeSnippet(
                        code:
                            '<script src="https://cdn.jsdelivr.net/gh/coco-de/coui@latest/web_loaders/standard.js"></script>',
                        mode: 'javascript',
                      ),
                    ],
                  ).li().p(),
                ],
                title: const Text('Adding a script'),
              ),
              StepItem(
                content: [
                  const Text('Open your ')
                      .thenInlineCode('index.html')
                      .thenText(' file and paste the script inside the ')
                      .thenInlineCode('<head>')
                      .thenText(' tag.')
                      .p(),
                  const Text('For example:').p(),
                  const CodeSnippet(
                    code: '''
<!DOCTYPE html>
<html>
  <head>
    ...
    <script src="https://cdn.jsdelivr.net/gh/coco-de/coui@latest/web_loaders/standard.js"></script>
    ...
  </head>
  ...
</html>
                      ''',
                    mode: 'javascript',
                  ).p(),
                ],
                title: const Text('Paste the script'),
              ),
              StepItem(
                content: [
                  const Text('Run the app using the following command:').p(),
                  const CodeSnippet(
                    code: 'flutter run -d chrome',
                    mode: 'shell',
                  ).p(),
                ],
                title: const Text('Run the app'),
              ),
            ],
          ),
          const Gap(32),
          Alert(
            content: const Text(
              'If you have a preloader that you want to share, please create a pull request under the ',
            )
                .thenButton(
                  child: const Text('web_loaders'),
                  onPressed: () {
                    launchUrlString(
                      'https://github.com/coco-de/coui/tree/master/web_loaders',
                    );
                  },
                )
                .thenText(' directory.')
                .p(),
            leading: const Icon(Icons.info_outlined),
            title: const Text('Contributing'),
          ),
        ],
      ),
    );
  }
}
