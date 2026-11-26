#!/usr/bin/env python3
"""Inline spacing in coui_web must reach the `--coui-space-*` variables.

Scanner behind `check_spacing_var_routing.sh` (the CI entry point — this
file is deliberately not named `check_*`). See that script's header for the
rule and why it exists; this docstring covers how the scan works.

A regex cannot see this rule. The shapes that break it are rarely the value
on the line of the key:

  * a local holds the literal (`final gapRem = '${x / kRemDivisor}rem';`)
  * a local helper builds it (`String rem(double px) => …` then `rem(x)`)
  * the key itself is computed — a ternary of two properties, a local bound
    to one, a function returning one, or a parameter a call site feeds one
    (`{cssProperty: …}` inside a helper called with `cssProperty: 'gap'`)
  * the value spans adjacent string literals over several lines.

So the scanner lexes Dart (strings with `${}` interpolation, comments,
brackets), finds every map entry and index assignment, keeps those whose
key can be a spacing property, and walks the value — resolving locals to
their initializers and same-file helpers to their bodies — for anything that
builds a literal length.

Exit codes: 0 clean · 1 violation (or a structural check failed) · 2 the
scanner could not read the tree (fail-closed).

Values routed through `pinnedLengthCss` (the declared opt-out for geometry
that rides a spacing property) are counted; with `--pinned-baseline=N` the
count is a ratchet.

Usage:
  spacing_var_routing.py [ROOT] [--pinned-baseline=N]
                                guard (default ROOT: packages/coui_web/lib)
  spacing_var_routing.py --inventory [ROOT]   every spacing declaration
  spacing_var_routing.py --self-test          prove each shape is caught
"""

import os
import re
import shutil
import sys
import tempfile

# ── what counts as spacing ────────────────────────────────────────────────

SIDES = (r'(?:top|right|bottom|left|inline|block'
         r'|inline-start|inline-end|block-start|block-end)')
SPACING_PROP = re.compile(
    rf'^(?:padding|margin)(?:-{SIDES})?$|^(?:gap|row-gap|column-gap)$')
LONGHAND_SUFFIX = re.compile(rf'^-{SIDES}$')
SPACING_BASE = re.compile(r'^(?:padding|margin)$')

# Calls whose result is already a routed length. `spaceCss` is the spacing
# route. `pinnedLengthCss` is the declared opt-out for a value that rides a
# spacing property without being spacing — allowed, but counted against a
# ratchet (see `run`). The other three are the routed converters of other
# families, which a spacing declaration may legitimately carry: an inset that
# clears a corner is a radius, a band drawn with `padding` is a stroke. Each
# documents its own policy in core_to_css.dart.
PINNED_CALL = 'pinnedLengthCss'
ALLOWED_CALLS = {'spaceCss', PINNED_CALL, 'radiusCss', 'strokeWidthCss',
                 'pictureStrokeCss'}
# Public members known to return a literal `rem`.
KNOWN_REM_MEMBERS = {'uniformRem'}

LENGTH_IN_LIT = re.compile(
    r'(?<![A-Za-z_\d.])-?(?:\d+\.?\d*|\.\d+)\s*(?:rem|px|em)\b')
# Flutter LineMetrics.height rounds ascent + descent to logical pixels.
# In this exact CSS projection, only the final 1px is a metric quantum,
# not spacing. Keep scanning every other length, including in the same string.
# A complete literal function is required; interpolation/adjacent strings
# cannot establish that an arbitrary number is this operation's unit argument.
LINE_METRIC_PROJECTION = re.compile(
    r'(?<![A-Za-z_\d-])round\(\s*nearest\s*,\s*1lh\s*,\s*'
    r'(?P<quantum>1px)\s*\)')


def numeric_literal(value):
    # The coarse plain-string check also sees the 1lh input. Remove the
    # recognized operation for that check only; _walk excludes just its unit.
    return re.search(r'\d', LINE_METRIC_PROJECTION.sub('', value))


def literal_lengths(value):
    quantum_spans = {m.span('quantum')
                     for m in LINE_METRIC_PROJECTION.finditer(value)}
    return (m for m in LENGTH_IN_LIT.finditer(value)
            if m.span() not in quantum_spans)


UNIT_AFTER_INTERP = re.compile(r'^\s*(?:rem|px|em)\b')
SPACE_VAR_PREFIX = re.compile(r'var\(\s*--coui-space-$')
REM_DIVISOR = re.compile(r'(?i)remdivisor')

# The scan reads ~260 declarations today. A floor well under that catches a
# scanner gone blind (a lexer change, a moved tree) — zero declarations would
# otherwise read as zero violations.
FLOOR = 150

CONVERTER_FILE = os.path.join('src', 'util', 'core_to_css.dart')

# ── Dart lexer ────────────────────────────────────────────────────────────

IDENT = re.compile(r'[A-Za-z_$][A-Za-z0-9_$]*')
IDENT_NO_DOLLAR = re.compile(r'[A-Za-z_][A-Za-z0-9_]*')
NUM = re.compile(
    r'(?:0[xX][0-9a-fA-F]+|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?'
    r'|\.\d+(?:[eE][+-]?\d+)?)')
OPS = [
    '...?', '>>>=', '...', '??=', '~/=', '<<=', '>>=', '>>>',
    '?..', '?.', '??', '=>', '==', '!=', '<=', '>=', '&&', '||', '++', '--',
    '+=', '-=', '*=', '/=', '%=', '&=', '|=', '^=', '~/', '<<', '..',
]


