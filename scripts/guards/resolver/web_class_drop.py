#!/usr/bin/env python3
"""Check RULE F's empty-class ternaries without treating Dart text as code.

This is a conservative lexical check, not a Dart type checker. Unproved class
expressions remain violations. The only value provenance it follows is immutable
local aliases of the canonical color/typography emitters; a same-named parameter
or declaration in a nearer scope prevents that proof.
"""

import dataclasses
import pathlib
import re
import sys


class ScanError(ValueError):
    """The source cannot be checked safely."""


@dataclasses.dataclass
class Token:
    text: str
    start: int
    end: int
    parts: object = None
    scope: tuple = ()


class Lexer:
    def __init__(self, source):
        self.source = source

    def code(self, start=0, interpolation=False):
        source, tokens, i, stack = self.source, [], start, []
        closing = {'(': ')', '[': ']', '{': '}'}
        while i < len(source):
            if source[i].isspace():
                i += 1
                continue
            if source.startswith('//', i):
                end = source.find('\n', i)
                i = len(source) if end < 0 else end + 1
                continue
            if source.startswith('/*', i):
                nesting, i = 1, i + 2
                while i < len(source) and nesting:
                    if source.startswith('/*', i):
                        nesting, i = nesting + 1, i + 2
                    elif source.startswith('*/', i):
                        nesting, i = nesting - 1, i + 2
                    else:
                        i += 1
                if nesting:
                    raise ScanError('unclosed block comment')
                continue
            raw = source[i] in 'rR' and source[i + 1:i + 2] in ("'", '"')
            if source[i] in "'\"" or raw:
                token, i = self.string(i, raw)
                tokens.append(token)
                continue
            if interpolation and source[i] == '}' and not stack:
                return tokens, i + 1
            match = re.match(r'[A-Za-z_$][A-Za-z0-9_$]*', source[i:])
            if match:
                end = i + len(match[0])
                tokens.append(Token(match[0], i, end))
                i = end
                continue
            operator = next((v for v in ('??=', '=>', '??', '?.', '==', '!=',
                                         '<=', '>=', '&&', '||', '+=', '-=')
                             if source.startswith(v, i)), source[i])
            tokens.append(Token(operator, i, i + len(operator)))
            if operator in closing:
                stack.append(closing[operator])
            elif operator in (')', ']', '}'):
                if not stack or stack.pop() != operator:
                    raise ScanError('unmatched closing delimiter')
            i += len(operator)
        if stack or interpolation:
            raise ScanError('unclosed delimiter or interpolation')
        return tokens, i

    def string(self, start, raw):
        source, i = self.source, start + int(raw)
        quote = source[i] * (3 if source.startswith(source[i] * 3, i) else 1)
        i += len(quote)
        parts, literal = [], ''
        while i < len(source) and not source.startswith(quote, i):
            if not raw and source[i] == '\\':
                # Keep escapes opaque. They cannot establish a safe class value.
                literal += source[i:i + 2]
                i += 2
            elif not raw and source.startswith('${', i):
                parts.append(literal)
                child, i = self.code(i + 2, interpolation=True)
                parts.append(child)
                literal = ''
            elif not raw and source[i] == '$':
                match = re.match(r'\$([A-Za-z_][A-Za-z0-9_]*)', source[i:])
                if match:
                    parts.extend([literal, [Token(match[1], i + 1,
                                                 i + len(match[0]))]])
                    literal, i = '', i + len(match[0])
                else:
                    literal, i = literal + source[i], i + 1
            else:
                literal, i = literal + source[i], i + 1
        parts.append(literal)
        if not source.startswith(quote, i):
            raise ScanError('unclosed string')
        end = i + len(quote)
        return Token(source[start:end], start, end, parts), end


def expression_end(tokens, start):
    """Stop at this expression's delimiter, not the next statement semicolon."""
    stack, ternaries = [], 0
    pairs = {'(': ')', '[': ']', '{': '}'}
    for i in range(start, len(tokens)):
        text = tokens[i].text
        if text in pairs:
            stack.append(pairs[text])
        elif stack and text == stack[-1]:
            stack.pop()
        elif not stack:
            if text == '?':
                ternaries += 1
            elif text == ':' and ternaries:
                ternaries -= 1
            elif text in (',', ';', ')', ']', '}', ':'):
                return i
    return len(tokens)


def empty(token):
    return token.parts == ['']


def unparen(tokens):
    while tokens and tokens[0].text == '(':
        end = expression_end(tokens, 1)
        if end != len(tokens) - 1 or tokens[-1].text != ')':
            break
        tokens = tokens[1:-1]
    return tokens


def matching_close(tokens, start):
    pairs, stack = {'(': ')', '[': ']', '{': '}'}, []
    for i in range(start, len(tokens)):
        text = tokens[i].text
        if text in pairs:
            stack.append(pairs[text])
        elif stack and text == stack[-1]:
            stack.pop()
            if not stack:
                return i
    return None


