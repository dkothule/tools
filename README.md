# md2pdf

> Convert Markdown to PDF with high-resolution Mermaid diagrams (SVG embedded in PDF output).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

`@dkothule/md2pdf` is a Markdown to PDF CLI for macOS and Linux with first-class Mermaid support.
It keeps Mermaid diagrams sharp in PDF by rendering vector assets (SVG by default) and includes automatic fallback logic for Mermaid flowcharts/graphs when needed.

## Why md2pdf

- Markdown to PDF from the terminal.
- Mermaid to PDF with high-resolution vector rendering.
- SVG-first pipeline for crisp diagrams at any zoom level.
- Auto fallback to Mermaid PDF for diagrams that use `foreignObject` labels.
- Fit-to-content PDF fallback (`--pdfFit`) to avoid full-page diagram artifacts.
- Better edge-label readability in flowchart/graph diagrams.
- Markdown normalization for reliable output (tables, tight lists, list parsing after bold lead-ins).
- Unicode cleanup/mapping in LaTeX mode for common symbols (`≥`, `≤`, `↗`) and emoji variation selectors.
- XeLaTeX emoji assistance: uses Twemoji mapping first, then mono fallback font.
- Configurable defaults (`~/.config/md2pdf/config.env`, project `.md2pdfrc`, or `--config`).
- Optional Finder Quick Action integration on macOS.

## New Machine Bootstrap (No Homebrew or npm)

If this is a fresh machine, install package manager/runtime first:

macOS:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)" || eval "$(/usr/local/bin/brew shellenv)"
brew install node
```

Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y nodejs npm
```

Then continue with the install steps below.

## Install

### Frictionless install (recommended)

Prerequisite: Node.js + npm installed (required to install the npm package).

1) Install md2pdf:

```bash
npm i -g @dkothule/md2pdf
```

2) Install runtime dependencies (system packages + `pandocfilters`):

```bash
md2pdf-install-system-deps --yes
```

macOS recommendation: if Homebrew is healthy and network is stable, run `brew update` before this step for freshest formula metadata.

If you prefer an interactive confirmation prompt, run:

```bash
md2pdf-install-system-deps
```

3) Verify runtime tools + CLI:

```bash
pandoc --version | head -n 1
xelatex --version | head -n 1
rsvg-convert --version
python3 -c "import pandocfilters; print('pandocfilters ok')"
md2pdf --version
md2pdf --help
```

`md2pdf-install-system-deps` supports macOS (Homebrew) and Debian/Ubuntu.
Run `md2pdf-install-system-deps --help` to see options.

### Manual fallback (if helper script does not support your Linux distro)

Install these dependencies yourself:

- `pandoc`
- LaTeX PDF engine (`xelatex` default)
- `librsvg` / `rsvg-convert`
- `python3` + `pip`
- `node` + `npm`

Then install the Python dependency:

```bash
python3 -m pip install pandocfilters
```

## System requirements

- `pandoc`
- LaTeX PDF engine (`xelatex` default)
- `librsvg` / `rsvg-convert`
- `python3`
- `node` + `npm`
- `chrome`/`chromium` (only when using `--renderer chromium`)

Note: the npm "Dependencies" tab only lists Node package dependencies.
System tools (`pandoc`, `xelatex`, `rsvg-convert`, `python3`, `pandocfilters`) are runtime prerequisites and are installed outside npm.

## macOS Finder Quick Action (Optional)

Install Finder context menu action:

```bash
md2pdf-install-finder-action
```

If it does not appear in Finder right away:

1. Right-click a `.md` file and choose `Quick Actions` -> `Customize...`
2. Enable `Convert Markdown to PDF` under `Extensions` -> `Finder`
3. Restart Finder:

```bash
killall Finder
```

Uninstall Finder context menu action:

```bash
md2pdf-uninstall-finder-action
```

After installation, right-click any `.md` file in Finder:

`Quick Actions` -> `Convert Markdown to PDF`

![Finder Quick Action menu](docs/images/finder-quick-action.png)

## Quick start

Convert Markdown to PDF (output goes beside input by default):

```bash
md2pdf ./notes.md
```

Custom output path:

```bash
md2pdf ./notes.md -o ./build/notes.pdf
```

Keep generated Mermaid assets for debugging:

```bash
md2pdf ./notes.md --keep-mermaid-assets
```

## Mermaid support details

md2pdf uses:

- `MERMAID_LATEX_FORMAT=svg` by default for vector quality in PDF.
- `MERMAID_AUTO_PDF_FALLBACK=true` by default to preserve flowchart/graph node labels when SVG uses `foreignObject`.
- `MERMAID_PDF_FIT=true` by default so Mermaid PDF fallback assets use tight bounds and do not force one-diagram-per-page.
- `LATEX_EMOJI_MODE=auto` by default so XeLaTeX uses Twemoji mapping for detected emoji code points, then falls back to `DejaVu Sans`.
- Pandoc input uses `markdown+lists_without_preceding_blankline` so list blocks after bold lead-ins render correctly.
- Conversion normalizes markdown by:
  - inserting missing blank lines before pipe-table headers,
  - removing trailing two-space hard-break markers on list-item lines (tight list spacing),
  - removing variation selectors (`U+FE0E`/`U+FE0F`) and mapping common symbols (`≥`, `≤`, `↗`) in LaTeX mode.