class Tok:
    __slots__ = ('kind', 'text', 'line', 'parts', 'pos', 'end')

    def __init__(self, kind, text, line, pos, end, parts=None):
        self.kind = kind      # id · num · str · op · open · close
        self.text = text
        self.line = line
        self.pos = pos
        self.end = end
        self.parts = parts    # str: [('lit', s) | ('interp', toks) | ('ident', s)]


class LexError(Exception):
    pass


def lex(src, i=0, line=1, interp=False):
    """Tokens of [src] from [i]; with [interp], stops after the `}` that
    closes a `${`. Returns (tokens, next index, line)."""
    toks = []
    n = len(src)
    depth = 0
    while i < n:
        c = src[i]
        if c == '\n':
            line += 1
            i += 1
            continue
        if c in ' \t\r\f':
            i += 1
            continue
        if src.startswith('//', i):
            j = src.find('\n', i)
            i = n if j == -1 else j
            continue
        if src.startswith('/*', i):
            d = 0
            j = i
            while j < n:
                if src.startswith('/*', j):
                    d += 1
                    j += 2
                    continue
                if src.startswith('*/', j):
                    d -= 1
                    j += 2
                    if d == 0:
                        break
                    continue
                if src[j] == '\n':
                    line += 1
                j += 1
            i = j
            continue
        if c in '\'"' or (c in 'rR' and i + 1 < n and src[i + 1] in '\'"'):
            tok, i, line = _lex_string(src, i, line)
            toks.append(tok)
            continue
        if c.isdigit() or (c == '.' and i + 1 < n and src[i + 1].isdigit()):
            m = NUM.match(src, i)
            toks.append(Tok('num', m.group(0), line, i, m.end()))
            i = m.end()
            continue
        if c.isalpha() or c in '_$':
            m = IDENT.match(src, i)
            toks.append(Tok('id', m.group(0), line, i, m.end()))
            i = m.end()
            continue
        if c in '([{':
            if c == '{':
                depth += 1
            toks.append(Tok('open', c, line, i, i + 1))
            i += 1
            continue
        if c in ')]}':
            if c == '}':
                if interp and depth == 0:
                    return toks, i + 1, line
                depth -= 1
            toks.append(Tok('close', c, line, i, i + 1))
            i += 1
            continue
        for op in OPS:
            if src.startswith(op, i):
                toks.append(Tok('op', op, line, i, i + len(op)))
                i += len(op)
                break
        else:
            toks.append(Tok('op', c, line, i, i + 1))
            i += 1
    if interp:
        raise LexError(f'unterminated interpolation (line {line})')
    return toks, i, line


def _lex_string(src, i, line):
    n = len(src)
    start, start_line = i, line
    raw = src[i] in 'rR'
    if raw:
        i += 1
    q = src[i]
    delim = q * 3 if src.startswith(q * 3, i) else q
    i += len(delim)
    parts, buf = [], []
    while True:
        if i >= n:
            raise LexError(f'unterminated string (line {start_line})')
        if src.startswith(delim, i):
            i += len(delim)
            break
        ch = src[i]
        if ch == '\n':
            if len(delim) == 1:
                raise LexError(f'newline in a string (line {start_line})')
            line += 1
        if not raw and ch == '\\':
            buf.append(src[i:i + 2])
            if src[i + 1:i + 2] == '\n':
                line += 1
            i += 2
            continue
        if not raw and ch == '$':
            if src.startswith('${', i):
                if buf:
                    parts.append(('lit', ''.join(buf)))
                    buf = []
                sub, i, line = lex(src, i + 2, line, interp=True)
                parts.append(('interp', sub))
                continue
            m = IDENT_NO_DOLLAR.match(src, i + 1)
            if m:
                if buf:
                    parts.append(('lit', ''.join(buf)))
                    buf = []
                parts.append(('ident', m.group(0)))
                i = m.end()
                continue
        buf.append(ch)
        i += 1
    if buf:
        parts.append(('lit', ''.join(buf)))
    return Tok('str', src[start:i], start_line, start, i, parts), i, line


def is_op(t, *texts):
    return t is not None and t.kind == 'op' and t.text in texts


def is_id(t, *texts):
    return t is not None and t.kind == 'id' and (not texts or t.text in texts)


def plain(t):
    """The text of a string token without interpolation, else None."""
    if t.kind != 'str' or not all(p[0] == 'lit' for p in t.parts):
        return None
    return ''.join(p[1] for p in t.parts)


def spacing_literal(t):
    """'full' for a spacing-property literal, 'suffix' for `'$x-<side>'`."""
    if t.kind != 'str':
        return None
    p = plain(t)
    if p is not None:
        return 'full' if SPACING_PROP.match(p) else None
    parts = t.parts
    if (len(parts) == 2 and parts[0][0] in ('ident', 'interp')
            and parts[1][0] == 'lit' and LONGHAND_SUFFIX.match(parts[1][1])):
        return 'suffix'
    return None


# ── one file: brackets, declarations, functions ───────────────────────────

NOT_TYPE = {
    'return', 'await', 'yield', 'throw', 'else', 'new', 'case', 'in', 'is',
    'as', 'if', 'for', 'while', 'switch', 'do', 'try', 'catch', 'on',
    'assert', 'break', 'continue', 'default', 'when', 'get', 'set',
    'operator', 'extends', 'implements', 'with', 'super', 'this', 'true',
    'false', 'null', 'required', 'covariant',
}
PARAM_SKIP = {'required', 'final', 'covariant', 'this', 'super', 'const', 'var'}


