#!/usr/bin/env bash
# Every parameter a component widget declares must be read by that component.
#
# The widget-level sibling of `check_axis_field_consumed.sh`. That guard
# looks at theme-level carriers — the types an axis lives on — and says so
# in its header; component widgets fall outside it. This one covers them.
#
# The failure is the same shape one level down. A parameter sits in the
# constructor, as a field and in `copyWith`, the public API is symmetric
# with the other platform, and nothing reads it: a caller passes a value
# and nothing happens, and nothing fails. It shipped on the text field
# three times at once — a pointer-up-outside callback, a states
# controller, a focus-traversal flag — each looking wired from every
# angle the analyzer and review look from.
#
# What counts as a read
#
#   Any mention of the field's name in the component's own directory that
#   is not value-type boilerplate. Subtracted by shape: the declaration,
#   the constructor's `this.f`, a `copyWith` parameter line and its
#   `f ?? this.f` body, a named-argument label `f:`, equality against
#   `other.f`, a bare `f,` hashCode line, and comments. What is left —
#   `widget.f`, `component.f`, a bare `f` in a stateless `build` — is a
#   read.
#
# The directory is the unit because a component's state class, private
# helpers and resolver call sit beside the widget and read its fields
# there. The cost is a blind spot worth stating: a field whose name is
# also used by some other class in the same directory reads as consumed on
# that other class's strength. Resolving which object a mention belongs to
# is an analyzer's job, not grep's; the honest move is to say so here.
#
# This proves something reads the value, not that the value reaches the
# user. A test that reads the effect back is what shows that.
#
# Ratchet: parameters unread today are listed in the baseline beside this
# script. Net-new ones fail; the list may only shrink. Some entries are
# framework-infrastructure types the other platform provides natively
# (`cross-platform/api.md`) — declared for signature parity and correctly
# unread; they stay listed rather than exempted by name, so a new one is
# still a decision someone sees.
#
# Usage: check_dead_widget_param.sh [--update]

set -uo pipefail
cd "$(dirname "$0")/../../.." || exit 1

BASELINE="scripts/guards/structure/dead_widget_param_baseline.txt"
ROOTS=(
  "packages/coui_flutter/lib/src/components"
  "packages/coui_web/lib/src/components"
)

for root in "${ROOTS[@]}"; do
  [ -d "$root" ] || { echo "FAIL: component root missing: $root"; exit 1; }
done

unread=$(
  find "${ROOTS[@]}" -name '*.dart' ! -name '*_style.dart' -print0 |
    sort -z |
    xargs -0 perl -e '
      use strict; use warnings;
      my $bases = qr/StatefulWidget|StatelessWidget|UiComponent|UiStatefulComponent|StatelessComponent|StatefulComponent/;
      my %dir_lines;   # dir -> [lines of every .dart file in it]

      sub dir_of { my $p = shift; $p =~ s{/[^/]+$}{}; return $p; }

      sub lines_of_dir {
        my $d = shift;
        return $dir_lines{$d} if $dir_lines{$d};
        my @all;
        opendir(my $dh, $d) or return [];
        for my $f (sort grep { /\.dart$/ } readdir $dh) {
          open(my $fh, "<", "$d/$f") or next;
          push @all, <$fh>;
          close $fh;
        }
        closedir $dh;
        return $dir_lines{$d} = \@all;
      }

      sub is_read {
        my ($f, $lines) = @_;
        for my $line (@$lines) {
          next unless $line =~ /\b\Q$f\E\b/;
          next if $line =~ m{^\s*(///|//|\*)};                         # comment
          next if $line =~ /^\s*(?:late\s+)?(?:final|const)\s+(?:[\w<>,?.() ]+?\s+)?\Q$f\E\s*;\s*$/;  # declaration
          next if $line =~ /\bget\s+\Q$f\E\s*(=>|\{)/;                 # getter declaration
          next if $line =~ /^\s*(required\s+)?[\w<>,?\s.()]+\s\Q$f\E,\s*$/;  # copyWith parameter
          next if $line =~ /^\s*\Q$f\E,\s*$/;                          # hashCode entry
          my $rest = $line;
          $rest =~ s/\b\Q$f\E\s*\?\?\s*this\.\Q$f\E\b//g;              # copyWith body
          $rest =~ s/\bthis\.\Q$f\E\b//g;                             # constructor
          $rest =~ s/\b\Q$f\E\s*==\s*other\.\Q$f\E\b//g;               # equality
          $rest =~ s/\bother\.\Q$f\E\b//g;
          $rest =~ s/(?<![.\w])\Q$f\E:(?!:)//g;                        # named-argument label
          return 1 if $rest =~ /\b\Q$f\E\b/;
        }
        return 0;
      }

      for my $path (@ARGV) {
        open(my $fh, "<", $path) or next;
        my @lines = <$fh>;
        close $fh;
        my $class;
        for my $line (@lines) {
          if ($line =~ /^class ([A-Z]\w*)\b.*\bextends\s+($bases)\b/) {
            $class = $1; next;
          }
          if (defined $class && $line =~ /^\}/) { undef $class; next; }
          next unless defined $class;
          next unless $line =~ /^  final [\w<>,?\s.()]+?\s([a-z]\w*);\s*$/;
          my $field = $1;
          next if is_read($field, lines_of_dir(dir_of($path)));
          print "$path:$class.$field\n";
        }
      }
    ' | sort -u
)

if [ "${1:-}" = "--update" ]; then
  {
    echo "# Component widget parameters that nothing in their component reads."
    echo "# Net-new entries fail CI; this list may only shrink."
    printf '%s\n' "$unread"
  } | sed '/^$/d' > "$BASELINE"
  echo "baseline updated ($(printf '%s' "$unread" | grep -c . || true) entries)"
  exit 0
fi

known=$(grep -vE '^#|^$' "$BASELINE" 2>/dev/null | sort -u)
netnew=$(comm -23 <(printf '%s\n' "$unread" | sed '/^$/d') <(printf '%s\n' "$known" | sed '/^$/d'))

if [ -n "$netnew" ]; then
  echo "FAIL: component widget parameter that nothing reads:"
  printf '%s\n' "$netnew" | sed 's/^/    /'
  echo "    — a declared parameter that is never read accepts a value and"
  echo "      does nothing with it. Wire it where it takes effect and add a"
  echo "      test that reads the effect back, or remove it."
  exit 1
fi

echo "PASS: every component widget parameter is read ($(printf '%s' "$known" | grep -c . || echo 0) known unread)"
exit 0
