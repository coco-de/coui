import 'dart:io';
import 'package:coui_web/coui_web.dart' show ThemeConfig;

void main() {
  final config = ThemeConfig.defaults();
  File('/tmp/coui-indicator-web-head.html').writeAsStringSync(
    '<meta charset="utf-8"><script src="tailwind.js"></script>'
    '<script>${config.tailwindConfig}</script><style>${config.cssVariables}</style>'
    '<style>*{box-sizing:border-box} body{padding:32px;font:16px sans-serif}</style>',
  );
}