class Func:
    __slots__ = ('ctx', 'name', 'idx', 'params', 'body', 'arrow', 'span',
                 'top_level')

    def __init__(self, ctx, name, idx, params, body, arrow, span, top_level):
        self.ctx = ctx
        self.name = name
        self.idx = idx
        self.params = params        # [(name, is_named)]
        self.body = body            # token range
        self.arrow = arrow          # `=>` body (an expression)
        self.span = span            # block it is visible in
        self.top_level = top_level


class FileCtx:
    def __init__(self, path, src):
        self.path = path
        self.src = src
        self.toks, _, _ = lex(src)
        n = len(self.toks)
        self.pair = {}
        self.par = [-1] * n
        stack = []
        for k, t in enumerate(self.toks):
            self.par[k] = stack[-1] if stack else -1
            if t.kind == 'open':
                stack.append(k)
            elif t.kind == 'close' and stack:
                o = stack.pop()
                self.pair[o] = k
                self.pair[k] = o
                self.par[k] = stack[-1] if stack else -1
        self.vars = {}    # name -> [(idx, init_start, init_end, span, is_decl)]
        self.funcs = {}   # name -> [Func]
        self._index()

    def tok(self, k):
        return self.toks[k] if 0 <= k < len(self.toks) else None

    def block_span(self, k):
        o = self.par[k]
        while o != -1 and self.toks[o].text != '{':
            o = self.par[o]
        if o == -1:
            return (0, len(self.toks))
        return (o, self.pair.get(o, len(self.toks)))

    def expr_end(self, k, stops=(';', ',')):
        depth = 0
        for j in range(k, len(self.toks)):
            t = self.toks[j]
            if t.kind == 'open':
                depth += 1
            elif t.kind == 'close':
                if depth == 0:
                    return j
                depth -= 1
            elif depth == 0 and t.kind == 'op' and t.text in stops:
                return j
        return len(self.toks)

    def _params(self, o):
        c = self.pair.get(o)
        params = []
        if c is None:
            return params
        named, depth, cur = False, 0, []
        for j in range(o + 1, c + 1):
            t = self.toks[j]
            if j == c or (depth == 0 and is_op(t, ',')):
                seg = cur
                for q, x in enumerate(cur):
                    if is_op(x, '='):
                        seg = cur[:q]
                        break
                ids = [x.text for x in seg
                       if x.kind == 'id' and x.text not in PARAM_SKIP]
                if ids:
                    params.append((ids[-1], named))
                cur = []
                continue
            if t.kind == 'open':
                if depth == 0 and t.text in '{[':
                    named = t.text == '{'
                    continue
                depth += 1
            elif t.kind == 'close':
                if depth == 0 and t.text in '}]':
                    continue
                depth -= 1
            cur.append(t)
        return params

    def _index(self):
        toks = self.toks
        whole = (0, len(toks))
        for k, t in enumerate(toks):
            if t.kind != 'id':
                continue
            prev, nxt = self.tok(k - 1), self.tok(k + 1)
            if nxt is None or is_op(prev, '.', '?.', '..', '?..'):
                continue
            if is_op(nxt, '=', '??='):
                is_decl = prev is not None and (
                    (prev.kind == 'id' and prev.text not in NOT_TYPE)
                    or is_op(prev, '?', '>'))
                is_assign = (prev is None or is_op(prev, ';', ':')
                             or (prev.kind in ('open', 'close')
                                 and prev.text in '{})')
                             or is_id(prev, 'else'))
                if is_decl or is_assign:
                    s = k + 2
                    self.vars.setdefault(t.text, []).append(
                        (k, s, self.expr_end(s), self.block_span(k), is_decl))
                continue
            declish = prev is not None and (
                (prev.kind == 'id'
                 and (prev.text not in NOT_TYPE or prev.text == 'get'))
                or is_op(prev, '?', '>'))
            if not declish:
                continue
            j = k + 1
            params = []
            if nxt.kind == 'open' and nxt.text == '(':
                params = self._params(k + 1)
                j = self.pair.get(k + 1, k + 1) + 1
            elif prev.text != 'get':
                continue
            while is_id(self.tok(j), 'async', 'sync'):
                j += 1
            span = self.block_span(k)
            top = span == whole
            after = self.tok(j)
            if is_op(after, '=>'):
                s = j + 1
                self.funcs.setdefault(t.text, []).append(
                    Func(self, t.text, k, params, (s, self.expr_end(s)), True,
                         span, top))
            elif after is not None and after.kind == 'open' and after.text == '{':
                e = self.pair.get(j, len(toks))
                self.funcs.setdefault(t.text, []).append(
                    Func(self, t.text, k, params, (j + 1, e), False, span,
                         top))

    def resolve_var(self, name, u):
        """Initializers / assignments [name] can hold at token [u]."""
        entries = self.vars.get(name, [])
        vis = [e for e in entries if e[3][0] <= u <= e[3][1]]
        decls = [e for e in vis if e[4]]
        if decls:
            decls.sort(key=lambda e: (e[3][1] - e[3][0],
                                      -e[0] if e[0] < u else 10 ** 9))
            d = decls[0]
            out = [d]
            out += [e for e in entries
                    if not e[4] and d[3][0] <= e[0] <= d[3][1] and e[0] > d[0]]
            return out
        return [e for e in vis if not e[4]]

    def resolve_func(self, name, u):
        entries = self.funcs.get(name, [])
        return [f for f in entries if f.span[0] <= u <= f.span[1]]

    def enclosing_func(self, u):
        best = None
        for fs in self.funcs.values():
            for f in fs:
                if f.body[0] <= u < f.body[1] and (
                        best is None or f.body[0] > best.body[0]):
                    best = f
        return best

    def returns(self, f):
        """Token ranges of what [f] returns."""
        if f.arrow:
            return [f.body]
        out = []
        for j in range(f.body[0], f.body[1]):
            if is_id(self.toks[j], 'return'):
                s = j + 1
                out.append((s, self.expr_end(s, stops=(';',))))
        return out


