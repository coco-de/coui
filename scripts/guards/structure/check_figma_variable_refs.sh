#!/usr/bin/env bash
#
# G12 (#3996) — `components.json` 의 모든 변수 ref 가 `tokens.figma.json` 에
# 실재하는지. **net-new 0** (ratchet 아님).
#
# 왜 net-new 0 인가: dangling ref 는 "조금 부정확" 이 아니라 **컴포넌트가 반쯤
# 그려진 채 남는 것**이다. 빌더가 `lk.size('12')` 로 없는 변수를 찾으면 throw 하고,
# 롤백되지 않는다 — 그 엔트리가 실패로 보고되고, 그리다 만 컴포넌트가 완성처럼
# 보이는 채 캔버스에 남는다. 로그를 열지 않으면 보이지 않는다. 실제로 그 상태로
# 101 개 중 33 개가 온전히 생성되지 않고 있었다:
#
#     ✗ Form / Checkbox: Error: variable not found: Primitives/size/12
#
# 왜 기존 가드가 못 잡았나: 두 exporter 가 **서로 다른 손 관리 목록**을 갖는다.
#   export_figma_tokens.dart  `_numericTokens()` — 어떤 변수를 *만드는가*
#   figma_reader/token_scale  `buildCoreNamespaces()` — 어떤 ref 를 *쓰는가*
# G1 은 JSON 이 소스와 같은지만 보고, G3/G4 는 리더 관점 센서스, G10 은 Dart 필드의
# 도달 여부다. 어느 것도 "이 ref 가 가리키는 변수가 존재하는가" 를 묻지 않는다.
#
# 그리고 그 어긋남은 **의도된 설계에서 나왔다** — 한쪽에만 반영된 결정에서.
# 처음엔 `size` 컬렉션을 일부러 만들지 않기로 한 결정(#3736 F1)이 리더에 반영되지
# 않아 리더가 없는 `Primitives/size/N` 을 쓰고 있었다. 그 다음엔 반대 방향으로 같은
# 일이 일어났다: Size 3계층 스펙이 F1 을 폐기하고 `size/*` 를 24 스텝으로 실제로
# 내보내면서 `font-size` 를 `font/size` 로 접고 `icon-size`/`control-size` 를 다른
# 컬렉션으로 옮겼는데, 리더는 여전히 옛 이름을 쓰고 있었다 — 24 개의 dangling ref.
# 이 가드가 잡는 것은 특정 결정이 아니라 그 절반-반영이라는 모양이다.
#
# `ref: null` 은 위반이 아니다 — 바인딩할 변수가 없다는 정직한 표기이고, 빌더는
# 원시값을 그린다(F1 이 값 18 에 대해 명시한 그 동작).
#
# **0 개는 "전부 있다" 가 아니다.** 이 가드는 한때 `VarLookup` 을 클래스가 떠난
# 파일에서 찾았고, 그 뒤로 접근자를 0 개 세면서 "접근자 그룹 0개 전부 존재" 를
# 출력했다 — 같은 시기에 컬렉션 이름 규칙의 사본이 브랜드 접미사(` · CoUI`)를
# 몰라서 `Semantic/color/*` ref 52 개도 세지 못했다. 둘 다 "아무것도 보지 않았다"
# 가 "아무것도 틀리지 않았다" 로 읽힌 모양이다. 그래서 지금은
#   · 클래스를 경로가 아니라 `export class VarLookup` 선언으로 찾는다 — 정확히
#     한 파일이어야 하고, `extends` 가 있으면 검사 범위를 모르므로 실패다.
#   · 접근자 0 개 · ref 0 개 · 읽지 못한 조회 호출은 전부 실패다. 읽지 못했다는
#     것은 "컬렉션이 리터럴이 아니다" 뿐 아니라, 인덱스를 `this.byKey` 로 직접
#     읽거나 리터럴을 다른 멤버에 넘겨 조회를 위임하는 형태도 포함한다.
#   · 멤버 경계는 들여쓰기 정규식이 아니라 **어휘 분석**으로 자른다(주석 ·
#     문자열 · 템플릿을 알고 괄호 깊이를 센다). 정규식 경계는 화살표 함수
#     프로퍼티 · 중첩 제네릭 · `#private` 를 멤버로 못 알아봐, 그 조회가 앞
#     접근자 아래에 섞여 깨진 접근자를 가렸다. 어휘 분석이 동기를 잃으면
#     (닫히지 않는 괄호 · 문자열) 통과가 아니라 실패다.
#   · 플러그인의 `canonicalCollection` · `withoutOrderingPrefix` 가 바뀌면
#     실패한다 — 이 파일의 `canon()` 은 그 손 복사본이고, 한쪽만 바뀌면
#     브랜드 접미사를 잃은 플러그인이 모든 `sem()` 에서 throw 하는데 가드만
#     초록이던 자리가 생긴다. 기준 사본은 픽스처가 들고 있다.
#   · 매 실행마다 먼저 픽스처(`fixtures/figma_variable_refs.*`)로 자기 판정을
#     검산한다 — 파서가 조용히 아무것도 못 읽게 되면 그 검산이 먼저 깨진다.
#     픽스처를 못 찾거나 파서가 죽은 것도 실패다(빈 출력끼리의 비교는 통과다).
#
# 이 가드가 보지 못하는 것: `fontFamily` 의 스캔은 `font/family/` 아래에 변수가
# 있는지만 본다 — 플러그인은 역할별(`sans` 는 `/mono/i` 가 아닌 것) 술어까지
# 걸어서, 한쪽 패밀리가 없으면 그 역할이 throw 한다. 변수가 *있는가* 와 *역할에
# 맞는 것이 있는가* 는 다른 질문이다.
#
# 전제: `build/tokens.figma.json` 이 있어야 한다. 없으면 생성한다 — 이 가드가
# 재생성해도 안전한 이유는 그 파일이 결정론적 산출물이고 gitignore 대상이라
# 사람의 작업물을 덮어쓸 위험이 없기 때문이다.
#
# Usage: check_figma_variable_refs.sh [--report]

