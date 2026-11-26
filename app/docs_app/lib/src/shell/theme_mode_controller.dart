/// 문서 앱의 라이트/다크 모드 상태와 그 토글 UI.
library;

import 'package:coui_flutter/coui_flutter.dart';

/// 라이트/다크 모드를 들고 있는 컨트롤러.
///
/// CoUI 의 `ThemeController` 위젯은 브랜드 팔레트 스와치 피커라 라이트/다크
/// 전환과는 무관하다 — 그래서 모드는 여기서 따로 들고 있는다.
class DocsThemeModeController extends ValueNotifier<CoreThemeMode> {
  /// 컨트롤러를 만든다. 기본값은 OS 설정을 따르는 [CoreThemeMode.system].
  DocsThemeModeController([super.value = CoreThemeMode.system]);

  /// 지금 보이는 것의 반대 모드로 뒤집는다.
  ///
  /// [dark] 는 *현재 화면에 그려지고 있는* 밝기다 — [CoreThemeMode.system]
  /// 은 그 자체로는 밝기를 모르므로 해석된 값을 받아야 첫 토글이 "보이는
  /// 것의 반대" 로 간다. [resolveDocsDarkMode] 로 구한 값을 넘긴다.
  void toggle({required bool dark}) {
    value = dark ? .light : .dark;
  }
}

/// [mode] 가 [context] 에서 다크로 해석되는지 판정한다.
///
/// [CoreThemeMode.system] 은 호스트 OS 설정을 따른다.
bool resolveDocsDarkMode(BuildContext context, CoreThemeMode mode) {
  return switch (mode) {
    .dark => true,
    .light => false,
    .system => MediaQuery.platformBrightnessOf(context) == .dark,
  };
}

/// [DocsThemeModeController] 를 서브트리에 흘려보내는 스코프.
///
/// `InheritedNotifier` 라 컨트롤러 값이 바뀌면 이 스코프를 읽은 위젯만
/// 다시 빌드된다.
class DocsThemeModeScope extends InheritedNotifier<DocsThemeModeController> {
  /// 스코프를 만든다.
  const DocsThemeModeScope({
    required DocsThemeModeController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// 가장 가까운 조상의 컨트롤러. 없으면 `null`.
  static DocsThemeModeController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DocsThemeModeScope>()
        ?.notifier;
  }

  /// 가장 가까운 조상의 컨트롤러. 없으면 던진다.
  static DocsThemeModeController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'No DocsThemeModeScope found in context');
    return controller!;
  }
}

/// 라이트/다크를 뒤집는 앱바 버튼.
///
/// 조상에 [DocsThemeModeScope] 가 없으면 아무것도 그리지 않는다 — 모드를
/// 바꿀 대상이 없는데 죽은 버튼을 보여주지 않기 위해서다.
class DocsThemeModeToggle extends StatelessWidget {
  /// 토글 버튼을 만든다.
  const DocsThemeModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DocsThemeModeScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();

    final dark = resolveDocsDarkMode(context, controller.value);

    return Button(
      onPressed: () => controller.toggle(dark: dark),
      variant: .ghost,
      size: .sm,
      child: Icon(dark ? LucideIcons.sun : LucideIcons.moon),
    );
  }
}