# ── the whole tree ────────────────────────────────────────────────────────


class Repo:
    def __init__(self, root):
        self.root = root
        self.files = []
        for dirpath, _dirs, names in os.walk(root):
            for name in sorted(names):
                if name.endswith('.dart'):
                    path = os.path.join(dirpath, name)
                    with open(path, encoding='utf-8') as fh:
                        src = fh.read()
                    try:
                        self.files.append(FileCtx(path, src))
                    except LexError as err:
                        raise LexError(f'{path}: {err}') from None
        self.top_funcs = {}
        for ctx in self.files:
            for name, fs in ctx.funcs.items():
                self.top_funcs.setdefault(name, []).extend(
                    f for f in fs if f.top_level)
        self.spacing_params = set()
        self._index_call_sites()

    def _funcs_named(self, name):
        out = []
        for ctx in self.files:
            out += ctx.funcs.get(name, [])
        return out

    def _index_call_sites(self):
        """(callee, parameter) pairs some call site feeds a spacing
        property, so the callee's `{parameter: value}` entries are spacing
        declarations too."""
        for ctx in self.files:
            toks = ctx.toks
            for k, t in enumerate(toks):
                if spacing_literal(t) != 'full':
                    continue
                o = ctx.par[k]
                while o != -1 and toks[o].text != '(':
                    if toks[o].text in '{[':
                        o = -1
                        break
                    o = ctx.par[o]
                if o == -1 or not is_id(ctx.tok(o - 1)):
                    continue
                callee = toks[o - 1].text
                if callee in NOT_TYPE:
                    continue
                depth, start, index = 0, o + 1, 0
                for j in range(o + 1, k):
                    x = toks[j]
                    if x.kind == 'open':
                        depth += 1
                    elif x.kind == 'close':
                        depth -= 1
                    elif depth == 0 and is_op(x, ','):
                        start, index = j + 1, index + 1
                if depth != 0:
                    continue
                if is_id(ctx.tok(start)) and is_op(ctx.tok(start + 1), ':'):
                    self.spacing_params.add((callee, toks[start].text))
                    continue
                for f in self._funcs_named(callee):
                    positional = [p for p in f.params if not p[1]]
                    if index < len(positional):
                        self.spacing_params.add((callee, positional[index][0]))

    # ── is this key a spacing property? ──────────────────────────────────

    def key_is_spacing(self, ctx, ks, ke):
        toks = ctx.toks
        while ks < ke and is_op(toks[ks], '?'):
            ks += 1
        key = toks[ks:ke]
        if not key:
            return False
        for t in key:
            kind = spacing_literal(t)
            if kind == 'full':
                return True
            if kind == 'suffix':
                head = t.parts[0]
                if head[0] == 'ident':
                    return self._name_is_spacing(ctx, head[1], ks)
                return True
        if len(key) == 1 and key[0].kind == 'id':
            return self._name_is_spacing(ctx, key[0].text, ks)
        if (key[0].kind == 'id' and len(key) > 1 and key[1].kind == 'open'
                and key[1].text == '('):
            for f in ctx.resolve_func(key[0].text, ks) or \
                    self.top_funcs.get(key[0].text, []):
                if any(spacing_literal(t) == 'full'
                       for t in f.ctx.toks[f.body[0]:f.body[1]]):
                    return True
        return False

    def _name_is_spacing(self, ctx, name, u):
        decls = ctx.resolve_var(name, u)
        if decls:
            for (_k, s, e, _span, _d) in decls:
                for t in ctx.toks[s:e]:
                    p = plain(t) if t.kind == 'str' else None
                    if spacing_literal(t) == 'full' or (
                            p is not None and SPACING_BASE.match(p)):
                        return True
            return False
        f = ctx.enclosing_func(u)
        while f is not None:
            if any(p[0] == name for p in f.params):
                return (f.name, name) in self.spacing_params
            f = ctx.enclosing_func(f.idx)
        return False

    # ── does this value build a literal length? ─────────────────────────

    def check_value(self, ctx, s, e):
        """(reasons the value builds a literal, whether it is pinned)."""
        toks = ctx.toks[s:e]
        reasons = []
        if len(toks) == 1 and toks[0].kind == 'str':
            p = plain(toks[0])
            if p is not None and numeric_literal(p):
                reasons.append(f'hard-coded literal {p!r}')
        self._pinned = False
        reasons += self._walk(ctx, toks, s, set(), 0)
        return reasons, self._pinned

    def _walk(self, ctx, toks, pos, visited, depth):
        reasons = []
        if depth > 16:
            return reasons
        prev_string_kind, prev_string_lit = None, ''
        for j, t in enumerate(toks):
            prev = toks[j - 1] if j > 0 else None
            nxt = toks[j + 1] if j + 1 < len(toks) else None
            if t.kind == 'str':
                # Dart concatenates adjacent strings, including a numeric
                # literal in one and its unit in the next. Preserve that
                # boundary without treating a split metric as sanctioned.
                prev_kind, prev_lit = prev_string_kind, prev_string_lit
                for kind, val in t.parts:
                    if kind == 'lit':
                        for m in literal_lengths(val):
                            reasons.append(
                                f'literal length {m.group(0).strip()!r}')
                        unit = UNIT_AFTER_INTERP.match(val)
                        if prev_kind in ('interp', 'ident') and unit:
                            reasons.append('a number interpolated into '
                                           f'{unit.group(0).strip()!r}')
                        if prev_kind == 'lit':
                            joined = prev_lit + val
                            for m in LENGTH_IN_LIT.finditer(joined):
                                if m.start() < len(prev_lit) < m.end():
                                    reasons.append('adjacent literal length '
                                                   f'{m.group(0).strip()!r}')
                            prev_lit = joined
                        else:
                            prev_lit = val
                    else:
                        if prev_kind == 'lit' and SPACE_VAR_PREFIX.search(
                                prev_lit):
                            reasons.append(
                                'hand-built `var(--coui-space-${…})` — an '
                                'off-scale value names a variable that does '
                                'not exist')
                        if kind == 'interp':
                            reasons += self._walk(ctx, val, pos, visited,
                                                  depth + 1)
                        else:
                            reasons += self._ident(ctx, val, pos, visited,
                                                   depth)
                    prev_kind = kind
                prev_string_kind, prev_string_lit = prev_kind, prev_lit
                continue
            prev_string_kind, prev_string_lit = None, ''
            if t.kind == 'num' and t.text in ('16', '16.0') and is_op(prev, '/'):
                reasons.append('/ 16')
                continue
            if t.kind != 'id':
                continue
            if t.text == '_rem':
                reasons.append('_rem(…)')
                continue
            if REM_DIVISOR.search(t.text):
                reasons.append(f'/ {t.text}')
                continue
            if is_op(prev, '.', '?.', '..', '?..'):
                if t.text in KNOWN_REM_MEMBERS:
                    reasons.append(f'.{t.text}')
                continue
            if nxt is not None and nxt.kind == 'open' and nxt.text == '(':
                close = j + 1
                depth_ = 0
                for q in range(j + 1, len(toks)):
                    if toks[q].kind == 'open':
                        depth_ += 1
                    elif toks[q].kind == 'close':
                        depth_ -= 1
                        if depth_ == 0:
                            close = q
                            break
                after = toks[close + 1] if close + 1 < len(toks) else None
                if t.text == PINNED_CALL:
                    self._pinned = True
                if t.text in ALLOWED_CALLS or is_op(after, '.', '?.', '!'):
                    continue
                reasons += self._call(ctx, t.text, pos, visited, depth)
                continue
            if is_op(nxt, '.', '?.', '!'):
                continue   # a receiver — the member decides the value
            reasons += self._ident(ctx, t.text, pos, visited, depth)
        return reasons

    def _ident(self, ctx, name, pos, visited, depth):
        key = ('v', ctx.path, name, pos)
        if key in visited:
            return []
        visited.add(key)
        reasons = []
        for (_k, s, e, _span, _d) in ctx.resolve_var(name, pos):
            sub = self._walk(ctx, ctx.toks[s:e], s, visited, depth + 1)
            if e - s == 1 and ctx.toks[s].kind == 'str':
                p = plain(ctx.toks[s])
                if p is not None and numeric_literal(p):
                    sub.append(f'hard-coded literal {p!r}')
            reasons += [f'{name} ← {r}' for r in sub]
        return reasons

    def _call(self, ctx, name, pos, visited, depth):
        key = ('f', ctx.path, name)
        if key in visited:
            return []
        visited.add(key)
        reasons = []
        for f in ctx.resolve_func(name, pos) or self.top_funcs.get(name, []):
            for (s, e) in f.ctx.returns(f):
                sub = self._walk(f.ctx, f.ctx.toks[s:e], s, visited, depth + 1)
                reasons += [f'{name}() ← {r}' for r in sub]
        return reasons

    # ── where declarations are ───────────────────────────────────────────

    def emissions(self, ctx):
        """(key start, key end, value start, value end, kind) for every map
        entry and index assignment in [ctx]."""
        toks = ctx.toks
        for o, t in enumerate(toks):
            if t.kind != 'open':
                continue
            c = ctx.pair.get(o)
            if c is None:
                continue
            if t.text == '{':
                entries, depth, start, block = [], 0, o + 1, False
                for j in range(o + 1, c + 1):
                    x = toks[j]
                    if j == c:
                        entries.append((start, j))
                    elif x.kind == 'open':
                        depth += 1
                    elif x.kind == 'close':
                        depth -= 1
                    elif depth == 0 and is_op(x, ';'):
                        block = True
                        break
                    elif depth == 0 and is_op(x, ','):
                        entries.append((start, j))
                        start = j + 1
                if not block:
                    for (es, ee) in entries:
                        yield from self._map_entry(ctx, es, ee)
            elif t.text == '[':
                prev = ctx.tok(o - 1)
                if not (is_id(prev) or is_op(prev, '..', '?..')
                        or (prev is not None and prev.kind == 'close')):
                    continue
                if not is_op(ctx.tok(c + 1), '=', '??='):
                    continue
                s = c + 2
                yield (o + 1, c, s,
                       ctx.expr_end(s, stops=(';', ',', '..', '?..')),
                       'index-assign')

    def _map_entry(self, ctx, es, ee):
        toks = ctx.toks
        segments, cur, depth = [], es, 0
        for q in range(es, ee):
            x = toks[q]
            if x.kind == 'open':
                depth += 1
            elif x.kind == 'close':
                depth -= 1
            elif depth == 0 and is_id(x, 'else'):
                segments.append((cur, q))
                cur = q + 1
        segments.append((cur, ee))
        for (ss, se) in segments:
            j = ss
            while j < se and is_id(toks[j], 'if', 'for'):
                j = ctx.pair.get(j + 1, j + 1) + 1
            if j >= se or is_op(toks[j], '...', '...?'):
                continue
            depth, pending, sep = 0, 0, None
            for q in range(j, se):
                x = toks[q]
                if x.kind == 'open':
                    depth += 1
                elif x.kind == 'close':
                    depth -= 1
                elif depth == 0 and x.kind == 'op':
                    if x.text == '?' and q != j:
                        pending += 1
                    elif x.text == ':':
                        if pending:
                            pending -= 1
                        else:
                            sep = q
                            break
            if sep is not None:
                yield (j, sep, sep + 1, se, 'map-entry')

    def scan(self):
        out = []
        for ctx in self.files:
            for (ks, ke, vs, ve, kind) in self.emissions(ctx):
                if self.key_is_spacing(ctx, ks, ke):
                    out.append((ctx, ks, ke, vs, ve, kind,
                                self.check_value(ctx, vs, ve)))
        return out

    # ── the central converter must itself route ──────────────────────────

    def converter_faults(self):
        """`CoreEdgeInsets.toValue()` and `emitSpacing` are trusted above
        (they return a shorthand, not a keyed declaration), so the guard
        checks the source they come from instead."""
        path = os.path.join(self.root, CONVERTER_FILE)
        ctx = next((c for c in self.files if c.path == path), None)
        if ctx is None:
            return [f'{CONVERTER_FILE} not found under {self.root}']
        faults = []
        if not ctx.funcs.get('spaceCss'):
            faults.append('`spaceCss` is not defined in core_to_css.dart')
        toks = ctx.toks
        body = None
        for k, t in enumerate(toks):
            if (is_id(t, 'extension') and is_id(ctx.tok(k + 1),
                                                 'CoreEdgeInsetsToCss')):
                o = next((j for j in range(k, len(toks))
                          if toks[j].kind == 'open' and toks[j].text == '{'),
                         None)
                if o is not None:
                    body = toks[o:ctx.pair.get(o, len(toks))]
                break
        if body is None:
            faults.append('extension CoreEdgeInsetsToCss not found')
            return faults
        flat = []
        for t in body:
            flat.append(t)
            if t.kind == 'str':
                for kind, val in t.parts:
                    if kind == 'interp':
                        flat += val
        if not any(is_id(t, 'spaceCss') for t in flat):
            faults.append('CoreEdgeInsetsToCss no longer calls spaceCss')
        for t in flat:
            if is_id(t, '_rem') or (t.kind == 'id' and REM_DIVISOR.search(
                    t.text)):
                faults.append(f'CoreEdgeInsetsToCss builds a literal rem '
                              f'(`{t.text}`, line {t.line})')
        return faults


