#!/usr/bin/env python3
"""Validate the bilingual (Bengali + English) documentation of ready-fast.

Run from anywhere:  python3 tools/validate-docs.py

The script exits with status 1 and prints every problem when the
documentation is incomplete or the two languages have drifted apart.

Checks:
   1. Structure      - every required file exists in docs/bn and docs/en.
   2. Translations   - every English document has a Bengali one and vice versa.
   3. Scripts        - every script in scripts/ has a document in both languages,
                       and no document describes a script that does not exist.
   4. Script docs    - each script document has the 13 required sections.
   5. Synchronicity  - both versions of a document have the same heading
                       outline, identical code blocks, the same inline code
                       and the same links.
   6. Links          - relative links point to files that exist.
   7. Language links - each document links to its translation; the root README
                       and docs/README.md link to both languages.
   8. CLI commands   - every documented "ready-fast <command>", script name and
                       --option really exists; every real command, script and
                       option is documented in both languages.
   9. Content        - no empty or placeholder documents; Bengali documents are
                       written in Bengali and English ones in English.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
LANGS = ("bn", "en")

TOPIC_DOCS = [
    "README.md",
    "installation.md",
    "quick-start.md",
    "commands.md",
    "supported-os.md",
    "security.md",
    "troubleshooting.md",
    "docker.md",
    "networking.md",
    "firewall.md",
    "monitoring.md",
    "backup.md",
]

SCRIPT_SECTIONS = {
    "en": [
        "Introduction",
        "What it does",
        "Supported OS",
        "Requirements",
        "Installation command",
        "Step-by-step explanation",
        "Command options",
        "Expected output",
        "Security considerations",
        "Side effects",
        "Rollback instructions",
        "Troubleshooting",
        "Testing status",
    ],
    "bn": [
        "পরিচিতি",
        "কী কাজ করে",
        "সমর্থিত অপারেটিং সিস্টেম",
        "যা যা প্রয়োজন",
        "ইনস্টলেশন কমান্ড",
        "ধাপে ধাপে ব্যাখ্যা",
        "কমান্ড অপশন",
        "প্রত্যাশিত আউটপুট",
        "নিরাপত্তা বিষয়ক সতর্কতা",
        "সিস্টেমে যেসব পরিবর্তন হয়",
        "আগের অবস্থায় ফিরে যাওয়া (Rollback)",
        "সমস্যা সমাধান",
        "টেস্টিং স্ট্যাটাস",
    ],
}

# Languages allowed after an opening code fence. Blocks marked "bash" or "cron"
# hold commands and are checked against the real CLI; "text" blocks hold output.
FENCE_LANGS = {"bash", "cron", "text"}
COMMAND_FENCES = {"bash", "cron"}

PLACEHOLDER_PATTERNS = [
    r"\bTODO\b",
    r"\bTBD\b",
    r"\bFIXME\b",
    r"coming soon",
    r"lorem ipsum",
    r"work in progress",
    r"to be written",
    r"শীঘ্রই আসছে",
    r"পরে লেখা হবে",
    r"অনুবাদ বাকি",
]

MIN_PROSE_CHARS = 500
MIN_BENGALI_RATIO = 0.60

BENGALI = re.compile(r"[ঀ-৿]")
LATIN = re.compile(r"[A-Za-z]")
FENCE = re.compile(r"^```(.*)$")
HEADING = re.compile(r"^(#{1,6})\s+(.*\S)\s*$")
LINK = re.compile(r"(?<!!)\[[^\]]*\]\(([^)\s]+)\)")
IMAGE = re.compile(r"!\[[^\]]*\]\(([^)\s]+)\)")
INLINE_CODE = re.compile(r"`([^`\n]+)`")
INVOCATION = re.compile(r"(?:^|(?<=[\s;&|(]))(?:\./|/usr/local/bin/|/opt/ready-fast/)?ready-fast[ \t]+([^\s`]+)(?:[ \t]+([^\s`]+))?")
# Text that may stand directly in front of "ready-fast" when it is the command
# being run: nothing, sudo, a shell separator, or a cron schedule.
COMMAND_POSITION = re.compile(r"(?:^|[;&|(]|\bsudo|^[\d*/,\- ]+)$")
OPTION = re.compile(r"(?<![\w-])(--[a-z][a-z-]*)")
HELP_OPTION = re.compile(r"^\s{2}(--[a-z][a-z-]*)", re.MULTILINE)

errors: list[str] = []


def error(path: Path | str, message: str) -> None:
    where = path.relative_to(ROOT) if isinstance(path, Path) else path
    errors.append(f"{where}: {message}")


class Doc:
    """A parsed Markdown file."""

    def __init__(self, path: Path) -> None:
        self.path = path
        self.text = path.read_text(encoding="utf-8")
        self.lines = self.text.splitlines()
        self.headings: list[tuple[int, str]] = []
        self.code_blocks: list[tuple[str, str]] = []  # (language, content)
        self.prose_lines: list[str] = []
        self._parse()
        self.prose = "\n".join(self.prose_lines)
        self.inline_code = INLINE_CODE.findall(self.prose)
        self.links = LINK.findall(self.prose) + IMAGE.findall(self.prose)

    def _parse(self) -> None:
        in_block = False
        lang = ""
        buf: list[str] = []
        for number, line in enumerate(self.lines, start=1):
            fence = FENCE.match(line)
            if fence:
                if not in_block:
                    in_block = True
                    lang = fence.group(1).strip()
                    buf = []
                    if lang not in FENCE_LANGS:
                        error(
                            self.path,
                            f"line {number}: code fence must name one of {sorted(FENCE_LANGS)}, found '{lang}'",
                        )
                else:
                    in_block = False
                    self.code_blocks.append((lang, "\n".join(buf)))
                continue
            if in_block:
                buf.append(line)
                continue
            self.prose_lines.append(line)
            heading = HEADING.match(line)
            if heading:
                self.headings.append((len(heading.group(1)), heading.group(2)))
        if in_block:
            error(self.path, "code fence is opened but never closed")

    def prose_without_code(self) -> str:
        text = INLINE_CODE.sub(" ", self.prose)
        text = re.sub(r"\]\([^)]*\)", "]", text)  # drop link targets
        return text


def run_help(command: list[str]) -> str:
    result = subprocess.run(command, capture_output=True, text=True, cwd=ROOT, check=False)
    if result.returncode != 0:
        error(" ".join(command), f"--help exited with status {result.returncode}")
    return result.stdout


def load_cli() -> tuple[set[str], dict[str, set[str]], set[str]]:
    """Return (CLI commands, {script name: options}, install.sh options)."""
    cli_text = (ROOT / "ready-fast").read_text(encoding="utf-8")
    match = re.search(r'^READY_FAST_COMMANDS="([^"]+)"', cli_text, re.MULTILINE)
    if not match:
        error("ready-fast", "READY_FAST_COMMANDS line not found")
        commands: set[str] = set()
    else:
        commands = set(match.group(1).split())

    scripts: dict[str, set[str]] = {}
    for script in sorted((ROOT / "scripts").glob("*.sh")):
        help_text = run_help(["bash", str(script), "--help"])
        scripts[script.stem] = set(HELP_OPTION.findall(help_text))

    install_options = set(HELP_OPTION.findall(run_help(["bash", str(ROOT / "install.sh"), "--help"])))
    return commands, scripts, install_options


def check_structure(script_names: list[str]) -> dict[str, dict[str, Doc]]:
    """Checks 1-3. Returns {lang: {relative path: Doc}} for files that exist."""
    docs: dict[str, dict[str, Doc]] = {lang: {} for lang in LANGS}

    for required in (ROOT / "README.md", DOCS / "README.md"):
        if not required.is_file():
            error(required, "required file is missing")

    found: dict[str, set[str]] = {}
    for lang in LANGS:
        base = DOCS / lang
        if not base.is_dir():
            error(base, "language directory is missing")
            found[lang] = set()
            continue
        found[lang] = {p.relative_to(base).as_posix() for p in base.rglob("*.md")}
        for other in base.rglob("*"):
            if other.is_file() and other.suffix != ".md":
                error(other, "only Markdown (.md) files are allowed in the documentation tree")
        for rel in sorted(found[lang]):
            docs[lang][rel] = Doc(base / rel)

    expected = set(TOPIC_DOCS) | {f"scripts/{name}.md" for name in script_names}
    for lang in LANGS:
        for rel in sorted(expected - found[lang]):
            kind = "script documentation" if rel.startswith("scripts/") else "required document"
            error(DOCS / lang / rel, f"{kind} is missing")
        for rel in sorted(found[lang] - expected):
            if rel.startswith("scripts/"):
                error(DOCS / lang / rel, f"documents a script that does not exist: scripts/{Path(rel).stem}.sh")
            else:
                error(DOCS / lang / rel, "unexpected document (add it to TOPIC_DOCS in tools/validate-docs.py)")

    for rel in sorted(found["en"] - found["bn"]):
        error(DOCS / "en" / rel, "has no Bengali translation (docs/bn/%s is missing)" % rel)
    for rel in sorted(found["bn"] - found["en"]):
        error(DOCS / "bn" / rel, "has no English translation (docs/en/%s is missing)" % rel)
    return docs


def check_script_sections(lang: str, doc: Doc) -> None:
    """Check 4."""
    sections = [title for level, title in doc.headings if level == 2]
    expected = [f"{i}. {title}" for i, title in enumerate(SCRIPT_SECTIONS[lang], start=1)]
    if sections != expected:
        for title in expected:
            if title not in sections:
                error(doc.path, f"required section is missing: '## {title}'")
        if all(title in sections for title in expected):
            error(doc.path, "level-2 sections must be exactly the 13 required sections, in order")
    h1 = [title for level, title in doc.headings if level == 1]
    if len(h1) != 1:
        error(doc.path, "must have exactly one level-1 heading")


def section_text(doc: Doc, number: int) -> str:
    """Raw text (including code blocks) of the level-2 section with this number."""
    out: list[str] = []
    active = False
    for line in doc.lines:
        heading = re.match(r"^## (\d+)\. ", line)
        if heading:
            active = int(heading.group(1)) == number
            continue
        if active:
            out.append(line)
    return "\n".join(out)


def normalise_link(target: str) -> str:
    """Make a link comparable between languages."""
    return re.sub(r"(^|/)(bn|en)/", r"\1<lang>/", target)


def check_pair(rel: str, bn: Doc, en: Doc) -> None:
    """Check 5: the two language versions must have the same technical content."""
    if [level for level, _ in bn.headings] != [level for level, _ in en.headings]:
        error(
            bn.path,
            f"heading outline differs from the English version "
            f"(bn has {len(bn.headings)} headings, en has {len(en.headings)}, or their levels differ)",
        )

    if len(bn.code_blocks) != len(en.code_blocks):
        error(bn.path, f"has {len(bn.code_blocks)} code blocks but the English version has {len(en.code_blocks)}")
    for index, (b, e) in enumerate(zip(bn.code_blocks, en.code_blocks), start=1):
        if b != e:
            error(bn.path, f"code block #{index} differs from the English version (commands and output must be identical)")

    bn_code, en_code = set(bn.inline_code), set(en.inline_code)
    for item in sorted(en_code - bn_code):
        error(bn.path, f"inline code `{item}` appears in the English version only")
    for item in sorted(bn_code - en_code):
        error(en.path, f"inline code `{item}` appears in the Bengali version only")

    counterpart = {"bn": "en", "en": "bn"}
    link_sets = {}
    for lang, doc in (("bn", bn), ("en", en)):
        own_switch = f"{'../' * rel.count('/')}../{counterpart[lang]}/{rel}"
        link_sets[lang] = {normalise_link(t) for t in doc.links if t != own_switch}
    for item in sorted(link_sets["en"] - link_sets["bn"]):
        error(bn.path, f"link target '{item}' appears in the English version only")
    for item in sorted(link_sets["bn"] - link_sets["en"]):
        error(en.path, f"link target '{item}' appears in the Bengali version only")


def check_links(doc: Doc) -> None:
    """Check 6."""
    for target in doc.links:
        if re.match(r"^[a-z][a-z0-9+.-]*:", target, re.IGNORECASE):
            continue  # http:, https:, mailto: ...
        path_part = target.split("#", 1)[0]
        if not path_part:
            continue  # link to a heading in the same file
        resolved = (doc.path.parent / path_part).resolve()
        if not resolved.exists():
            error(doc.path, f"broken link: {target}")
        elif ROOT not in resolved.parents and resolved != ROOT:
            error(doc.path, f"link leaves the repository: {target}")


def check_language_link(lang: str, rel: str, doc: Doc) -> None:
    """Check 7: a link to the translation must be near the top of the file."""
    other = "en" if lang == "bn" else "bn"
    expected = f"{'../' * rel.count('/')}../{other}/{rel}"
    head = "\n".join(doc.lines[:8])
    if f"]({expected})" not in head:
        error(doc.path, f"language link to '{expected}' is missing from the first lines of the file")


def check_landing_pages() -> None:
    """Check 7 for the root README and docs/README.md."""
    for path, targets in (
        (ROOT / "README.md", ("docs/bn/README.md", "docs/en/README.md")),
        (DOCS / "README.md", ("bn/README.md", "en/README.md")),
    ):
        if not path.is_file():
            continue
        doc = Doc(path)
        check_links(doc)
        for target in targets:
            if target not in doc.links:
                error(path, f"must link to {target}")
        if not BENGALI.search(doc.prose):
            error(path, "must contain a Bengali introduction")
        if len(LATIN.findall(doc.prose_without_code())) < 100:
            error(path, "must contain an English introduction")
        check_placeholders(doc)
        check_invocations(doc, *CLI)


def check_invocations(doc: Doc, commands: set[str], scripts: dict[str, set[str]], install_options: set[str]) -> None:
    """Check 8a: every documented command, script and option must exist."""
    sources: list[str] = list(doc.inline_code)
    for lang, content in doc.code_blocks:
        if lang in COMMAND_FENCES:
            sources.extend(content.splitlines())

    for line in sources:
        for match in INVOCATION.finditer(line):
            if not COMMAND_POSITION.search(line[: match.start()].strip()):
                continue  # "ready-fast" is an argument of another command here
            command, argument = match.group(1), match.group(2)
            if command.startswith("<"):
                continue  # placeholder such as <command>
            if command not in commands:
                error(doc.path, f"documented CLI command does not exist: 'ready-fast {command}' (in: {line.strip()})")
                continue
            if command in ("run", "info") and argument and not argument.startswith("<"):
                if argument not in scripts:
                    error(doc.path, f"documented script does not exist: '{argument}' (in: {line.strip()})")
                    continue
                if command == "run":
                    rest = line[match.end():]
                    rest = re.split(r"[|;&>]", rest, maxsplit=1)[0]
                    for option in OPTION.findall(rest):
                        if option not in scripts[argument]:
                            error(
                                doc.path,
                                f"documented option does not exist: '{option}' of script '{argument}' (in: {line.strip()})",
                            )
        if re.search(r"(?:^|[\s/])install\.sh\b", line):
            rest = line.split("install.sh", 1)[1]
            rest = re.split(r"[|;&>]", rest, maxsplit=1)[0]
            for option in OPTION.findall(rest):
                if option not in install_options:
                    error(doc.path, f"documented install.sh option does not exist: '{option}' (in: {line.strip()})")

    for reference in re.findall(r"\bscripts/([a-z0-9-]+)\.sh\b", doc.text):
        if reference not in scripts:
            error(doc.path, f"refers to a script file that does not exist: scripts/{reference}.sh")


def check_script_doc_options(name: str, doc: Doc, scripts: dict[str, set[str]]) -> None:
    """Check 8b for one script document."""
    options = scripts[name]
    section = section_text(doc, 7)
    for option in sorted(options):
        if f"`{option}" not in section:
            error(doc.path, f"option {option} of '{name}' is not documented in section 7")
    for code in doc.inline_code:
        match = re.match(r"^(--[a-z][a-z-]*)(?: <[^>]+>)?$", code)
        if match and match.group(1) not in options:
            error(doc.path, f"documents option `{match.group(1)}`, which '{name}' does not have")
    if f"ready-fast run {name}" not in section_text(doc, 5):
        error(doc.path, f"section 5 must show the command 'ready-fast run {name}'")


def check_commands_reference(doc: Doc, commands: set[str], scripts: dict[str, set[str]], install_options: set[str]) -> None:
    """Check 8c: commands.md must cover the whole CLI."""
    everything = "\n".join([*doc.inline_code, *(content for _, content in doc.code_blocks)])
    for command in sorted(commands):
        if not re.search(rf"ready-fast {re.escape(command)}\b", everything):
            error(doc.path, f"CLI command 'ready-fast {command}' is not documented")
    for name, options in sorted(scripts.items()):
        if not re.search(rf"ready-fast run {re.escape(name)}\b", everything):
            error(doc.path, f"script '{name}' is not documented (expected 'ready-fast run {name}')")
        for option in sorted(options):
            if option not in everything:
                error(doc.path, f"option {option} (script '{name}') is not mentioned")
    for option in sorted(install_options):
        if option not in everything:
            error(doc.path, f"install.sh option {option} is not mentioned")


def check_index(lang: str, doc: Doc, script_names: list[str]) -> None:
    """The language README must link to every other document."""
    for rel in TOPIC_DOCS[1:] + [f"scripts/{name}.md" for name in script_names]:
        if rel not in doc.links:
            error(doc.path, f"index must link to {rel}")


def check_placeholders(doc: Doc) -> None:
    for pattern in PLACEHOLDER_PATTERNS:
        if re.search(pattern, doc.text, re.IGNORECASE):
            error(doc.path, f"contains placeholder text matching /{pattern}/")


def check_content(lang: str, doc: Doc) -> None:
    """Check 9."""
    check_placeholders(doc)
    prose = doc.prose_without_code()
    letters = len(BENGALI.findall(prose)) + len(LATIN.findall(prose))
    if letters < MIN_PROSE_CHARS:
        error(doc.path, f"is too short to be real documentation ({letters} letters of prose, minimum {MIN_PROSE_CHARS})")
        return
    bengali = len(BENGALI.findall(prose))
    if lang == "bn":
        ratio = bengali / letters
        if ratio < MIN_BENGALI_RATIO:
            error(
                doc.path,
                f"only {ratio:.0%} of the prose is Bengali (minimum {MIN_BENGALI_RATIO:.0%}); it looks untranslated",
            )
    else:
        without_switch = "\n".join(line for line in doc.prose_lines if "](../" not in line or "/bn/" not in line)
        stray = BENGALI.findall(INLINE_CODE.sub(" ", without_switch))
        if stray:
            error(doc.path, f"English document contains {len(stray)} Bengali characters outside the language link")


CLI: tuple[set[str], dict[str, set[str]], set[str]] = (set(), {}, set())


def main() -> int:
    global CLI
    CLI = load_cli()
    commands, scripts, install_options = CLI
    script_names = sorted(scripts)
    if not script_names:
        error("scripts", "no scripts found")

    docs = check_structure(script_names)
    check_landing_pages()

    for lang in LANGS:
        for rel, doc in sorted(docs[lang].items()):
            check_links(doc)
            check_language_link(lang, rel, doc)
            check_content(lang, doc)
            check_invocations(doc, commands, scripts, install_options)
            if rel.startswith("scripts/"):
                check_script_sections(lang, doc)
                name = Path(rel).stem
                if name in scripts:
                    check_script_doc_options(name, doc, scripts)
            if rel == "commands.md":
                check_commands_reference(doc, commands, scripts, install_options)
            if rel == "README.md":
                check_index(lang, doc, script_names)

    for rel in sorted(set(docs["bn"]) & set(docs["en"])):
        check_pair(rel, docs["bn"][rel], docs["en"][rel])

    total = sum(len(docs[lang]) for lang in LANGS)
    if errors:
        print(f"Documentation validation FAILED: {len(errors)} problem(s)\n")
        for item in errors:
            print(f"  - {item}")
        return 1
    print(
        f"Documentation validation passed: {total} documents in {len(LANGS)} languages, "
        f"{len(script_names)} scripts, {len(commands)} CLI commands."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
