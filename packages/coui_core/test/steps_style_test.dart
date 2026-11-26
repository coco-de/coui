// Tests for CoreStepsStyle nested merge / copyWith.
//
// Mirrors the merge-chain pattern established by CoreWindowPanelStyle:
// `design system default → theme.style → widget.stepsStyle` with the
// right-most non-null winning per field.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const double _kIndicatorSm = 16;
const double _kIndicatorLg = 32;
const double _kSpacingSm = 8;
const double _kSpacingLg = 24;
const double _kThicknessSm = 1;
const double _kThicknessLg = 2;

const _kIndicatorBg = CoreColor.token(CoreColors.surfaceContainer);
const _kIndicatorBgAlt = CoreColor.token(CoreColors.surface);

const _kGapSm = CoreGapStyle(size: _kSpacingSm);
const _kGapLg = CoreGapStyle(size: _kSpacingLg);

void main() {
  group('CoreStepsStyle.merge', () {
    test('null other returns this', () {
      const a = CoreStepsStyle(indicatorSize: _kIndicatorSm);
      expect(identical(a.merge(null), a), isTrue);
    });

    test('non-null fields in other override receiver', () {
      const base = CoreStepsStyle(
        indicatorSize: _kIndicatorSm,
        indicatorContentGapStyle: _kGapSm,
        connectorThickness: _kThicknessSm,
        indicatorColor: _kIndicatorBg,
      );
      const override = CoreStepsStyle(
        indicatorSize: _kIndicatorLg,
        connectorThickness: _kThicknessLg,
      );
      final merged = base.merge(override);
      expect(merged.indicatorSize, _kIndicatorLg);
      expect(merged.indicatorContentGapStyle, _kGapSm);
      expect(merged.connectorThickness, _kThicknessLg);
      expect(merged.indicatorColor, _kIndicatorBg);
    });

    test('dimensional fields (indicatorConnectorGapStyle / step paddings / '
        'iconSizeRatio) merge correctly', () {
      const base = CoreStepsStyle(
        indicatorConnectorGapStyle: _kGapSm,
        stepPadding: CoreEdgeInsets.only(bottom: _kSpacingSm),
        stepPaddingHorizontal: CoreEdgeInsets.only(
          top: _kSpacingSm,
          right: _kSpacingSm,
        ),
        iconSizeRatio: 0.4,
      );
      const override = CoreStepsStyle(
        indicatorConnectorGapStyle: _kGapLg,
        iconSizeRatio: 0.6,
      );
      final merged = base.merge(override);
      expect(merged.indicatorConnectorGapStyle?.size, _kSpacingLg);
      expect(
        merged.stepPadding,
        const CoreEdgeInsets.only(bottom: _kSpacingSm),
      );
      expect(
        merged.stepPaddingHorizontal,
        const CoreEdgeInsets.only(top: _kSpacingSm, right: _kSpacingSm),
      );
      expect(merged.iconSizeRatio, 0.6);
    });

    test('null fields in other preserve receiver', () {
      const base = CoreStepsStyle(
        indicatorSize: _kIndicatorSm,
        indicatorConnectorGapStyle: _kGapSm,
      );
      const override = CoreStepsStyle();
      final merged = base.merge(override);
      expect(merged.indicatorSize, _kIndicatorSm);
      expect(merged.indicatorConnectorGapStyle, _kGapSm);
    });

    test('nested gap slots merge recursively', () {
      const base = CoreStepsStyle(
        indicatorContentGapStyle: CoreGapStyle(size: _kSpacingSm),
      );
      const override = CoreStepsStyle(
        indicatorContentGapStyle: CoreGapStyle(
          color: CoreColor.token(CoreColors.primary),
        ),
      );
      final merged = base.merge(override);
      // Size preserved from base, color from override (CoreGapStyle.merge
      // is field-wise non-null).
      expect(merged.indicatorContentGapStyle?.size, _kSpacingSm);
      expect(
        merged.indicatorContentGapStyle?.color,
        const CoreColor.token(CoreColors.primary),
      );
    });
  });

  group('CoreStepsStyle.copyWith', () {
    test('replaces supplied fields, keeps the rest', () {
      const base = CoreStepsStyle(
        indicatorSize: _kIndicatorSm,
        indicatorContentGapStyle: _kGapSm,
        indicatorColor: _kIndicatorBg,
      );
      final next = base.copyWith(indicatorColor: _kIndicatorBgAlt);
      expect(next.indicatorSize, _kIndicatorSm);
      expect(next.indicatorContentGapStyle, _kGapSm);
      expect(next.indicatorColor, _kIndicatorBgAlt);
    });

    test('replaces dimensional fields', () {
      const base = CoreStepsStyle(
        indicatorConnectorGapStyle: _kGapSm,
        stepPadding: CoreEdgeInsets.only(bottom: _kSpacingSm),
        iconSizeRatio: 0.4,
      );
      final next = base.copyWith(
        indicatorConnectorGapStyle: _kGapLg,
        iconSizeRatio: 0.7,
      );
      expect(next.indicatorConnectorGapStyle, _kGapLg);
      expect(
        next.stepPadding,
        const CoreEdgeInsets.only(bottom: _kSpacingSm),
      );
      expect(next.iconSizeRatio, 0.7);
    });
  });

  group('CoreStepsStyle equality', () {
    test('identical field values compare equal', () {
      const a = CoreStepsStyle(
        indicatorSize: _kIndicatorSm,
        indicatorConnectorGapStyle: _kGapSm,
      );
      const b = CoreStepsStyle(
        indicatorSize: _kIndicatorSm,
        indicatorConnectorGapStyle: _kGapSm,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different dimensional field values compare unequal', () {
      const a = CoreStepsStyle(
        stepPadding: CoreEdgeInsets.only(bottom: _kSpacingSm),
      );
      const b = CoreStepsStyle(
        stepPadding: CoreEdgeInsets.only(bottom: _kSpacingLg),
      );
      expect(a, isNot(equals(b)));
    });

    test('different nested gap slot values compare unequal', () {
      const a = CoreStepsStyle(indicatorContentGapStyle: _kGapSm);
      const b = CoreStepsStyle(indicatorContentGapStyle: _kGapLg);
      expect(a, isNot(equals(b)));
    });
  });

  group('CoreStepsStyle redesign fields', () {
    test(
      'an upcoming indicator is the page fill inside an outlineVariant ring',
      () {
        expect(
          CoreStepsStyle.defaultIndicatorColor,
          const CoreColor.token(CoreColors.surface),
        );
        expect(
          CoreStepsStyle.defaultIndicatorBorderColor,
          const CoreColor.token(CoreColors.outlineVariant),
        );
        expect(
          CoreStepsStyle.defaultIndicatorBorderWidth,
          CoreStrokeWidth.stroke1,
        );
      },
    );

    test(
      'the connector leaving a completed step is primary, the rest quiet',
      () {
        expect(
          CoreStepsStyle.defaultActiveConnectorColor,
          const CoreColor.token(CoreColors.primary),
        );
        expect(
          CoreStepsStyle.defaultConnectorColor,
          const CoreColor.token(CoreColors.outlineVariant),
        );
      },
    );

    test('an upcoming number and title read onSurfaceVariant', () {
      expect(
        CoreStepsStyle.defaultInactiveLabelColor,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(
        CoreStepsStyle.defaultInactiveTitleColor,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(
        CoreStepsStyle.defaultTitleColor,
        const CoreColor.token(CoreColors.onSurface),
      );
    });

    test('the step number is semi-bold on the labelLarge role', () {
      final label = CoreStepsStyle.defaultLabelStyle;
      expect(label.token, CoreTextStyles.labelLarge);
      expect(label.fontWeight, CoreFontWeight.semiBold);
    });

    test('the horizontal connector gap is wider than the vertical one', () {
      expect(CoreStepsStyle.defaultIndicatorConnectorGapStyle.size, 4);
      expect(
        CoreStepsStyle.defaultIndicatorConnectorGapHorizontalStyle.size,
        8,
      );
    });

    test('the new fields merge, copy and compare', () {
      const a = CoreStepsStyle(
        activeConnectorColor: CoreColor.token(CoreColors.primary),
        indicatorBorderColor: CoreColor.token(CoreColors.outline),
        indicatorBorderWidth: 2,
        inactiveTitleColor: CoreColor.token(CoreColors.onSurface),
        indicatorConnectorGapHorizontalStyle: _kGapSm,
      );
      const b = CoreStepsStyle(
        activeConnectorColor: CoreColor.token(CoreColors.success),
        indicatorBorderWidth: 3,
        indicatorConnectorGapHorizontalStyle: CoreGapStyle(
          color: CoreColor.token(CoreColors.primary),
        ),
      );
      final merged = a.merge(b);
      expect(
        merged.activeConnectorColor,
        const CoreColor.token(CoreColors.success),
      );
      expect(
        merged.indicatorBorderColor,
        const CoreColor.token(CoreColors.outline),
      );
      expect(merged.indicatorBorderWidth, 3);
      expect(
        merged.inactiveTitleColor,
        const CoreColor.token(CoreColors.onSurface),
      );
      // The nested gap merges field by field, like the vertical one.
      expect(merged.indicatorConnectorGapHorizontalStyle?.size, _kSpacingSm);
      expect(
        merged.indicatorConnectorGapHorizontalStyle?.color,
        const CoreColor.token(CoreColors.primary),
      );

      for (final changed in [
        a.copyWith(activeConnectorColor: b.activeConnectorColor),
        a.copyWith(indicatorBorderColor: b.activeConnectorColor),
        a.copyWith(indicatorBorderWidth: 5),
        a.copyWith(inactiveTitleColor: b.activeConnectorColor),
        a.copyWith(
          indicatorConnectorGapHorizontalStyle:
              b.indicatorConnectorGapHorizontalStyle,
        ),
      ]) {
        expect(changed, isNot(equals(a)));
        expect(changed.hashCode, isNot(a.hashCode));
      }
      expect(a.copyWith(), equals(a));
      expect(a.copyWith().hashCode, a.hashCode);
    });
  });

  // The title role is bold, so every step carries a semi-bold of its own —
  // the current step states it again through its own overlay so a caller can
  // lift that step alone. Both sit on the titleSmall role.
  group('CoreStepsStyle title weights', () {
    test('every step is semi-bold on the titleSmall role', () {
      final title = CoreStepsStyle.defaultTitleStyle;
      expect(title.token, CoreTextStyles.titleSmall);
      expect(title.fontWeight, CoreFontWeight.semiBold);
    });

    test('currentTitleStyle merges, copies and compares', () {
      const a = CoreStepsStyle(
        currentTitleStyle: CoreTextStyle(fontWeight: CoreFontWeight.bold),
      );
      const b = CoreStepsStyle(
        currentTitleStyle: CoreTextStyle(fontWeight: CoreFontWeight.black),
      );
      expect(a.merge(b).currentTitleStyle?.fontWeight, CoreFontWeight.black);
      expect(
        const CoreStepsStyle().copyWith(currentTitleStyle: b.currentTitleStyle),
        equals(b),
      );
      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('the current step is semi-bold too and keeps the role', () {
      final current = CoreStepsStyle.defaultTitleStyle.merge(
        CoreStepsStyle.defaultCurrentTitleStyle,
      );
      expect(current.token, CoreTextStyles.titleSmall);
      expect(current.fontWeight, CoreFontWeight.semiBold);
    });
  });
  group('CoreStepsStyle failed indicator', () {
    test('a failed step wears the error fill with the onError cross', () {
      expect(
        CoreStepsStyle.defaultFailedIndicatorColor,
        const CoreColor.token(CoreColors.error),
      );
      expect(
        CoreStepsStyle.defaultFailedLabelColor,
        const CoreColor.token(CoreColors.onError),
      );
    });

    test('failed colours merge, copy and compare', () {
      const a = CoreStepsStyle(failedIndicatorColor: _kIndicatorBg);
      const b = CoreStepsStyle(
        failedIndicatorColor: _kIndicatorBgAlt,
        failedLabelColor: _kIndicatorBg,
      );
      final merged = a.merge(b);
      expect(merged.failedIndicatorColor, _kIndicatorBgAlt);
      expect(merged.failedLabelColor, _kIndicatorBg);
      expect(
        const CoreStepsStyle().copyWith(
          failedIndicatorColor: _kIndicatorBgAlt,
          failedLabelColor: _kIndicatorBg,
        ),
        equals(b),
      );
      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(b.hashCode));
    });
  });

  group('CoreStepsStyle.stepItemStyle', () {
    test('the hosted-row default restates nothing of the row', () {
      expect(CoreStepsStyle.defaultStepItemStyle, const CoreStepItemStyle());
    });

    test('merges field by field, so a colour patch keeps the height', () {
      const base = CoreStepsStyle(
        stepItemStyle: CoreStepItemStyle(minHeight: _kIndicatorLg),
      );
      const patch = CoreStepsStyle(
        stepItemStyle: CoreStepItemStyle(
          trailingStyle: CoreTextStyle(color: _kIndicatorBg),
        ),
      );
      final merged = base.merge(patch).stepItemStyle!;
      expect(merged.minHeight, _kIndicatorLg);
      expect(merged.trailingStyle?.color, _kIndicatorBg);
    });

    test('takes part in equality and copyWith', () {
      const a = CoreStepsStyle(
        stepItemStyle: CoreStepItemStyle(minHeight: _kIndicatorSm),
      );
      const b = CoreStepsStyle(
        stepItemStyle: CoreStepItemStyle(minHeight: _kIndicatorLg),
      );
      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(b.hashCode));
      expect(
        const CoreStepsStyle().copyWith(stepItemStyle: b.stepItemStyle),
        equals(b),
      );
    });
  });

  group('CoreStepsTheme.variantStyles', () {
    test('equal maps compare and hash alike', () {
      const a = CoreStepsTheme(
        variantStyles: {
          CoreStepsVariant.list: CoreStepsStyle(indicatorSize: _kIndicatorSm),
        },
      );
      const b = CoreStepsTheme(
        variantStyles: {
          CoreStepsVariant.list: CoreStepsStyle(indicatorSize: _kIndicatorSm),
        },
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('a different row is a different theme', () {
      const a = CoreStepsTheme(
        variantStyles: {
          CoreStepsVariant.list: CoreStepsStyle(indicatorSize: _kIndicatorSm),
        },
      );
      const b = CoreStepsTheme(
        variantStyles: {
          CoreStepsVariant.list: CoreStepsStyle(indicatorSize: _kIndicatorLg),
        },
      );
      expect(a, isNot(equals(b)));
    });

    test('the default variant is numbered — the shape Steps had', () {
      expect(CoreStepsVariant.defaultVariant, CoreStepsVariant.numbered);
    });
  });

  group('CoreStepStatus.effective', () {
    test('without statuses the steps are placed by currentStep', () {
      final statuses = [
        for (var i = 0; i < 4; i++)
          CoreStepStatus.effective(index: i, currentStep: 2),
      ];
      expect(statuses, [
        CoreStepStatus.done,
        CoreStepStatus.done,
        CoreStepStatus.current,
        CoreStepStatus.todo,
      ]);
    });

    test("an item's own status wins, the rest fall back on their index", () {
      const items = [
        CoreStepData(title: 'a'),
        CoreStepData(title: 'b', status: CoreStepStatus.failed),
        CoreStepData(title: 'c'),
        CoreStepData(title: 'd', status: CoreStepStatus.done),
      ];
      final statuses = [
        for (var i = 0; i < items.length; i++)
          CoreStepStatus.effective(
            index: i,
            currentStep: 1,
            status: items[i].status,
          ),
      ];
      expect(statuses, [
        CoreStepStatus.done,
        CoreStepStatus.failed,
        CoreStepStatus.todo,
        CoreStepStatus.done,
      ]);
    });
  });

  group('CoreStepStatus glyphs', () {
    test('a list row draws one closed circle per status', () {
      expect(
        {for (final s in CoreStepStatus.values) s: s.glyph},
        {
          CoreStepStatus.done: LucideIcons.circleCheck,
          CoreStepStatus.current: LucideIcons.circleDot,
          CoreStepStatus.todo: LucideIcons.circle,
          CoreStepStatus.failed: LucideIcons.circleX,
        },
      );
    });

    test('a numbered indicator marks done and failed, numbers the rest', () {
      expect(CoreStepStatus.done.indicatorGlyph, LucideIcons.check);
      expect(CoreStepStatus.failed.indicatorGlyph, LucideIcons.x);
      expect(CoreStepStatus.current.indicatorGlyph, isNull);
      expect(CoreStepStatus.todo.indicatorGlyph, isNull);
    });
  });
}
