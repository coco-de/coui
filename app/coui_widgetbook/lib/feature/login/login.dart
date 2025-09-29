import 'package:core/core.dart' hide UseCase;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import 'login.mocks.dart';

/// LoginPage 유즈케이스
@GenerateNiceMocks([
  MockSpec<ThemeBloc>(),
  MockSpec<AuthBloc>(),
  MockSpec<LoginBloc>(),
])
@UseCase(name: 'LoginPage', type: LoginPage, path: '[Feature]')
Widget buildWidgetbookLoginUseCase(BuildContext context) {
  final hasError = context.knobs.boolean(label: '에러 발생');
  final loginState = LoginState.initial().copyWith(
    isLoading: context.knobs.boolean(label: '로딩'),
    loginStatus: hasError
        ? LoginStatus.failed(
            [
              const InvalidEmailFormatFailure(),
              const InvalidPasswordFormatFailure(),
            ][getIt<Faker>().datatype.number(max: 1)],
          )
        : const InitialLoginStatus(),
  );
  final bloc = MockLoginBloc();

  when(
    bloc.stream,
  ).thenAnswer((_) => Stream<LoginState>.fromIterable([loginState]));
  when(bloc.state).thenReturn(loginState);

  return buildLoginPage(bloc);
}

/// LoginPage 유즈케이스
Widget buildLoginPage(LoginBloc loginBloc) {
  final themeBloc = MockThemeBloc();
  final authBloc = MockAuthBloc();
  when(themeBloc.switchTheme(any)).thenAnswer((_) {});
  when(authBloc.logout()).thenAnswer((_) => Future<void>.value());

  return MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<ThemeBloc>(
        create: (BuildContext context) => MockThemeBloc(),
      ),
      BlocProvider<AuthBloc>(create: (BuildContext context) => MockAuthBloc()),
    ],
    child: LoginPage(bloc: loginBloc),
  );
}