set -uo pipefail
_GUARD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$(dirname "$0")/../../.." || exit 1

readonly COMPONENTS="tools/figma-token-sync/src/data/components.json"
readonly TOKENS="build/tokens.figma.json"
readonly EXPORTER="packages/coui_core/bin/export_figma_tokens.dart"
readonly PLUGIN_SRC="tools/figma-token-sync/src"
readonly FIXTURES="$_GUARD_DIR/fixtures"
# 플러그인 규칙(`canonicalCollection`)의 기준 사본은 이 픽스처가 든다.
readonly PINNED_TS="$FIXTURES/figma_variable_refs.varlookup.ts.txt"

# check <components.json> <tokens.figma.json> <file declaring VarLookup> <mode>
#   mode: check | --report | --selftest
check() {
  env G12_COMPONENTS="$1" G12_TOKENS="$2" G12_VARLOOKUP="$3" G12_MODE="$4" \
    G12_PINNED="$PINNED_TS" \
    python3 - <<'PY'
import json, os, re, sys, collections

mode = os.environ['G12_MODE']
components_text = open(os.environ['G12_COMPONENTS'], encoding='utf-8').read()
components = json.loads(components_text)
tokens = json.load(open(os.environ['G12_TOKENS'], encoding='utf-8'))
varlookup_path = os.environ['G12_VARLOOKUP']
src = open(varlookup_path, encoding='utf-8').read()
pinned_src = open(os.environ['G12_PINNED'], encoding='utf-8').read()

# Collection names are CANONICALIZED before comparing, exactly the way the
# plugin does it (`canonicalCollection` in the file that declares VarLookup).
#
# The file may order its collections with a numeric prefix (`0. Primitives`),
# spells Semantic/Color with a space after the slash, and gives Semantic/Color
# one collection per brand (`Semantic/ Color · CoUI`) — while every accessor
# and every `ref` speaks the logical name (`Semantic/color/primary`).
# Compared raw, accessor groups that certainly exist come back missing; worse,
# the ref scan below builds its alternation from these names, so a name this
# mirror does not fold is a whole collection whose refs are never captured —
# and "not captured" reads exactly like "not dangling". That is how 52
# `Semantic/color/*` refs went unchecked while the brand suffix was unknown here.
#
# Two brands fold onto the same key. The plugin's index keeps whichever came
# last, so a key resolves when ANY brand has it — the union below is that.
#
# The character classes are JavaScript's, not Python's: `\s`, `\d` and `.`
# differ between the two engines (`\x1c`, `﻿`, `\r`, non-ASCII digits),
# and a mirror that folds a name the plugin does not is a green gate over a
# lookup that throws. Unreachable with today's exporter, so this is for the
# day a collection is named with one of them.
_JS_WS = (
    r'[\t\n\v\f\r    -     　﻿]'
)
_JS_NOT_EOL = r'[^\n\r  ]'


def canon(name):
    n = re.sub(r'^[0-9]+(?:-[0-9]+)*\.' + _JS_WS + '*', '', name)
    n = re.sub('/' + _JS_WS + '+', '/', n)
    n = re.sub(_JS_WS + r'*·' + _JS_WS + '*' + _JS_NOT_EOL + r'+\Z', '', n)
    return 'Semantic' if n == 'Semantic/Color' else n


def canonical_fn_text(text):
    """The two plugin functions `canon()` mirrors, normalised so only a change
    of logic — not of whitespace or comments — differs. None if absent."""
    out = []
    for fn in ('canonicalCollection', 'withoutOrderingPrefix'):
        m = re.search(r'^export function ' + fn + r'\b.*?^\}', text, re.M | re.S)
        if not m:
            return None
        body = re.sub(r'//[^\n]*|/\*.*?\*/', ' ', m.group(0), flags=re.S)
        out.append(re.sub(r'\s+', ' ', body).strip())
    return '\n'.join(out)


have = {
    f"{canon(c['name'])}/{v['name']}"
    for c in tokens['collections']
    for v in c.get('variables', [])
}
groups = {k.rsplit('/', 1)[0] for k in have}


def group_of(ref):
    return ref.split('/')[1] if '/' in ref else '(no group)'


# ── Part 1: components.json refs ────────────────────────────────────────────
# Read two ways and take the union, so neither can narrow the gate alone:
#   · every string under a `ref` key — independent of how collections are
#     named, so a renamed collection shows up as dangling, not as invisible;
#   · every string anywhere that starts with a collection the token file
#     declares — independent of the key, so refs moved under another key are
#     still read.
ref_values = []


def walk(node):
    if isinstance(node, dict):
        for key, value in node.items():
            if key == 'ref' and isinstance(value, str):
                ref_values.append(value)
            walk(value)
    elif isinstance(node, list):
        for value in node:
            walk(value)


walk(components)
collection_names = sorted(
    {canon(c['name']) for c in tokens['collections']},
    key=len,
    reverse=True,
)
refs = set(ref_values) | set(
    re.findall(
        r'"((?:' + '|'.join(re.escape(c) for c in collection_names) + r')/[^"]+)"',
        components_text,
    )
)
missing = sorted(refs - have)

# ── Part 2: the plugin's own accessors ──────────────────────────────────────
# `components.json` refs are only half the surface. A builder can also ask for
# a variable directly — `lk.size(16)` — and `VarLookup` builds that key from a
# string written in its own source, not from the JSON. If nothing it asks for
# exists, the lookup throws and nothing rolls the entry back — the entry is
# reported as failed and a half-drawn component is left on the canvas, looking
# finished. That is exactly how `size()` broke 17 of 101 entries while every
# JSON ref was clean.
#
# Each `this.get(...)` / `this.tryGet(...)` inside a member is one attempt. An
# accessor is broken only when NONE of its attempts resolves: several accessors
# deliberately try a current name and then a legacy one (`font/size/<n>` →
# `font-size/<n>`) so a document imported before a regroup still binds, and the
# legacy half is always absent from a current export.
#
# An attempt is a pattern over the variable keys: literal text must match, an
# interpolation stands for one path segment. `letter-spacing/size-${n}` asks for
# `letter-spacing/size-14`; `space/${n}px` asks for keys no export has. A key
# written without interpolation must exist as written (`a11y/touch` is not
# `a11y/touch-target`). A leaf that is wholly a parameter only needs its
# collection to hold something. A leaf that starts with an interpolation and
# goes on (`${group}/${n}`) cannot be read at all. An accessor may also resolve
# by SCANNING the index for a prefix (`fontFamily` walks `Primitives/font/family/`,
# because the live library keys families by their own name) — that scan is an
# attempt too, but only inside a member that actually reads `this.byKey`.
#
# Anything this cannot read is a failure, not a skip: an accessor whose attempts
# are unreadable is an accessor this gate cannot vouch for, and skipping it is
# the silent narrowing this file exists to catch.
class LexError(Exception):
    pass


def lex_class_body(text, brace_at):
    """Walk the class from its opening brace to its closing one, tracking
    comments, string / template literals and bracket depth. Returns the body
    twice, same length: `clean` (comments blanked, literals kept) and `masked`
    (comments blanked, literal contents replaced by NUL) — call sites are found
    on `masked` so a quoted `this.get(` never counts, then read from `clean`."""
    n = len(text)
    clean, masked = [], []

    def blank(a, b):
        seg = re.sub(r'[^\n]', ' ', text[a:b])
        clean.append(seg)
        masked.append(seg)

    def template(i):
        clean.append('`')
        masked.append('`')
        i += 1
        while i < n:
            c = text[i]
            if c == '\\':
                clean.append(text[i:i + 2])
                masked.append('\x00' * len(text[i:i + 2]))
                i += 2
            elif c == '`':
                clean.append('`')
                masked.append('`')
                return i + 1
            elif c == '$' and text[i + 1:i + 2] == '{':
                clean.append('${')
                masked.append('${')
                i = code(i + 2)
                clean.append('}')
                masked.append('}')
                i += 1
            else:
                clean.append(c)
                masked.append('\n' if c == '\n' else '\x00')
                i += 1
        raise LexError('unterminated template literal')

    def code(i):
        depth = 0
        while i < n:
            c = text[i]
            nxt = text[i + 1:i + 2]
            if c == '/' and nxt == '/':
                j = text.find('\n', i)
                j = n if j < 0 else j
                blank(i, j)
                i = j
                continue
            if c == '/' and nxt == '*':
                j = text.find('*/', i + 2)
                if j < 0:
                    raise LexError('unterminated block comment')
                blank(i, j + 2)
                i = j + 2
                continue
            if c in '\'"':
                j = i + 1
                while j < n and text[j] != c:
                    if text[j] == '\n':
                        raise LexError('newline inside a string literal')
                    j += 2 if text[j] == '\\' else 1
                if j >= n:
                    raise LexError('unterminated string literal')
                j += 1
                clean.append(text[i:j])
                masked.append(c + '\x00' * (j - i - 2) + c)
                i = j
                continue
            if c == '`':
                i = template(i)
                continue
            if c in '{([':
                depth += 1
            elif c in '})]':
                if depth == 0:
                    if c == '}':
                        return i
                    raise LexError('unbalanced ' + c)
                depth -= 1
            clean.append(c)
            masked.append(c)
            i += 1
        raise LexError('the class is never closed')

    code(brace_at + 1)
    return ''.join(clean), ''.join(masked)


def split_members(mask):
    """Chunks of the class body. A member starts on a line indented exactly two
    spaces while no bracket is open — depth is what separates a member from the
    continuation of a multi-line one, so arrow-function properties, nested
    generics and `#private` members all start a chunk like any other."""
    bounds = [0]
    depth = 0
    for idx, ch in enumerate(mask):
        if ch in '{([':
            depth += 1
        elif ch in '})]':
            depth -= 1
        elif ch == '\n' and depth == 0 and re.match(r'  [A-Za-z_#@$]', mask[idx + 1:idx + 4]):
            bounds.append(idx + 1)
    bounds.append(len(mask))
    return [(bounds[i], bounds[i + 1]) for i in range(len(bounds) - 1)]


MODIFIERS = r'(?:(?:public|private|protected|static|readonly|async|override|abstract|declare|get|set)\s+)*'
member_name_re = re.compile(r'\s*' + MODIFIERS + r'(#?[\w$]+)')
call_re = re.compile(r'this\s*\??\.\s*(?:tryGet|get)\s*\(')
attempt_re = re.compile(
    r'this\s*\??\.\s*(?:tryGet|get)\s*\(\s*'
    r'(?P<q>[\'"])(?P<coll>[^\'"]+)(?P=q)\s*,\s*'
    r'(?:`(?P<tpl>[^`]*)`|(?P<q2>[\'"])(?P<lit>[^\'"]*)(?P=q2)|(?P<ident>[A-Za-z_$][\w$]*))'
    r'\s*,?\s*\)'
)
scan_re = re.compile(r'startsWith\s*\(\s*([\'"`])([^\'"`$]+)\1\s*\)')
interp_re = re.compile(r'\$\{[^}]*\}')
SKIP = {'constructor', 'get', 'tryGet'}  # the index itself, not accessors

decl = re.search(r'^export class VarLookup\b([^{]*)\{', src, re.M)
extends = bool(decl and re.search(r'\bextends\b', decl.group(1)))
attempts = collections.defaultdict(list)  # accessor → [(kind, pattern/prefix, shown)]
unread = []
lex_error = None
member_count = 0

if decl and not extends:
    try:
        body, mask = lex_class_body(src, decl.end() - 1)
    except LexError as e:
        lex_error = str(e)
        body = mask = ''
    chunks = split_members(mask) if mask else []
    names = []
    for a, b in chunks:
        m = member_name_re.match(mask[a:b])
        names.append(m.group(1) if m else None)
    member_count = sum(1 for nm in names if nm)
    declared = {nm for nm in names if nm}
    for (a, b), name in zip(chunks, names):
        if not name:
            continue
        cm, cc = mask[a:b], body[a:b]
        for call in call_re.finditer(cm):
            m = attempt_re.match(cc, call.start())
            if not m:
                snippet = cc[call.start():].split('\n', 1)[0].strip()
                unread.append(f'{name}: {snippet}')
                continue
            coll = canon(m.group('coll'))
            if m.group('tpl') is not None:
                tpl = m.group('tpl')
                pieces = interp_re.split(tpl)
                if not interp_re.search(tpl):
                    attempts[name].append(('re', re.escape(f'{coll}/{tpl}'), f'{coll}/{tpl}'))
                elif pieces == ['', '']:
                    attempts[name].append(('prefix', f'{coll}/', f'{coll}/'))
                elif pieces[0] == '':
                    unread.append(f'{name}: the leaf starts with an interpolation — {tpl}')
                else:
                    pat = '[^/]+'.join(re.escape(p) for p in pieces)
                    attempts[name].append(('re', re.escape(coll + '/') + pat, f'{coll}/{tpl}'))
            elif m.group('lit') is not None:
                attempts[name].append(('re', re.escape(f"{coll}/{m.group('lit')}"), f"{coll}/{m.group('lit')}"))
            else:
                attempts[name].append(('prefix', f'{coll}/', f'{coll}/'))
        if name in SKIP:
            continue
        reads_index = re.search(r'this\s*\.\s*byKey\b', cm) is not None
        if re.search(r'this\s*\.\s*byKey\s*\.\s*(?:get|has)\s*\(', cm):
            unread.append(f'{name}: reads this.byKey directly')
        elif reads_index:
            scans = [m for m in (scan_re.match(cc, s.start()) for s in re.finditer(r'startsWith\s*\(', cm)) if m]
            for m in scans:
                attempts[name].append(('prefix', m.group(2), m.group(2)))
            if not scans:
                unread.append(f'{name}: iterates this.byKey without a literal startsWith')
        for call in re.finditer(r'this\s*\.\s*([\w$]+)\s*\(', cm):
            callee = call.group(1)
            if callee in declared and callee not in SKIP and callee != name:
                if re.match(r'this\s*\.\s*[\w$]+\s*\(\s*[\'"`]', cc[call.start():]):
                    unread.append(f'{name}: hands a literal to this.{callee}(…)')


def resolves(attempt):
    kind, key, _ = attempt
    if kind == 're':
        return any(re.fullmatch(key, k) for k in have)
    return any(k.startswith(key) for k in have)


bad = {
    name: tries
    for name, tries in attempts.items()
    if not any(resolves(t) for t in tries)
}
attempt_count = sum(len(t) for t in attempts.values())

real_fn = canonical_fn_text(src)
pinned_fn = canonical_fn_text(pinned_src)

if mode == '--selftest':
    lines = [f'accessor {n} {"bad" if n in bad else "ok"}' for n in attempts]
    lines += [f'unread {u}' for u in unread]
    lines += [f'ref-missing {r or "<empty>"}' for r in missing]
    lines.append(f'refs {len(refs)} (under ref {len(set(ref_values))})')
    if not decl:
        lines.append('decl missing')
    if extends:
        lines.append('decl-extends')
    if lex_error:
        lines.append(f'lex-error {lex_error}')
    lines.append(f'canonical-fn {"present" if real_fn else "absent"}')
    print('\n'.join(sorted(lines)))
    sys.exit(0)

if mode == '--report':
    print(f'VarLookup 선언         {varlookup_path}')
    print(f'components.json ref   {len(refs)}  (ref 키 고유값 {len(set(ref_values))})')
    print(f'tokens.figma.json 변수 {len(have)}  (그룹 {len(groups)})')
    print(f'dangling ref          {len(missing)}')
    print(f'VarLookup 멤버         {member_count}  → 접근자 {len(attempts)} (조회 {attempt_count})'
          f'  · 깨진 접근자 {len(bad)} · 읽지 못한 호출 {len(unread)}')
    print(f'플러그인 규칙 사본      {"픽스처와 같다" if real_fn == pinned_fn else "다르다"}')
    for name, tries in sorted(bad.items()):
        print(f'   {name}: ' + ' | '.join(t[2] for t in tries))
    for u in unread:
        print(f'   읽지 못함 — {u}')
    if missing:
        by = collections.Counter(group_of(m) for m in missing)
        print()
        for g, n in by.most_common():
            print(f'  {g:16} {n}')
        print()
        for m in missing:
            print('  ', m or '<empty>')
    sys.exit(0)

if not decl:
    print(f'❌ {varlookup_path} 에서 `export class VarLookup` 을 읽지 못했다.')
    sys.exit(1)

if extends:
    print(f'❌ VarLookup 이 다른 클래스를 extends 한다 — 접근자가 부모에도 있을 수 있어')
    print('   이 가드는 자기 본문만 읽는다. 검사 범위를 모른 채 통과시키지 않는다.')
    print('   부모 클래스까지 읽도록 이 가드를 고쳐라.')
    sys.exit(1)

if lex_error:
    print(f'❌ VarLookup 본문을 어휘 분석하다 동기를 잃었다 — {lex_error}.')
    print('   정규식 리터럴 안의 따옴표나 괄호처럼 이 분석이 모르는 형태일 수 있다.')
    print('   분석을 고쳐라 — 못 읽은 채 통과시키지 않는다.')
    sys.exit(1)

if real_fn is None:
    print(f'❌ {varlookup_path} 에서 `canonicalCollection` · `withoutOrderingPrefix` 를 찾지 못했다.')
    print('   이 가드의 `canon()` 은 그 두 함수의 사본이다 — 함수가 다른 파일로 옮겨 갔다면')
    print('   가드가 읽는 위치와 기준 사본(픽스처)을 같이 옮겨라.')
    sys.exit(1)

if real_fn != pinned_fn:
    print('❌ 플러그인의 `canonicalCollection` / `withoutOrderingPrefix` 가 이 가드의 기준 사본과 다르다.')
    print()
    print('   이 가드의 `canon()` 은 그 함수의 손 복사본이다. 플러그인만 바뀌면 가드가')
    print('   실제와 다른 이름으로 컬렉션을 접어, 풀리지 않는 조회를 풀린다고 말한다.')
    print('   고칠 곳 둘: ① 이 스크립트의 `canon()` ② 픽스처 `figma_variable_refs.varlookup.ts.txt`')
    print('   안의 두 함수 사본. 두 번째를 먼저 바꾸면 이 비교가 곧 통과한다.')
    sys.exit(1)

if unread:
    print(f'❌ VarLookup 의 조회 {len(unread)}건을 이 가드가 읽지 못한다.')
    print()
    for u in unread:
        print('   ', u)
    print()
    print('   읽지 못한 조회가 가리키는 변수가 있는지는 아무도 확인하지 않는다.')
    print('   컬렉션과 키를 리터럴로 적거나, 이 가드가 그 형태를 읽게 고쳐라.')
    sys.exit(1)

if not attempts:
    print(f'❌ {varlookup_path} 의 VarLookup 에서 접근자를 하나도 읽지 못했다.')
    print('   0 개는 "전부 존재" 가 아니라 "아무것도 확인하지 않았다" 다 — 파서가')
    print('   클래스 구조를 놓쳤다는 신호다.')
    sys.exit(1)

if bad:
    print(f'❌ VarLookup 접근자 {len(bad)}개가 존재하지 않는 변수만 찾는다.')
    print()
    for name, tries in sorted(bad.items()):
        print(f'    {name}: ' + ' | '.join(t[2] for t in tries))
    print()
    print('   빌더가 `lk.<accessor>(n)` 을 호출하면 throw 하고, 롤백되지 않는다 —')
    print('   그 엔트리가 실패로 보고되고 그리다 만 컴포넌트가 캔버스에 남는다.')
    print('   그룹을 export 하거나, 접근자를 실재하는 그룹에 매핑해라')
    print(f'   ({varlookup_path} 의 `VarLookup.size` 가 `space/` 로 물러서는 것과 같은 방식).')
    sys.exit(1)

if not ref_values:
    print('❌ components.json 에서 `ref` 를 하나도 읽지 못했다 — 키 이름이 바뀌었거나')
    print('   리더가 ref 를 내지 않는다. 0 개는 "dangling 0" 이 아니다.')
    sys.exit(1)

if missing:
    by = collections.Counter(group_of(m) for m in missing)
    print(f'❌ components.json 이 존재하지 않는 Figma 변수 {len(missing)}개를 참조한다.')
    print()
    for g, n in by.most_common():
        print(f'   {g}/*  {n}개')
    print()
    for m in missing[:20]:
        print('   ', m or '<empty>')
    if len(missing) > 20:
        print(f'    … 그리고 {len(missing) - 20}개 더')
    print()
    print('   빌더가 이 변수를 찾으면 throw 하고, 롤백되지 않는다 — 그 엔트리가')
    print('   실패로 보고되고 그리다 만 컴포넌트가 캔버스에 남는다.')
    print()
    print('   고칠 곳은 둘 중 하나다:')
    print('     · 그 그룹을 export 해야 한다면  → export_figma_tokens.dart')
    print('     · export 하지 않는 게 결정이면  → figma_reader/token_scale.dart 의')
    print('       NamespaceSpec.refGroup 으로 실재하는 그룹에 매핑')
    sys.exit(1)

print(
    f'✅ G12 변수 ref {len(refs)}개 · VarLookup 접근자 {len(attempts)}개'
    f'(조회 {attempt_count}) 전부 tokens.figma.json 에서 풀린다 (dangling 0).'
)
PY
}

