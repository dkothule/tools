# md2pdf Architecture

## Purpose

`md2pdf` converts Markdown to PDF with a specific focus on Mermaid diagrams rendered as vector assets so diagrams stay sharp at any zoom level in the final PDF.

## Conversion pipeline

```mermaid
flowchart LR
  A[Markdown file] --> B[md2pdf CLI]
  B --> C[Pandoc]
  C --> D[Mermaid filter]
  D --> E[Mermaid CLI mmdc]
  E --> F[SVG or PDF vector assets]
  C --> G[PDF engine]
  F --> G
  G --> H[Output PDF]
```

## Mermaid rendering strategy

```mermaid
flowchart TD
  A[Fenced mermaid block] --> B[Render SVG]
  B --> C{foreignObject in SVG?}
  C -->|No| D[Use SVG in PDF pipeline]
  C -->|Yes| E{MERMAID_AUTO_PDF_FALLBACK=true?}
  E -->|No| D
  E -->|Yes| F[Render Mermaid PDF with --pdfFit]
  F --> G[Use fit-to-content PDF asset]
```

## Components

- `bin/md2pdf`
  - Main CLI entrypoint.
  - Loads config from global/project/optional explicit config file.
  - Normalizes markdown input (tables, list parsing compatibility, list spacing, Unicode cleanup).
  - Invokes pandoc with the Mermaid filter and PDF engine.
  - Supports `latex` (default) and `chromium` renderer modes.
  - Optionally cleans temporary Mermaid assets after conversion.
- `lib/pandoc_mermaid_filter.py`
  - Detects fenced Mermaid blocks during pandoc filtering.
  - Calls `mmdc` to render each diagram.
  - Uses `MERMAID_LATEX_FORMAT=svg` by default for high-resolution vector output.
  - Rewrites Mermaid blocks to image references so pandoc includes Mermaid-rendered assets.
- `lib/run_pandoc_mermaid_filter.sh`
  - Wrapper that runs the Python filter with configured Python executable.
- `assets/table-style.tex`
  - Optional LaTeX header for table formatting.
- `assets/mermaid.config.json`
  - Default Mermaid config for PDF-safe text rendering (`flowchart.htmlLabels=false`).
  - Ensures edge labels use opaque backgrounds so arrow lines do not strike through label text.

## Configuration model

Load order (later overrides earlier):

1. `$HOME/.config/md2pdf/config.env`
2. `<input-markdown-directory>/.md2pdfrc`
3. `--config <file>`
4. Environment variables
5. CLI cleanup flags (`--keep-mermaid-assets`, `--cleanup-mermaid-assets`)

Defaults:

- `PDF_RENDERER=latex`
- `PDF_ENGINE=xelatex`
- `LR_MARGIN=0.7in`
- `TB_MARGIN=0.5in`
- `MERMAID_CONFIG=assets/mermaid.config.json`
- `MERMAID_LATEX_FORMAT=svg`
- `CHROMIUM_MERMAID_FORMAT=png`
- `LATEX_EMOJI_MODE=auto`
- `LATEX_EMOJI_MONO_FONT=DejaVu Sans`
- `MERMAID_PDF_FIT=true`
- `MERMAID_AUTO_PDF_FALLBACK=true`
- `CLEANUP_MERMAID_ASSETS=true`
- `MERMAID_ASSET_PREFIX=md2pdf-mermaid`

## Markdown normalization behavior

Before pandoc conversion, `bin/md2pdf` applies lightweight normalization:

- Add a missing blank line before pipe-table headers so pipe tables parse reliably.
- Use pandoc input mode `markdown+lists_without_preceding_blankline` so lists after bold lead-ins still parse as lists.
- Trim trailing two-space hard-break markers on list-item lines to keep list spacing tight.
- Remove variation selectors (`U+FE0E`, `U+FE0F`) from input text.
- In LaTeX mode, map common Unicode symbols (`≥`, `≤`, `↗`) to LaTeX-safe equivalents via generated `newunicodechar` mappings.

## Temporary Mermaid assets

For each conversion run with Mermaid content, md2pdf creates:

- `<MERMAID_ASSET_PREFIX>-<run-id>-images/`

This directory contains `.mmd` and Mermaid output files (`.svg` by default).
By default it is removed after conversion (`CLEANUP_MERMAID_ASSETS=true`).

## Finder Quick Action (macOS)

- `scripts/install_md2pdf_quick_action.sh` creates a Finder Quick Action.
- `scripts/uninstall_md2pdf_quick_action.sh` removes it.
- These scripts are macOS-only and independent of Linux CLI support.

## Validation and samples

- Smoke test: `tests/architecture-smoke-test.md`
- Full Mermaid sample suite: `tests/samples/mermaid-all-diagram-types.md`
