import 'package:coui_i10n/coui_i10n.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// A [SlangAddon] for changing the active [Locale] via [Localizations].
///
/// Mirrors Widgetbook 4's built-in `LocaleAddon`, but additionally syncs the
/// selected locale into slang's [LocaleSettings] so that the global `t`
/// translations used inside stories follow the addon selection.
class SlangAddon extends Addon<Locale> with SingleFieldOnly {
  /// SlangAddon 생성자.
  SlangAddon({
    required this.locales,
    required this.localizationsDelegates,
    Locale? initialLocale,
  }) : assert(
         locales.isNotEmpty,
         'locales cannot be empty',
       ),
       assert(
         initialLocale == null || locales.contains(initialLocale),
         'initialLocale must be in locales',
       ),
       super(
         name: 'Locale',
         initialValue: initialLocale ?? locales.first,
       );

  /// 지원하는 로케일.
  final List<Locale> locales;

  /// 로케일 델리게이트.
  final List<LocalizationsDelegate<Object>> localizationsDelegates;

  @override
  Field<Locale> get field {
    return ObjectDropdownField<Locale>(
      initialValue: initialValue,
      name: 'name',
      values: locales,
      labelBuilder: (locale) => locale.toLanguageTag(),
    );
  }

  @override
  Widget apply(BuildContext context, Widget child, Locale setting) {
    return _LocaleUpdater(
      locale: setting,
      delegates: localizationsDelegates,
      child: child,
    );
  }
}

/// 로케일 변경을 감지하고 적용하는 내부 위젯.
class _LocaleUpdater extends StatefulWidget {
  const _LocaleUpdater({
    required this.locale,
    required this.delegates,
    required this.child,
  });

  final Locale locale;
  final List<LocalizationsDelegate<Object>> delegates;
  final Widget child;

  @override
  State<_LocaleUpdater> createState() => _LocaleUpdaterState();
}

class _LocaleUpdaterState extends State<_LocaleUpdater> {
  int _localeRequest = 0;

  void _scheduleLocaleUpdate() {
    final request = ++_localeRequest;
    final locale = AppLocaleUtils.parse(widget.locale.toLanguageTag());
    // 다음 프레임에서 로케일 업데이트 (빌드/레이아웃 중 setState 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || request != _localeRequest) {
        return;
      }
      // Web locales are deferred libraries. build() awaits their loadLibrary
      // even when another preview is already loading the same locale; Slang's
      // loadLocale() returns early in that case and is not a readiness barrier.
      final _ = await locale.build();
      if (!mounted || request != _localeRequest) return;
      if (LocaleSettings.currentLocale != locale) {
        final _ = LocaleSettings.setLocaleSync(locale);
      }
      // The global `t` getters in demos do not subscribe to inherited changes.
      // Publish the loaded bundle and remount their content on locale changes.
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleLocaleUpdate();
  }

  @override
  void didUpdateWidget(_LocaleUpdater oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locale != widget.locale) {
      _scheduleLocaleUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final translations = LocaleSettings.instance.currentTranslations;
    return InheritedLocaleData<AppLocale, Translations>(
      translations: translations,
      child: Localizations(
        locale: widget.locale,
        delegates: widget.delegates,
        child: KeyedSubtree(
          key: ValueKey(translations.$meta.locale),
          child: widget.child,
        ),
      ),
    );
  }
}