# Self-test — runs on every invocation, before the real check. A parser that
# silently stops reading reports "0 checked" exactly like a clean tree, so it
# proves itself on known shapes first: the fixture VarLookup holds one member
# per shape the parser has to read (and members that must come out broken,
# unread, or invisible to a naive parser), and the fixture refs hold one per
# capture path. An empty answer is a failure — a fixture that cannot be found
# makes both sides of the comparison empty, which is equal.
selftest_one() {
  local label=$1 components=$2 tokens=$3 ts=$4 expected=$5 got
  if [ ! -s "$expected" ]; then
    echo "❌ G12 self-test($label): 기대 파일이 없거나 비어 있다 — $expected"
    return 1
  fi
  if ! got=$(check "$components" "$tokens" "$ts" --selftest 2>&1); then
    echo "❌ G12 self-test($label): 파서가 픽스처를 읽다가 실패했다."
    printf '%s\n' "$got"
    return 1
  fi
  if [ -z "$got" ]; then
    echo "❌ G12 self-test($label): 파서가 아무것도 내지 않았다."
    return 1
  fi
  if [ "$got" != "$(cat "$expected")" ]; then
    echo "❌ G12 self-test($label): 픽스처를 잘못 읽었다 — 아래 판정이 기대와 다르다."
    echo "--- expected ($expected)"
    cat "$expected"
    echo "--- got"
    printf '%s\n' "$got"
    return 1
  fi
}