class Checker:
    def __init__(self, source):
        self.tokens, _ = Lexer(source).code()
        self.streams, self.bindings, self.imports = [], {}, {}
        self.mutated_names = set()
        self._scopes(self.tokens, ())
        self.type_bodies = self._type_bodies()
        for stream in self.streams:
            self._declarations(stream)

    def _type_bodies(self):
        bodies = set()
        for i, token in enumerate(self.tokens):
            if (token.scope or
                    token.text not in ('class', 'mixin', 'extension', 'enum')):
                continue
            nesting = 0
            for part in self.tokens[i + 1:]:
                if part.text in ('(', '['):
                    nesting += 1
                elif part.text in (')', ']'):
                    nesting -= 1
                elif not nesting and not part.scope:
                    if part.text == ';':
                        # A class alias has no body. Do not consume the next
                        # top-level resolver's block as a type owner.
                        break
                    if part.text == '{':
                        bodies.add(part.start)
                        break
        return bodies

    def _scopes(self, tokens, outer):
        self.streams.append(tokens)
        scope, stack = outer, []
        for token in tokens:
            token.scope = scope
            if token.text == '{':
                stack.append(scope)
                scope += (token.start,)
            elif token.text == '}' and stack:
                scope = stack.pop()
            if token.parts is not None:
                for part in token.parts:
                    if isinstance(part, list):
                        self._scopes(part, token.scope)

    def _bind(self, token, expression=None, scope=None):
        self.bindings.setdefault(token.text, []).append(
            (token.scope if scope is None else scope, token.start, expression))

    def _declarations(self, tokens):
        pairs, opened, declarations = {}, [], set()
        for i, token in enumerate(tokens):
            if token.text == '(':
                opened.append(i)
            elif token.text == ')' and opened:
                pairs[i] = opened.pop()
        for i, token in enumerate(tokens):
            if token.text == 'import' and i + 1 < len(tokens):
                uri = tokens[i + 1]
                if uri.parts == ['package:coui_web/src/util/core_to_css.dart']:
                    end = expression_end(tokens, i + 2)
                    tail = [v.text for v in tokens[i + 2:end]]
                    if 'if' in tail or 'deferred' in tail:
                        # Conditional/deferred import ownership is not proved by
                        # this scanner; do not borrow the default URI's proof.
                        continue
                    prefix = tail[tail.index('as') + 1] if 'as' in tail else ''
                    self.imports[prefix] = tail
            if token.text in ('final', 'const', 'var'):
                j = i + 1
                while j < len(tokens) and tokens[j].text not in ('=', ';',
                                                               '(', ')', ',',
                                                               'in', ':', '=>'):
                    j += 1
                if j < len(tokens) and tokens[j].text == '=' and j > i + 1:
                    name = tokens[j - 1]
                    end = expression_end(tokens, j + 1)
                    value = tokens[j + 1:end] if token.text != 'var' else None
                    self._bind(name, value)
                    declarations.add(name.start)
                elif (token.text in ('final', 'var') and j == i + 1 and
                      j < len(tokens) and tokens[j].text == '('):
                    # Destructuring is not an emitter proof. Do not let an
                    # unanalysed pattern borrow a same-named outer color alias.
                    end = matching_close(tokens, j)
                    for part in tokens[j + 1:end]:
                        if re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*', part.text):
                            self.mutated_names.add(part.text)
                elif token.text in ('final', 'var') and j > i + 1:
                    # for-in and case patterns introduce real shadowing names.
                    # Conservatively withhold proof in the enclosing scope
                    # rather than pretending these constructs are assignments.
                    self._bind(tokens[j - 1])
            # A function/closure parameter shadows an emitter alias. Function
            # declarations also shadow an imported emitter with the same name.
            if token.text != ')' or i not in pairs or i + 1 >= len(tokens):
                continue
            if tokens[i + 1].text not in ('{', '=>'):
                continue
            begin = pairs[i]
            previous = tokens[begin - 1] if begin else None
            if previous and previous.text in ('if', 'for', 'while', 'switch'):
                continue
            if previous and re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*', previous.text):
                self._bind(previous)
            body_scope = (tokens[i + 1].scope + (tokens[i + 1].start,)
                          if tokens[i + 1].text == '{' else None)
            # Arrow parameter scopes do not have braces. Conservatively mark
            # their names ambiguous in the enclosing scope rather than borrowing
            # a same-named outer proof.
            segment = []
            for part in tokens[begin + 1:i] + [Token(',', 0, 0)]:
                if part.text in (',', '{', '}', '[', ']'):
                    before_default = segment[:next(
                        (n for n, v in enumerate(segment) if v.text == '='),
                        len(segment))]
                    names = [v for v in before_default
                             if re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*', v.text)]
                    if names:
                        self._bind(names[-1], scope=body_scope)
                    segment = []
                else:
                    segment.append(part)
        for i, token in enumerate(tokens[:-1]):
            if (not re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*', token.text) or
                    token.start in declarations or
                    tokens[i + 1].text not in ('=', '+=', '-=', '??=', 'in')):
                continue
            previous = tokens[i - 1].text if i else ''
            if previous in ('.', '?.'):
                continue
            if (re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*', previous) or
                    previous in ('?', '>', ']')):
                # Explicitly typed mutable locals/fields do not establish
                # immutable emitter provenance and can shadow an outer alias.
                self._bind(token)
            else:
                self.mutated_names.add(token.text)

    def _binding(self, token):
        if token.text in self.mutated_names:
            return True, None
        candidates = [v for v in self.bindings.get(token.text, [])
                      if token.scope[:len(v[0])] == v[0]]
        if not candidates:
            return False, None
        nearest = max(len(v[0]) for v in candidates)
        candidates = [v for v in candidates if len(v[0]) == nearest]
        if len(candidates) != 1 or candidates[0][1] >= token.start:
            return True, None
        return True, candidates[0][2]

    def _emitter(self, tokens, seen=None):
        tokens = unparen(tokens)
        if not tokens:
            return False
        if any(owner in self.type_bodies for owner in tokens[0].scope):
            # An inherited/mixin member can shadow the imported function (or
            # its prefix) without a declaration in this lexical source. Only
            # top-level resolver contexts have the ownership proof we need.
            return False
        seen = set() if seen is None else seen
        if len(tokens) == 1:
            if tokens[0].start in seen:
                return False
            bound, value = self._binding(tokens[0])
            return bound and value is not None and self._emitter(
                value, seen | {tokens[0].start})
        call = 1
        prefix, name = '', tokens[0]
        if len(tokens) > 3 and tokens[1].text == '.':
            prefix, name, call = tokens[0].text, tokens[2], 3
            if self._binding(tokens[0])[0]:
                return False
        if (name.text not in ('emitColor', 'emitTypography') or
                prefix not in self.imports or self._binding(name)[0] or
                tokens[call].text != '(' or tokens[-1].text != ')'):
            return False
        tail = self.imports[prefix]
        if 'show' in tail and name.text not in tail[tail.index('show') + 1:]:
            return False
        if 'hide' in tail and name.text in tail[tail.index('hide') + 1:]:
            return False
        return matching_close(tokens, call) == len(tokens) - 1

    def _color_class(self, tokens, seen=None):
        tokens = unparen(tokens)
        if not tokens:
            return False
        seen = set() if seen is None else seen
        if len(tokens) == 1:
            token = tokens[0]
            if token.parts is not None:
                return self._color_string(token, seen)
            if token.start in seen:
                return False
            bound, value = self._binding(token)
            return bound and value is not None and self._color_class(
                value, seen | {token.start})
        return (tokens[-2].text == '.' and tokens[-1].text == 'className' and
                self._emitter(tokens[:-2]))

    def _color_string(self, token, seen):
        template, holes = '', {}
        for part in token.parts:
            if isinstance(part, str):
                template += part
            else:
                marker = 'HOLE' + str(len(holes)) + 'X'
                holes[marker] = part
                template += marker
        for word in template.split():
            if word in holes and self._color_class(holes[word], seen):
                continue
            if not re.fullmatch(r'(?:(?:hover|focus|focus-visible|active|disabled):)*'
                                r'(?:ring|text|bg)-[A-Za-z0-9_./%\[\]-]+', word):
                return False
            for marker, expression in holes.items():
                if marker in word:
                    names = [v.text for v in expression]
                    chain = ''.join(names)
                    if not re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*'
                                        r'(?:!?\.[A-Za-z_][A-Za-z0-9_]*)*', chain):
                        return False
                    if not (names[-2:] == ['.', 'tailwindColor'] or
                            names[-5:] == ['.', 'token', '!', '.', 'name']):
                        return False
        return True

    @staticmethod
    def _selector(tokens):
        # A complete CSS :where(.identifier) suffix is selector text, never a
        # dimensional Tailwind utility. Extra utility words fail this proof.
        if len(tokens) != 1 or tokens[0].parts is None:
            return False
        template = ''
        for part in tokens[0].parts:
            if isinstance(part, str):
                template += part
            elif len(part) == 1 and re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*',
                                               part[0].text):
                template += 'IDENTIFIER'
            else:
                return False
        return bool(re.fullmatch(r':where\(\.[A-Za-z_][A-Za-z0-9_-]*\)', template))

    def violations(self):
        for tokens in self.streams:
            for i, token in enumerate(tokens[:-2]):
                if token.text != '?':
                    continue
                then_end = (matching_close(tokens, i + 1)
                            if tokens[i + 1].text == '(' else i + 1)
                if then_end is None:
                    continue
                then = unparen(tokens[i + 1:then_end + 1])
                colon = then_end + 1
                if len(then) != 1 or not empty(then[0]):
                    continue
                if colon >= len(tokens) or tokens[colon].text != ':':
                    continue
                end = expression_end(tokens, colon + 1)
                branch = unparen(tokens[colon + 1:end])
                if not self._color_class(branch) and not self._selector(branch):
                    yield token.start


def main(paths):
    for name in paths:
        path = pathlib.Path(name)
        try:
            source = path.read_text(encoding='utf-8')
            offsets = list(Checker(source).violations())
        except (OSError, ValueError) as error:
            print(f'RULE F could not check {name}: {error}', file=sys.stderr)
            return 1
        for offset in offsets:
            print(f'{name}:{source.count(chr(10), 0, offset) + 1}')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