def _text(ctx, s, e):
    return ' '.join(t.text for t in ctx.toks[s:e])


def run(root, inventory=False, pinned_baseline=None, out=sys.stdout):
    """Returns (exit code, declarations, violations, pinned)."""
    try:
        repo = Repo(root)
    except LexError as err:
        print(f'❌ 스캐너가 소스를 읽지 못했다 — {err}', file=out)
        return 2, 0, 0, 0
    results = repo.scan()
    bad = [r for r in results if r[6][0]]
    pinned = [r for r in results if r[6][1]]
    if inventory:
        for (ctx, ks, ke, vs, ve, kind, (reasons, is_pinned)) in results:
            rel = os.path.relpath(ctx.path, root)
            mark = 'BAD' if reasons else ('pin' if is_pinned else 'ok ')
            print(f'{mark} {rel}:{ctx.toks[ks].line} '
                  f'{_text(ctx, ks, ke)}: {_text(ctx, vs, ve)}', file=out)
    code = 0
    for (ctx, ks, ke, vs, ve, kind, (reasons, _)) in bad:
        rel = os.path.relpath(ctx.path, root)
        print(f'❌ {rel}:{ctx.toks[ks].line}  {_text(ctx, ks, ke)}: '
              f'{_text(ctx, vs, ve)}', file=out)
        for r in sorted(set(reasons)):
            print(f'     - {r}', file=out)
        code = 1
    for fault in repo.converter_faults():
        print(f'❌ {fault}', file=out)
        code = 1
    if len(results) < FLOOR:
        print(f'❌ 간격 선언을 {len(results)}개만 찾았다 (하한 {FLOOR}) — '
              '스캐너가 눈이 멀었을 가능성. 위반 0 이 아니라 판정 불가다.',
              file=out)
        code = 1
    if pinned_baseline is not None:
        print(f'[spacing] {PINNED_CALL} 로 고정한 선언: {len(pinned)} '
              f'(baseline {pinned_baseline})', file=out)
        if len(pinned) > pinned_baseline:
            print(f'❌ {PINNED_CALL} 선언이 baseline 보다 늘었다.', file=out)
            for (ctx, ks, ke, vs, ve, kind, _) in pinned:
                rel = os.path.relpath(ctx.path, root)
                print(f'     {rel}:{ctx.toks[ks].line}  '
                      f'{_text(ctx, ks, ke)}', file=out)
            print('   왜: 고정한 값은 변수를 다시 가리켜도 움직이지 않는다 — '
                  '간격이 아닌 값에만 정당하다.', file=out)
            print('   무엇을: 간격이면 spaceCss 로. 간격이 아닌 기하라면 '
                  'baseline 을 올리고 PR 본문 ratchet-raised 에 사유를 적는다.',
                  file=out)
            code = 1
        elif len(pinned) < pinned_baseline:
            print(f'    ✅ baseline 아래 — baseline 을 {len(pinned)} 으로 '
                  '내린다.', file=out)
    return code, len(results), len(bad), len(pinned)


