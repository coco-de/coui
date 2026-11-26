// Runs slang_gpt over the component chrome source (`chrome/`), which has its
// own slang config next to the strings. slang reads its config from the
// working directory, so this wrapper changes into `chrome/` first — the
// package's own `slang.yaml` (docs-site strings) stays untouched.
//
// Usage (from packages/coui_i10n):
//   dart run tool/translate_chrome.dart [--target=<locale>] [--full]
//
// Without `--target` every chrome locale except the base (ko) and the
// hand-written `en` is translated — the 11-language set (S-18) the
// component chrome ships in. Afterwards regenerate the Dart classes with
// `dart run tool/gen_chrome_localizations.dart` and review the diff: the
// output is an AI draft (see `cross-platform/localization.md`).
//
// The API key comes from `--api-key=` or the OPENAI_API_KEY environment
// variable — never commit it.
import 'dart:io';

import 'package:slang_gpt/runner.dart';

const _kTargets = ['zh-Hans', 'ja', 'de', 'fr', 'es', 'pt', 'it', 'ru', 'ar'];

Future<void> main(List<String> arguments) async {
  final args = [...arguments];
  if (!args.any((a) => a.startsWith('--api-key='))) {
    final key = Platform.environment['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      stderr.writeln('Set OPENAI_API_KEY or pass --api-key=...');
      exitCode = 64;
      return;
    }
    args.add('--api-key=$key');
  }
  Directory.current = Directory('chrome');
  if (args.any((a) => a.startsWith('--target='))) {
    await runGpt(args);
  } else {
    for (final target in _kTargets) {
      await runGpt([...args, '--target=$target']);
    }
  }

  // slang_gpt writes a target whose file did not exist yet as
  // `_default_<locale>.i18n.json` (the docs-site package cleans these up
  // with fix_slang_gpt.sh) — give them their real name here.
  for (final file in Directory('i18n').listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    if (name.startsWith('_default_')) {
      file.renameSync('i18n/${name.substring('_default_'.length)}');
    }
  }
}