selftest() {
  selftest_one main \
    "$FIXTURES/figma_variable_refs.components.json" \
    "$FIXTURES/figma_variable_refs.tokens.json" \
    "$PINNED_TS" \
    "$FIXTURES/figma_variable_refs.expected.txt" || return 1
  selftest_one extends \
    "$FIXTURES/figma_variable_refs.components.json" \
    "$FIXTURES/figma_variable_refs.tokens.json" \
    "$FIXTURES/figma_variable_refs.extends.ts.txt" \
    "$FIXTURES/figma_variable_refs.extends.expected.txt" || return 1
}

selftest || exit 1

if [ ! -f "$COMPONENTS" ]; then
  echo "❌ $COMPONENTS 없음 — melos run export:figma-components"
  exit 1
fi

if [ ! -f "$TOKENS" ]; then
  echo "ℹ️  $TOKENS 없음 — 생성한다 (결정론적 산출물, gitignore 대상)."
  if ! dart run "$EXPORTER" >/dev/null 2>&1; then
    echo "❌ 토큰 exporter 실행 실패 — dart run $EXPORTER 를 직접 돌려 확인해라."
    exit 1
  fi
fi

# The class is found by its declaration, not by a path: it has already moved
# once (out of helpers.ts), and a guard reading the file it left counted zero
# accessors and passed for as long as nobody looked at the number.
declarers=$(grep -rlE '^export class VarLookup([^A-Za-z0-9_$]|$)' \
  "$PLUGIN_SRC" --include='*.ts' || true)
if [ -z "$declarers" ]; then
  echo "❌ $PLUGIN_SRC 아래에서 \`export class VarLookup\` 선언을 찾지 못했다."
  exit 1
fi
if [ "$(printf '%s\n' "$declarers" | wc -l | tr -d ' ')" != "1" ]; then
  echo "❌ \`export class VarLookup\` 선언이 여러 파일에 있다 — 어느 것을 검사할지 모른다."
  printf '    %s\n' $declarers
  exit 1
fi

check "$COMPONENTS" "$TOKENS" "$declarers" "${1:-check}"