# ── self-test ─────────────────────────────────────────────────────────────

_CONVERTER = r"""
String _rem(double px) => '${px / kRemDivisor}rem';
String spaceCss(double px) => CoreSpace.steps.contains(px)
    ? 'var(--coui-space-${px.toInt()})'
    : _rem(px);
extension CoreEdgeInsetsToCss on CoreEdgeInsets {
  String toValue() => '${spaceCss(top)} ${spaceCss(right)} '
      '${spaceCss(bottom)} ${spaceCss(left)}';
}
"""

# One violation per case; the comment names the shape.
_VIOLATIONS = r"""
const _kRemDivisor = 16.0;
String _side() => 'padding-bottom';
Map<String, String> emitX(double v, {required String cssProperty}) =>
    {cssProperty: '${v / kRemDivisor}rem'};               // param-keyed
Styles build(double x, CoreBorderRadius r, bool c, bool a) {
  final g = '${x / kRemDivisor}rem';
  String rem(double px) => '${px / kRemDivisor}rem';
  final prop = c ? 'margin-right' : 'margin-bottom';
  final pre = x / kRemDivisor;
  final raw = <String, String>{
    'gap': '${x / kRemDivisor}rem',                      // direct
    'row-gap': g,                                        // via a local
    'padding-left': rem(x),                              // via a helper
    'margin':
        '${x / kRemDivisor}rem '
        '${x / kRemDivisor}rem',                         // adjacent, 2 lines
    c ? 'margin-left' : 'margin-top': '1rem',            // ternary key
    prop: '${x / 16}rem',                                // key in a local
    'margin-inline-start': '0',                          // bare zero
    'column-gap': 'var(--coui-space-${x.toInt()})',      // hand-built var
    'padding-top': '${pre}rem',                          // pre-divided
    'padding-right': '${x / _kRemDivisor}rem',           // private divisor
    if (a) 'padding-block': '${x / 16}rem' else 'width': '1rem', // if/else
    'padding-inline': r.uniformRem,                      // known rem member
  }..['margin-block-end'] = _rem(x);                     // cascade index
  raw['margin-inline'] = '4px';                          // index assignment
  raw[_side()] = '2px';                                  // key from a function
  return Styles(raw: {...raw, ...emitX(x, cssProperty: 'gap')});
}
"""
_VIOLATION_COUNT = 16

