#!/usr/bin/env python3
"""Comprehensive Flutter 3.35 compatibility fix script"""
import re
import os
from pathlib import Path

def fix_file(filepath, patterns):
    """Apply regex patterns to a file"""
    if not os.path.exists(filepath):
        return False

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content
    for pattern, replacement, description in patterns:
        content = re.sub(pattern, replacement, content, flags=re.MULTILINE | re.DOTALL)

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

base = "/Users/dongwoo/Development/cocode/uiux/coui/packages/coui_flutter/lib/src/components"

# Pattern format: (regex_pattern, replacement, description)
fixes = {
    # dot_indicator.dart - dotBuilder parameter order (context, i, isSelected) -> (i, isSelected, context)
    f"{base}/display/dot_indicator.dart": [
        (r'dotBuilder\(context, i, i == index\)',
         r'dotBuilder(i, i == index, context)',
         "Fix dotBuilder parameter order"),
    ],

    # color_picker.dart - multiple parameter order issues
    f"{base}/form/color_picker.dart": [
        # _buildGridTile(context, color, theme) -> _buildGridTile(color, context, theme)
        (r'_buildGridTile\(context, color, theme\)',
         r'_buildGridTile(color, context, theme)',
         "Fix _buildGridTile parameter order"),

        # previewLabelBuilder(context, color) -> previewLabelBuilder(color, context)
        (r'widget\.previewLabelBuilder!\(context, color\)',
         r'widget.previewLabelBuilder!(color, context)',
         "Fix previewLabelBuilder parameter order"),

        # ui.decodeImageFromPixels parameter order: (width, height, format, pixels, callback) -> (pixels, width, height, format, callback)
        (r'ui\.decodeImageFromPixels\(\s*image\.width,\s*image\.height,\s*ui\.PixelFormat\.rgba8888,\s*Uint8List\.fromList\(pixels\),\s*\(ui\.Image img\)',
         r'ui.decodeImageFromPixels(\n      Uint8List.fromList(pixels),\n      image.width,\n      image.height,\n      ui.PixelFormat.rgba8888,\n      (ui.Image img)',
         "Fix decodeImageFromPixels parameter order"),

        # Remove invalid value.toDouble() on Color
        (r'return value\.toDouble\(\);',
         r'return value;',
         "Remove toDouble on Color"),

        # _previewWidget(context, color) -> _previewWidget(color, context)
        (r'_previewWidget\(\s*context,\s*_preview!\.pickedColor,?\s*\)',
         r'_previewWidget(\n                                _preview!.pickedColor,\n                                context,\n                              )',
         "Fix _previewWidget parameter order"),
    ],

    # slider.dart - buildHint/buildTrackValue parameter order
    f"{base}/form/slider.dart": [
        # buildHint(context, constraints, theme) -> buildHint(constraints, context, theme)
        (r'buildHint\(context, constraints, theme\)',
         r'buildHint(constraints, context, theme)',
         "Fix buildHint parameter order"),

        # buildTrackValue(context, constraints, theme) -> buildTrackValue(constraints, context, theme)
        (r'buildTrackValue\(context, constraints, theme\)',
         r'buildTrackValue(constraints, context, theme)',
         "Fix buildTrackValue parameter order"),
    ],

    # text_field.dart - context menu parameter order
    f"{base}/form/text_field.dart": [
        # buildEditableTextContextMenu(context, editableTextState) -> buildEditableTextContextMenu(editableTextState, context)
        (r'buildEditableTextContextMenu\(context, editableTextState\)',
         r'buildEditableTextContextMenu(editableTextState, context)',
         "Fix buildEditableTextContextMenu parameter order"),

        # _getMaterialButtonLabel(context, buttonItem) -> _getMaterialButtonLabel(buttonItem, context)
        (r'_getMaterialButtonLabel\(context, buttonItem\)',
         r'_getMaterialButtonLabel(buttonItem, context)',
         "Fix _getMaterialButtonLabel parameter order"),

        # replaceWordAtCaret(text, start, replacement) -> replaceWordAtCaret(start, text, replacement)
        (r'replaceWordAtCaret\(text, start, replacement\)',
         r'replaceWordAtCaret(start, text, replacement)',
         "Fix replaceWordAtCaret parameter order"),
    ],

    # input_otp.dart - multiple parameter swaps
    f"{base}/form/input_otp.dart": [
        # _buildCell(theme, widget.data.groupLength) -> _buildCell(widget.data.groupLength, theme)
        (r'_buildCell\(\s*theme,\s*widget\.data\.groupLength,?\s*\)',
         r'_buildCell(\n                      widget.data.groupLength,\n                      theme,\n                    )',
         "Fix _buildCell parameter order"),

        # Remove toDouble on value that should be int
        (r'value: value\.toDouble\(\),',
         r'value: value,',
         "Remove unnecessary toDouble"),

        # _InputOTPCharacter swap: (_children[index], child) -> (child, _children[index])
        (r'_InputOTPCharacter\(\s*_children\[index\],\s*child,\s*\)',
         r'_InputOTPCharacter(\n              child,\n              _children[index],\n            )',
         "Fix _InputOTPCharacter parameter order"),

        # _buildChild swap: (this, _children[i].key) -> (_children[i].key, this)
        (r'_buildChild\(\s*this,\s*_children\[i\]\.key,?\s*\)',
         r'_buildChild(\n              _children[i].key,\n              this,\n            )',
         "Fix _buildChild parameter order 1"),

        # _buildChild swap: (this, null) -> (null, this)
        (r'_buildChild\(\s*this,\s*null,?\s*\)',
         r'_buildChild(\n              null,\n              this,\n            )',
         "Fix _buildChild parameter order 2"),
    ],

    # time_picker.dart - toDouble on int variables
    f"{base}/form/time_picker.dart": [
        # Remove toDouble assignments to int variables
        (r'(hour|minute|second) = \1\.clamp\([^)]+\)\.toDouble\(\);',
         r'\1 = \1.clamp(0, 23 if "\1" == "hour" else 59);',
         "Remove toDouble on time variables"),
    ],
}

# Run fixes
fixed_files = []
for filepath, patterns in fixes.items():
    if fix_file(filepath, patterns):
        fixed_files.append(filepath)
        print(f"✓ Fixed: {filepath}")

print(f"\n✅ Fixed {len(fixed_files)} files")
