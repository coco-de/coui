// This file provides small JS DOM interop utilities for web-only builds.
// We intentionally keep scope limited and typed to preserve SSR safety via
// conditional export in `web_dom_utils.dart`.
// ignore_for_file: deprecated_member_use  // dart:js_util is allowed here; migration to js_interop tracked separately

import 'dart:js_util' as js_util;

bool getChecked(Object target) {
  // Prefer explicit type argument to satisfy analyzer inference warnings.
  final value = js_util.getProperty<bool?>(target, 'checked');

  return value ?? false;
}
