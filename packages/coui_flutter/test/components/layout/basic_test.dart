import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

const _kTestContentSpacing = 20.0;
const _kTestTitleSpacing = 6.0;

void main() {
  group('Basic', () {
    testWidgets('renders with title only', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Basic(title: material.Text('Title Only')),
        ),
      );

      expect(find.byType(Basic), findsOneWidget);
      expect(find.text('Title Only'), findsOneWidget);
    });

    testWidgets('renders with leading', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Basic(
            leading: material.Icon(material.Icons.star),
            title: material.Text('With Leading'),
          ),
        ),
      );

      expect(find.byType(Basic), findsOneWidget);
      expect(find.text('With Leading'), findsOneWidget);
      expect(find.byType(material.Icon), findsOneWidget);
    });

    testWidgets('renders with subtitle', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Basic(
            subtitle: material.Text('Subtitle'),
            title: material.Text('Title'),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
    });

    testWidgets('renders with content', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Basic(
            content: material.Text('Content body'),
            title: material.Text('Title'),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Content body'), findsOneWidget);
    });

    testWidgets('renders with trailing', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Basic(
            title: material.Text('Title'),
            trailing: material.Icon(material.Icons.chevron_right),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
    });

    testWidgets('renders with all optional params', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Basic(
            content: material.Text('Content'),
            leading: material.Icon(material.Icons.info),
            subtitle: material.Text('Subtitle'),
            title: material.Text('Title'),
            trailing: material.Icon(material.Icons.chevron_right),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });
  });

  group('Basic (alias)', () {
    testWidgets('renders with title', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Basic(title: material.Text('Layout Title')),
        ),
      );

      expect(find.byType(Basic), findsOneWidget);
      expect(find.text('Layout Title'), findsOneWidget);
    });

    testWidgets('renders with leading and title', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Basic(
            leading: material.Icon(material.Icons.home),
            title: material.Text('Home'),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
    });
  });

  group('Label', () {
    testWidgets('renders with text only', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Label(text: 'Label text'),
        ),
      );

      expect(find.byType(Label), findsOneWidget);
      expect(find.text('Label text'), findsOneWidget);
    });

    testWidgets('renders with short text', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Label(text: 'Label with leading'),
        ),
      );

      expect(find.text('Label with leading'), findsOneWidget);
    });

    testWidgets('renders with long text', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Label(text: 'Label with trailing'),
        ),
      );

      expect(find.text('Label with trailing'), findsOneWidget);
    });

    testWidgets('renders with full text', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Label(text: 'Full label'),
        ),
      );

      expect(find.text('Full label'), findsOneWidget);
    });
  });

  group('Basic subtitle ink', () {
    testWidgets('the subtitle reads onSurfaceSubtle, the title onSurface', (
      tester,
    ) async {
      late Color subtle;
      late Color surface;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            subtle = scheme
                .resolve(const CoreColor.token(CoreColors.onSurfaceSubtle))
                .toValue();
            surface = scheme
                .resolve(const CoreColor.token(CoreColors.onSurface))
                .toValue();
            return const Basic(
              title: Text('Title'),
              subtitle: Text('Subtitle'),
            );
          },
        ),
      );

      Color inkOf(String text) =>
          DefaultTextStyle.of(tester.element(find.text(text))).style.color!;
      expect(inkOf('Subtitle'), subtle);
      expect(inkOf('Title'), surface);
    });
  });

  group('Basic redesign props', () {
    testWidgets('showSubtitle false hides the subtitle', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Basic(
            title: material.Text('Title'),
            subtitle: material.Text('Subtitle'),
            showSubtitle: false,
          ),
        ),
      );
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsNothing);
    });

    testWidgets('trailingText draws Medium 15 before the icon, 4 apart', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Basic(
            title: material.Text('Title'),
            trailingText: material.Text('Value'),
            showTrailingIcon: true,
          ),
        ),
      );
      final style = tester
          .widget<material.DefaultTextStyle>(
            find
                .ancestor(
                  of: find.text('Value'),
                  matching: find.byType(material.DefaultTextStyle),
                )
                .first,
          )
          .style;
      expect(style.fontSize, CoreTypography.coui.labelXl.fontSize);
      expect(style.fontWeight, material.FontWeight.w500);
      final icon = find.byType(Icon);
      expect(icon, findsOneWidget);
      expect(
        tester.getTopLeft(icon).dx - tester.getTopRight(find.text('Value')).dx,
        closeTo(CoreSpace.space4, 0.01),
      );
    });

    testWidgets(
      'the trailing chevron is on by default, can be turned off, and yields to trailing',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(const Basic(title: material.Text('Title'))),
        );
        expect(find.byType(Icon), findsOneWidget);

        await tester.pumpWidget(
          _buildApp(
            const Basic(title: material.Text('Title'), showTrailingIcon: false),
          ),
        );
        expect(find.byType(Icon), findsNothing);

        await tester.pumpWidget(
          _buildApp(
            const Basic(
              title: material.Text('Title'),
              trailing: material.Text('Custom'),
              showTrailingIcon: true,
            ),
          ),
        );
        expect(find.byType(Icon), findsNothing);
        expect(find.text('Custom'), findsOneWidget);
      },
    );
  });
}
