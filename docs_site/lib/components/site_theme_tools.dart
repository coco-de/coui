import 'package:coui_web/coui_web.dart';

import 'style_setup_code.dart';
import 'surface_style_switcher.dart';

/// Review, copy and share the configuration currently being previewed.
class SiteThemeTools extends StatelessComponent {
  const SiteThemeTools({super.key});

  @override
  Component build(BuildContext context) {
    return details(classes: 'site-theme-tools', [
      summary([Text('선택한 스타일을 내 프로젝트에 적용하기').labelLarge.medium.onSurface]),
      Card(
        variant: CoreCardVariant.outlined,
        classes: 'site-theme-tools-content',
        attributes: {'data-theme-tools': '', 'data-theme-platform': 'flutter'},
        child: Component.fragment([
          div(classes: 'site-theme-tool-actions', [
            div(
              attributes: const {'role': 'group', 'aria-label': '설정 코드 플랫폼'},
              classes: 'site-theme-platforms',
              [
                for (final platform in ['flutter', 'web'])
                  Button(
                    enabled: true,
                    size: CoreComponentSize.sm,
                    variant: CoreButtonVariant.outline,
                    attributes: {'data-theme-platform-option': platform, 'aria-pressed': '${platform == 'flutter'}'},
                    child: Text(platform == 'flutter' ? 'Flutter' : 'Web'),
                  ),
              ],
            ),
            Button(
              enabled: true,
              size: CoreComponentSize.sm,
              attributes: const {'data-theme-copy': ''},
              child: Text('설정 복사'),
            ),
            Button(
              enabled: true,
              size: CoreComponentSize.sm,
              variant: CoreButtonVariant.outline,
              attributes: const {'data-theme-share': ''},
              child: Text('현재 조합 링크 복사'),
            ),
          ]),
          pre([
            code(
              attributes: const {'data-theme-code': ''},
              [Component.text(surfaceSetupCode(style: CoreSurfaceStyleId.defaultId, dark: false, forFlutter: true))],
            ),
          ]),
          Link(href: '/guides/theming', child: Text('초기 테마 설정 가이드 →').labelMedium),
          p(attributes: const {'data-theme-status': '', 'role': 'status', 'aria-live': 'polite'}, []),
          for (final option in SurfaceStyleSwitcher.offered)
            for (final mode in ['light', 'dark'])
              for (final platform in ['flutter', 'web'])
                Component.element(
                  tag: 'template',
                  attributes: {'data-theme-snippet': '${option.id.name}|$mode|$platform'},
                  children: [
                    pre([
                      Component.text(
                        surfaceSetupCode(style: option.id, dark: mode == 'dark', forFlutter: platform == 'flutter'),
                      ),
                    ]),
                  ],
                ),
        ]),
      ),
    ]);
  }
}
