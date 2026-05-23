#!/bin/bash
set -euo pipefail

# Build a single PDF from all documentation pages in nav order
# Sources page order and hierarchy from mkdocs.yml
# Requires: pandoc, python3, a LaTeX engine (tectonic or texlive)

OUTPUT="site/bioinformatics-knowledge-base.pdf"
COMBINED="/tmp/bioinformatics-kb-combined.md"

# Generate combined markdown with hierarchy from mkdocs.yml
python3 scripts/combine-docs.py > "$COMBINED"

mkdir -p "$(dirname "$OUTPUT")"

# Detect available PDF engine
if command -v tectonic &>/dev/null; then
  PDF_ENGINE="--pdf-engine=tectonic"
elif command -v xelatex &>/dev/null; then
  PDF_ENGINE="--pdf-engine=xelatex"
elif command -v pdflatex &>/dev/null; then
  PDF_ENGINE="--pdf-engine=pdflatex"
else
  echo "ERROR: No LaTeX engine found. Install one of: tectonic, texlive, mactex" >&2
  echo "  brew install tectonic" >&2
  exit 1
fi

pandoc "$COMBINED" \
  $PDF_ENGINE \
  --metadata title="Bioinformatics Knowledge Base" \
  --metadata author="Reference Documentation for NGS Tools and File Formats" \
  --toc \
  --toc-depth=3 \
  --syntax-highlighting=tango \
  -V geometry:margin=1in \
  -V documentclass=report \
  -V colorlinks=true \
  -o "$OUTPUT"

rm -f "$COMBINED"
echo "PDF built: $OUTPUT"
