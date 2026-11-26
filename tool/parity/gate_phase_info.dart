#!/usr/bin/env dart

/// Prints `GatePhase.current`'s requirements as `KEY=value` lines
/// (#3618/#3619) — `ci.yaml`'s `parity-gate` job captures this into
/// `$GITHUB_OUTPUT` so each signal's step-level `continue-on-error` is a
/// live expression reading `GatePhase.current` (`src/gate/gate_phase.dart`,
/// the single source of truth for the rollout phase), not a YAML comment a
/// promotion could forget to update in lockstep with the Dart constant.
///
/// Usage:
///   `dart run tool/parity/gate_phase_info.dart >> "$GITHUB_OUTPUT"`
library;

import 'dart:io';

import 'src/gate/gate_phase.dart';

void main() {
  const phase = GatePhase.current;
  stdout
    ..writeln('phase=${phase.wireName}')
    ..writeln('requires_property=${phase.requiresProperty}')
    ..writeln('requires_pixel=${phase.requiresPixel}');
}
