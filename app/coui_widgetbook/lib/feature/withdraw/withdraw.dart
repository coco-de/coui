import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life/life.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';
import 'package:withdraw/withdraw.dart';

import 'withdraw.mocks.dart';

/// WithdrawPage 유즈케이스
@GenerateNiceMocks([
  MockSpec<ThemeBloc>(),
  MockSpec<AuthBloc>(),
  MockSpec<WithdrawBloc>(),
])
@UseCase(
  name: 'WithdrawPage',
  type: WithdrawPage,
  path: '[Feature]',
)
Widget buildWidgetbookWithdrawUseCase(BuildContext context) {
  final withdrawState = WithdrawState.initial().copyWith(
    isAgree: context.knobs.boolean(
      label: 'isAgree',
    ),
  );
  final bloc = MockWithdrawBloc();
  when(bloc.stream).thenAnswer(
    (_) => Stream<WithdrawState>.fromIterable([withdrawState]),
  );
  when(bloc.state).thenReturn(withdrawState);

  return buildWithdrawPage(bloc);
}

/// WithdrawPage 위젯
Widget buildWithdrawPage(WithdrawBloc withdrawBloc) {
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
    child: WithdrawPage(
      bloc: withdrawBloc,
    ),
  );
}
