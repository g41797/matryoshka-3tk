"""Shared LOC-counting logic for src/*.c3. Implements L-1 of
3tk-staging-plan-030.md: a line counts when it is real code -- not blank, not
comment, not the machinery (`import`, `$include`, `$exec`, `$embed`).

Unlike ztk's src_loc.py, this cannot be a per-line startswith test. C3 has
`/* */` block comments and `<* *>` doc blocks, both of which carry state
across lines, so the whole file is scanned once to blank out every comment
and doc-block span (and to skip over string literals, so a `//` or `/*`
inside a string does not open a false comment) before counting is done
line by line.
"""

import glob
import os
import re

_MACHINERY_RE = re.compile(r'^(import\s|\$include\(|\$exec\(|\$embed\()')


def _strip_comments(text: str) -> str:
    """Return `text` with every comment and doc-block span replaced by
    spaces (newlines kept), so line numbers and blank/non-blank shape are
    unchanged."""
    out = []
    i = 0
    n = len(text)
    while i < n:
        two = text[i:i + 2]
        if two == '/*' or two == '<*':
            end = '*/' if two == '/*' else '*>'
            j = text.find(end, i + 2)
            j = n if j == -1 else j + 2
            out.append(re.sub(r'[^\n]', ' ', text[i:j]))
            i = j
        elif two == '//':
            j = text.find('\n', i)
            j = n if j == -1 else j
            out.append(re.sub(r'[^\n]', ' ', text[i:j]))
            i = j
        elif text[i] == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == '\\' else 1
            j = min(j + 1, n)
            out.append(text[i:j])
            i = j
        else:
            out.append(text[i])
            i += 1
    return ''.join(out)


def _counts(stripped_line: str) -> bool:
    if not stripped_line:
        return False
    if _MACHINERY_RE.match(stripped_line):
        return False
    return True


def count_file_loc(filepath: str) -> int:
    with open(filepath, 'r', encoding='utf-8') as f:
        text = f.read()
    stripped_text = _strip_comments(text)
    total = 0
    for raw_line, stripped in zip(text.splitlines(), stripped_text.splitlines()):
        if _counts(stripped.strip()):
            total += 1
    return total


def count_src_loc(src_dir: str) -> int:
    total = 0
    for filepath in sorted(glob.glob(os.path.join(src_dir, '*.c3'))):
        total += count_file_loc(filepath)
    return total