## Configuration

Config precedence (later overrides earlier):

1. `$HOME/.config/md2pdf/config.env`
2. `<input-markdown-directory>/.md2pdfrc`
3. `--config /path/to/config.env`
4. Environment variables

Create starter config:

```bash
md2pdf --init
```

Create starter config at custom path:

```bash
md2pdf --init ./md2pdf.config.env --force
```

Example config:

```bash
PDF_RENDERER=latex
CHROMIUM_MERMAID_FORMAT=png
PDF_ENGINE=xelatex
LR_MARGIN=0.7in
TB_MARGIN=0.5in
MERMAID_LATEX_FORMAT=svg
LATEX_EMOJI_MODE=auto
LATEX_EMOJI_MONO_FONT=DejaVu Sans
MERMAID_PDF_FIT=true
MERMAID_AUTO_PDF_FALLBACK=true
CLEANUP_MERMAID_ASSETS=true
MERMAID_ASSET_PREFIX=md2pdf-mermaid
```

## CLI reference

```bash
md2pdf --help
md2pdf --version
md2pdf --init
```

Common options:

- `-o, --output <file>`: output PDF path
- `--renderer <latex|chromium>`: choose PDF backend (`latex` default)
- `--config <file>`: load additional config file
- `--keep-mermaid-assets`: keep generated Mermaid temp files
- `--cleanup-mermaid-assets`: remove generated Mermaid temp files (default)

Renderer notes:

- `latex` (default): Pandoc + XeLaTeX output, existing behavior.
- `chromium`: Pandoc renders standalone HTML and Chrome/Chromium prints to PDF.
- `chromium` mode is useful when you need browser-grade emoji/glyph rendering.
- `CHROMIUM_MERMAID_FORMAT=svg|png` controls Mermaid asset format in Chromium mode (`png` default for stability).
- In `latex` mode, `LATEX_EMOJI_MODE=auto` uses `twemojis` mapping, then `LATEX_EMOJI_MONO_FONT`.

## Test samples

- Smoke test: `tests/architecture-smoke-test.md`
- Mermaid sample pack: `tests/samples/mermaid-all-diagram-types.md`

Run:

```bash
md2pdf ./tests/architecture-smoke-test.md
md2pdf ./tests/samples/mermaid-all-diagram-types.md --keep-mermaid-assets
```

## Troubleshooting

- `mmdc not found`: install dependencies and verify `MERMAID_BIN`.
- Pipe-table rows render as plain text: `md2pdf` now auto-normalizes missing blank lines before `|` table headers during conversion.
- Lists after bold labels render as one paragraph: `md2pdf` now parses markdown with `lists_without_preceding_blankline`; no manual blank line is required.
- Bullet lists have extra vertical space: trailing double-space hard breaks at end of list items are trimmed during normalization.
- Flowchart/graph labels missing in PDF: keep `MERMAID_AUTO_PDF_FALLBACK=true`.
- Diagram taking a full page: keep `MERMAID_PDF_FIT=true`.
- PDF engine missing: install `xelatex` or set `PDF_ENGINE`.
- Chromium renderer missing browser binary: install Chrome/Chromium or set `CHROMIUM_BIN` when `PDF_RENDERER=chromium`.
- Chromium Mermaid issues on some machines: keep `CHROMIUM_MERMAID_FORMAT=png` for stable browser printing.
- Emoji glyph warnings (`✅`, `⭐`, 🙂, etc.): keep `LATEX_EMOJI_MODE=auto`, ensure TeX has `twemojis`/`newunicodechar`, and keep a valid `LATEX_EMOJI_MONO_FONT` fallback.
- Need full emoji fidelity with minimal LaTeX tuning: use `--renderer chromium` and keep `CHROMIUM_MERMAID_FORMAT=png` for stable Mermaid printing.
- On macOS, if `xelatex` is still missing after `md2pdf-install-system-deps`:
  - Add TeX to PATH: `echo 'export PATH="/Library/TeX/texbin:$PATH"' >> ~/.zshrc && source ~/.zshrc`
  - If binary is still missing: `sudo /Library/TeX/texbin/tlmgr install collection-xetex`
- On macOS, if Homebrew update times out during `md2pdf-install-system-deps`:
  - Retry without auto-update: `HOMEBREW_NO_AUTO_UPDATE=1 md2pdf-install-system-deps --yes`
  - If a third-party tap keeps failing, inspect taps (`brew tap`) and untap the failing one (example: `brew untap macos-fuse-t/homebrew-cask`)
- On macOS Finder Quick Actions in `Downloads`, first-run privacy prompts can block temp-asset cleanup.
  - If conversion succeeded but cleanup warning appears, output PDF is still usable.
  - Remove leftover assets manually: `rm -rf ~/Downloads/md2pdf-mermaid-*-images`

## Keywords

markdown to pdf, md to pdf, md2pdf, mermaid to pdf, mermaid svg, pandoc markdown pdf, markdown pdf cli, macOS markdown pdf, Linux markdown pdf

## License

MIT License, Copyright (c) 2026 Deepak Kothule