_CLEAN = r"""
ResolvedX resolveX() => ResolvedX(width: '${8 / kRemDivisor}rem');
Styles build(double x, int n, CoreEdgeInsets i, double w, String pct) {
  final resolved = resolveX();
  final half = 'calc(${spaceCss(x)} / 2)';
  return Styles(raw: {
    'gap': spaceCss(x),
    'padding': i.toValue(),
    'margin': '${spaceCss(x)} ${spaceCss(x)}',
    'margin-left': 'calc($n * ${spaceCss(x)})',
    'margin-top': half,
    'margin-right': 'auto',
    'padding-top': '$pct%',
    'padding-bottom': pictureStrokeCss(w),
    'padding-inline': 'min(${radiusCss(w)}, ${spaceCss(x)})',
    'margin-bottom': spaceCss(resolved.indent),
    'width': '${x / kRemDivisor}rem',
    'border-width': '${w / 16}rem',
  });
}
"""


_PINNED = r"""
Styles build(double size, double offset) {
  final cap = pinnedLengthCss(size);
  return Styles(raw: {
    'margin-top': pinnedLengthCss(-size / 2),            // pinned directly
    'padding-left': 'min(${radiusCss(size)}, $cap)',      // pinned via a local
    'gap': spaceCss(offset),                             // not pinned
  });
}
"""


