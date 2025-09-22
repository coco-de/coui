import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:coui_flutter/coui_flutter.dart';

const kDebugStickerVisible = true;
const kDebugContainerVisible = true;

void debugPostSticker(
    Color color, BuildContext context, Rect rect, String text) {
  if (!kDebugStickerVisible) {
    return;
  }
  assert(kDebugMode, 'debugPostSticker should only be called in debug mode');
  final entry = OverlayEntry(
    builder: (context) {
      return Positioned(
        height: rect.height,
        left: rect.left,
        top: rect.top,
        width: rect.width,
        child: IgnorePointer(
          child: Opacity(
            opacity: 0.2,
            child: Container(
              decoration: BoxDecoration(color: color),
              padding: const EdgeInsets.all(8),
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
      );
    },
  );
  Overlay.of(context).insert(entry);
  Timer(const Duration(seconds: 2), entry.remove);
}

extension DebugContainer on Widget {
  Widget debugContainer([Color color = Colors.red]) {
    return !kDebugContainerVisible
        ? this
        : ColoredBox(color: color, child: this);
  }
}
