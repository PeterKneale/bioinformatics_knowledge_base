#!/usr/bin/env python3
"""Combine docs into a single markdown with hierarchy from mkdocs.yml nav."""

import re
import sys
from pathlib import Path

DOCS_DIR = Path("docs")
MKDOCS_YML = Path("mkdocs.yml")

# Map from .md file path (relative to docs/) to its nav title
# Built during emit so we can resolve cross-references
page_titles: dict[str, str] = {}


def parse_nav_from_yaml(text: str) -> list:
    """Parse the nav section from mkdocs.yml into a nested structure.
    
    Returns a list of tuples: (title, path_or_children)
    where children is a recursive list of the same shape.
    """
    lines = text.split("\n")
    nav_started = False
    nav_lines = []

    for line in lines:
        if re.match(r"^nav:", line):
            nav_started = True
            continue
        if nav_started:
            if line and not line[0].isspace() and not line.startswith("#"):
                break
            nav_lines.append(line)

    return _parse_nav_items(nav_lines, indent=2)


def _parse_nav_items(lines: list, indent: int) -> list:
    """Recursively parse indented nav items."""
    items = []
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.lstrip()
        if not stripped or stripped.startswith("#"):
            i += 1
            continue

        current_indent = len(line) - len(stripped)
        if current_indent < indent:
            break
        if current_indent > indent:
            i += 1
            continue

        # Parse "- Title: path.md" or "- Title:"
        match = re.match(r"-\s+(.+?):\s*(.+\.md)\s*$", stripped)
        if match:
            title, path = match.group(1), match.group(2)
            items.append((title, path))
            i += 1
        else:
            # Section header like "- Alignment:" with children
            match = re.match(r"-\s+(.+?):\s*$", stripped)
            if match:
                title = match.group(1)
                # Collect children at deeper indent
                children_lines = []
                i += 1
                while i < len(lines):
                    child_line = lines[i]
                    child_stripped = child_line.lstrip()
                    if not child_stripped or child_stripped.startswith("#"):
                        children_lines.append(lines[i])
                        i += 1
                        continue
                    child_indent = len(child_line) - len(child_stripped)
                    if child_indent <= current_indent:
                        break
                    children_lines.append(lines[i])
                    i += 1
                children = _parse_nav_items(children_lines, indent=current_indent + 4)
                items.append((title, children))
            else:
                i += 1

    return items


def shift_headings(content: str, levels: int) -> str:
    """Shift all markdown headings down by n levels."""
    def replacer(m):
        hashes = m.group(1)
        new_level = min(len(hashes) + levels, 6)
        return "#" * new_level + m.group(2)
    return re.sub(r"^(#{1,6})([ \t]+.*)$", replacer, content, flags=re.MULTILINE)


def collect_page_titles(items: list) -> None:
    """Walk nav tree and record path -> title mapping."""
    for title, value in items:
        if isinstance(value, str):
            page_titles[value] = title
        elif isinstance(value, list):
            collect_page_titles(value)


def title_to_anchor(title: str) -> str:
    """Convert a heading title to a pandoc-style anchor ID."""
    anchor = title.lower()
    anchor = re.sub(r"[^\w\s\-]", "", anchor)
    anchor = re.sub(r"\s+", "-", anchor.strip())
    return anchor


def rewrite_internal_links(content: str, source_path: str) -> str:
    """Convert relative .md links to internal anchor links."""
    source_dir = str(Path(source_path).parent)

    def replace_link(m):
        text = m.group(1)
        target = m.group(2)

        # Skip external links and anchors
        if target.startswith("http") or target.startswith("#"):
            return m.group(0)

        # Resolve relative path to docs-relative path
        if target.startswith("../") or target.startswith("./"):
            resolved = str((Path(source_dir) / target).resolve())
            # Make relative to docs dir
            try:
                resolved = str(Path(resolved).relative_to(Path(source_dir).resolve().parent.parent if "../" in target else Path(source_dir).resolve()))
            except ValueError:
                pass
            # Simpler: resolve against source directory
            resolved = str(Path(source_dir) / target)
            # Normalize
            parts = []
            for p in resolved.split("/"):
                if p == "..":
                    if parts:
                        parts.pop()
                elif p != ".":
                    parts.append(p)
            resolved = "/".join(parts)
        else:
            # Same directory reference
            if "/" in target:
                resolved = target
            else:
                resolved = f"{source_dir}/{target}" if source_dir != "." else target

        # Strip .md extension and any fragment
        resolved = re.sub(r"\.md(#.*)?$", "", resolved)
        md_path = resolved + ".md"

        # Look up the nav title for this page
        if md_path in page_titles:
            anchor = title_to_anchor(page_titles[md_path])
            return f"[{text}](#{anchor})"

        return m.group(0)

    return re.sub(r"\[([^\]]+)\]\(([^)]+)\)", replace_link, content)


def emit_section(items: list, depth: int) -> str:
    """Recursively emit markdown for a nav section.
    
    depth=1 for top-level parts (# Formats)
    depth=2 for sub-sections (## Alignment)
    Pages get their heading at depth+1, internal headings shifted accordingly.
    Sub-sections with children don't add extra depth for their pages.
    """
    output = []
    for title, value in items:
        if isinstance(value, str):
            # It's a file path
            filepath = DOCS_DIR / value
            if filepath.exists():
                content = filepath.read_text()
                # Rewrite internal links to anchors
                content = rewrite_internal_links(content, value)
                # Extract the H1 title from the file to use as the page heading
                h1_match = re.match(r"^#\s+(.+)", content)
                page_title = h1_match.group(1) if h1_match else title
                # Strip the first H1
                content_stripped = re.sub(r"^#\s+.*\n+", "", content, count=1)
                # Page heading at depth (same level as its category)
                page_depth = min(depth, 3)
                heading = "#" * page_depth + f" {page_title}"
                # Shift remaining headings in content
                shifted = shift_headings(content_stripped, page_depth - 1)
                # Start each page on a new page
                output.append(f"\\newpage\n\n{heading}\n\n{shifted}")
            else:
                print(f"WARNING: {filepath} not found, skipping", file=sys.stderr)
        elif isinstance(value, list):
            # It's a section with children
            heading = "#" * depth + f" {title}"
            output.append(heading + "\n")
            output.append(emit_section(value, depth + 1))

    return "\n\n".join(output)


def main():
    yaml_text = MKDOCS_YML.read_text()
    nav = parse_nav_from_yaml(yaml_text)

    # First pass: collect all page titles for cross-referencing
    collect_page_titles(nav)

    parts = []
    for title, value in nav:
        if isinstance(value, str):
            # Top-level page (e.g. Home: index.md)
            filepath = DOCS_DIR / value
            if filepath.exists():
                content = filepath.read_text()
                content = rewrite_internal_links(content, value)
                parts.append(content)
        elif isinstance(value, list):
            # Top-level section (Processes, Tools, Formats)
            heading = f"# {title}"
            parts.append(heading + "\n\n" + emit_section(value, depth=2))

    print("\n\n".join(parts))


if __name__ == "__main__":
    main()