def self_test():
    ok = True
    tmp = tempfile.mkdtemp(prefix='spacing-var-routing-')

    def tree(files):
        root = tempfile.mkdtemp(dir=tmp)
        for rel, src in files.items():
            path = os.path.join(root, rel)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, 'w', encoding='utf-8') as fh:
                fh.write(src)
        return root

    def check(label, files, want_code, want_bad, floor=0, baseline=None,
              want_pinned=None):
        nonlocal ok
        global FLOOR
        saved, FLOOR = FLOOR, floor
        sink = open(os.devnull, 'w', encoding='utf-8')
        try:
            code, decls, bad, pinned = run(tree(files), out=sink,
                                           pinned_baseline=baseline)
        finally:
            FLOOR = saved
            sink.close()
        good = (code == want_code
                and (want_bad is None or bad == want_bad)
                and (want_pinned is None or pinned == want_pinned))
        ok = ok and good
        print(f'  {"✅" if good else "❌"} {label}: exit {code}, '
              f'declarations {decls}, violations {bad}, pinned {pinned}'
              + ('' if good else f' (expected exit {want_code}, '
                                 f'violations {want_bad}, '
                                 f'pinned {want_pinned})'))

    conv = {CONVERTER_FILE: _CONVERTER}
    try:
        check('every violation shape is caught',
              {**conv, 'src/a_style.dart': _VIOLATIONS}, 1, _VIOLATION_COUNT)
        check('sanctioned shapes pass',
              {**conv, 'src/b_style.dart': _CLEAN}, 0, 0, want_pinned=0)
        metric = 'round(nearest, 1lh, 1px)'
        for label, value in [
            ('canonical logical-line metric', "'" + metric + "'"),
            ('metric inside geometry',
             "'max(${pinnedLengthCss(0)}, calc((${pinnedLengthCss(size)} - "
             + metric + ") / 2))'"),
            ('metric whitespace', "'round( nearest , 1lh , 1px )'"),
        ]:
            check(label, {**conv, 'src/metric_style.dart':
                         'Styles build(double size) => Styles(raw: '
                         "{'padding-top': " + value + '});'}, 0, 0)
        for label, value in [
            ('spacing beside metric', "'calc(" + metric + " + 8px)'"),
            ('spacing as metric input', "'round(nearest, 8px, 1px)'"),
            ('different quantum', "'round(nearest, 1lh, 2px)'"),
            ('different strategy', "'round(up, 1lh, 1px)'"),
            ('incomplete metric', "'round(nearest, 1lh, 1px'"),
            ('extra metric argument', "'round(nearest, 1lh, 1px, 8px)'"),
            ('other function', "'preround(nearest, 1lh, 1px)'"),
            ('interpolated input', "'round(nearest, ${8}px, 1px)'"),
            ('interpolated quantum', "'round(nearest, 1lh, ${1}px)'"),
            ('interpolated spacing beside metric',
             "'calc(" + metric + " + ${8}px)'"),
            ('adjacent spacing beside metric', "'" + metric + "' ' + 8px'"),
            ('adjacent numeric and unit spacing',
             "'" + metric + "' ' + 8' 'p' 'x'"),
            ('interpolation beside adjacent unit',
             "'calc(" + metric + " + ${8}' 'px)'"),
            ('nested interpolation spacing',
             "'calc(" + metric + " + ${'8px'})'"),
            ('adjacent incomplete metric', "'round(nearest, 1lh, ' '1px)'"),
            ('adjacent split quantum', "'round(nearest, 1lh, 1' 'px)'"),
        ]:
            check(label, {**conv, 'src/metric_style.dart':
                         'Styles build() => Styles(raw: '
                         "{'padding-top': " + value + '});'}, 1, 1)
        check('a converter that stops routing fails',
              {CONVERTER_FILE: _CONVERTER.replace(
                  "'${spaceCss(top)} ${spaceCss(right)} '",
                  "'${_rem(top)} ${spaceCss(right)} '"),
               'src/b_style.dart': _CLEAN}, 1, 0)
        check('a blind scanner fails instead of passing',
              {**conv, 'src/b_style.dart': _CLEAN}, 1, 0, floor=10_000)
        check('an unreadable file fails closed',
              {**conv, 'src/c_style.dart': "final s = 'unterminated;\n"},
              2, None)
        check('pinned values are counted, not flagged (at baseline)',
              {**conv, 'src/d_style.dart': _PINNED}, 0, 0, baseline=2,
              want_pinned=2)
        check('one pinned value over the baseline fails',
              {**conv, 'src/d_style.dart': _PINNED}, 1, 0, baseline=1,
              want_pinned=2)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    return ok


def main(argv):
    args, flags, baseline = [], set(), None
    for a in argv[1:]:
        if a.startswith('--pinned-baseline='):
            value = a.split('=', 1)[1]
            if not value.isdigit():
                print(f'❌ --pinned-baseline 는 정수여야 한다: {value!r}',
                      file=sys.stderr)
                return 2
            baseline = int(value)
        elif a.startswith('--'):
            flags.add(a)
        else:
            args.append(a)
    if flags - {'--inventory', '--self-test'} or len(args) > 1:
        print(__doc__, file=sys.stderr)
        return 2
    if '--self-test' in flags:
        print('spacing_var_routing self-test')
        if self_test():
            print('✅ 모든 형태를 잡고, 허용된 형태는 통과시키고, 고정은 센다.')
            return 0
        print('❌ self-test 실패 — 위 단계 참고.')
        return 1
    root = args[0] if args else 'packages/coui_web/lib'
    code, decls, bad, pinned = run(root, inventory='--inventory' in flags,
                                   pinned_baseline=baseline)
    if code == 0:
        print(f'✅ 인라인 간격 선언 {decls}개가 전부 spaceCss / '
              f'CoreEdgeInsets.toValue() 를 거친다 ({pinned}개는 '
              f'{PINNED_CALL} 로 고정).')
    elif code == 1 and bad:
        print(f'\n간격 선언 {decls}개 중 {bad}개 위반. 값은 spaceCss(px) '
              '(또는 CoreEdgeInsets.toValue()) 에서 와야 한다 — 단계는 '
              '`var(--coui-space-N)`, 그 밖의 값은 리터럴이 된다.')
    return code


if __name__ == '__main__':
    sys.exit(main(sys.argv))
