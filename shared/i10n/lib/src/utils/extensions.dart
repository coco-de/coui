import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';

/// 번역 확장 클래스
extension TranslationExtension on BuildContext {
  /// 번역 객체 반환
  Translations get i10n => Translations.of(this);
}
