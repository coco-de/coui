import 'package:flutter/material.dart';
import 'package:i10n/i10n.dart';
import 'package:throttling/throttling.dart';
import 'package:widgetbook/widgetbook.dart';

/// A [SlangAddon] for changing the active [Locale] via [Localizations].
class SlangAddon extends WidgetbookAddon<Locale> {
  /// SlangAddon 생성자.
  SlangAddon({
    this.initialLocale,
    required this.locales,
    required this.localizationsDelegates,
  }) : assert(
         locales.isNotEmpty,
         'locales cannot be empty',
       ),
       assert(
         initialLocale == null || locales.contains(initialLocale),
         'initialLocale must be in locales',
       ),
       super(name: 'Locale');

  /// 초기 로케일.
  final Locale? initialLocale;

  /// 지원하는 로케일.
  final List<Locale> locales;

  /// 로케일 델리게이트.
  final List<LocalizationsDelegate<Object>> localizationsDelegates;

  /// 디버용 디바운스.
  final deb = Debouncing<void>(duration: const Duration(milliseconds: 400));

  @override
  List<Field> get fields {
    return [
      ObjectDropdownField<Locale>(
        initialValue: initialLocale ?? locales.firstOrNull,
        labelBuilder: (locale) => locale.toLanguageTag(),
        name: 'name',
        values: locales,
      ),
    ];
  }

  @override
  Locale valueFromQueryGroup(Map<String, String> group) {
    final local =
        valueOf<Locale>('name', group) ?? initialLocale ?? locales.firstOrNull;
    deb.debounce(() {
      LocaleSettings.setLocaleRaw(local?.toLanguageTag() ?? '');
    });

    return local!;
  }

  /// [valueFromQueryGroup]에서 얻은 애드온 [setting]에 따라 사용 사례를 사용자 정의 위젯으로 래핑합니다.
  @override
  Widget buildUseCase(BuildContext context, Widget child, Locale setting) {
    return Localizations(
      delegates: localizationsDelegates,
      locale: setting,
      child: child,
    );
  }
}
