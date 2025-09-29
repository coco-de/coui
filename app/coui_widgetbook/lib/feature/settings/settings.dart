import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life/life.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:settings/settings.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import 'settings.mocks.dart';

/// SettingsPage 유즈케이스
@GenerateNiceMocks([
  MockSpec<ThemeBloc>(),
  MockSpec<AuthBloc>(),
  MockSpec<SettingsBloc>(),
])
@UseCase(
  name: 'SettingPage',
  type: SettingsPage,
  path: '[Feature]',
)
Widget buildWidgetbookSettingsUseCase(BuildContext context) {
  final settingsState = SettingsState.initial().copyWith(
    marketing: context.knobs.boolean(label: '이벤트 알림 동의 여부'),
    push: context.knobs.boolean(label: '댓글 알림 동의 여부'),
    status: context.knobs.boolean(label: '로딩')
        ? const SettingsStatus.loading()
        : const SettingsStatus.loaded(),
  );
  final bloc = MockSettingsBloc();
  when(bloc.stream).thenAnswer(
    (_) => const Stream<SettingsState>.empty(),
  );
  when(bloc.state).thenReturn(settingsState);

  return buildSettingsPage(bloc);
}

/// SettingsPage 위젯
Widget buildSettingsPage(SettingsBloc settingsBloc) {
  final themeBloc = MockThemeBloc();
  final authBloc = MockAuthBloc();
  when(themeBloc.switchTheme(any)).thenAnswer((_) {});
  when(authBloc.logout()).thenAnswer((_) => Future<void>.value());

  return MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<ThemeBloc>(
        create: (BuildContext context) => MockThemeBloc(),
      ),
      BlocProvider<AuthBloc>(
        create: (BuildContext context) => MockAuthBloc(),
      ),
    ],
    child: SettingsPage(
      bloc: settingsBloc,
    ),
  );
}
