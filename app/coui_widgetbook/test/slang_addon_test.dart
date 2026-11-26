import 'package:coui_i10n/coui_i10n.dart';
import 'package:coui_widgetbook/add_on/slang_addon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('simultaneous previews load and switch locale together', (
    tester,
  ) async {
    final selectedLocale = ValueNotifier(const Locale('en'));
    addTearDown(selectedLocale.dispose);
    final addon = SlangAddon(
      locales: const [Locale('en'), Locale('ko')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<Locale>(
          valueListenable: selectedLocale,
          builder: (context, locale, _) => Column(
            children: [
              addon.apply(context, const _LocaleProbe(), locale),
              addon.apply(context, const _LocaleProbe(), locale),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('en'), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    selectedLocale.value = const Locale('ko');
    await tester.pumpAndSettle();
    expect(find.text('ko'), findsNWidgets(2));
    expect(tester.takeException(), isNull);

    selectedLocale.value = const Locale('en');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

class _LocaleProbe extends StatelessWidget {
  const _LocaleProbe();

  @override
  Widget build(BuildContext context) => Text(
    TranslationProvider.of(context).flutterLocale.languageCode,
  );
}
