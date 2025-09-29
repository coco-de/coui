import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life/life.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sign_in_with_email/sign_in_with_email.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

import 'sign_in_with_email.mocks.dart';

/// SignInWithEmailPage 유즈케이스
@GenerateNiceMocks([
  MockSpec<ThemeBloc>(),
  MockSpec<AuthBloc>(),
  MockSpec<SignInWithEmailBloc>(),
])
@UseCase(
  name: 'SignInWithEmailPage',
  type: SignInWithEmailPage,
  path: '[Feature]',
)
Widget buildWidgetbookSignInWithEmailUseCase(BuildContext context) {
  final state = SignInWithEmailState.initial();

  final bloc = MockSignInWithEmailBloc();
  when(bloc.stream).thenAnswer(
    (_) => const Stream<SignInWithEmailState>.empty(),
  );
  when(bloc.state).thenReturn(
    state.copyWith(
      pageStatus: context.knobs.object.dropdown(
        label: 'Page status',
        labelBuilder: (value) {
          if (value == PageStatus.signIn) {
            return 'Sign in';
          } else if (value == PageStatus.createAccount) {
            return 'Create account';
          } else if (value == PageStatus.confirmEmail) {
            return 'Confirm email';
          } else if (value == PageStatus.forgotPassword) {
            return 'Forgot password';
          } else if (value == PageStatus.confirmPasswordReset) {
            return 'Confirm password reset';
          }

          return '';
        },
        options: [
          PageStatus.signIn,
          PageStatus.createAccount,
          PageStatus.confirmEmail,
          PageStatus.forgotPassword,
          PageStatus.confirmPasswordReset,
        ],
      ),
    ),
  );

  return buildSignInWithEmailPage(bloc);
}

/// SignInWithEmailPage 위젯
Widget buildSignInWithEmailPage(SignInWithEmailBloc signInWithEmailBloc) {
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
    child: SignInWithEmailPage(
      bloc: signInWithEmailBloc,
    ),
  );
}
