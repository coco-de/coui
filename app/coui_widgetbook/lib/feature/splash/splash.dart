import 'package:flutter/material.dart';
import 'package:splash/splash.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// SplashPage 유즈케이스
@UseCase(
  name: 'SplashPage',
  type: SplashPage,
  path: '[Feature]',
)
Widget buildWidgetbookSplashUseCase(BuildContext context) => const SplashPage();
