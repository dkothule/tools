#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Deepak Kothule
set -euo pipefail

YES=0
OS="$(uname -s)"
PYTHON_BIN=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Install md2pdf runtime dependencies (system packages + pandocfilters).

Options:
  -y, --yes   Skip confirmation prompt and proceed immediately
  -h, --help  Show this help message

Supported platforms:
  - macOS (Homebrew)
  - Debian/Ubuntu Linux (apt)
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -y|--yes)
        YES=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Error: unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done
}

confirm_install() {
  if [[ "$YES" -eq 1 ]]; then
    return
  fi

  if [[ ! -t 0 ]]; then
    echo "Non-interactive shell detected. Re-run with --yes to proceed." >&2
    exit 1
  fi

  echo "This command will install system packages for md2pdf and may prompt for sudo password."
  echo "Detected OS: $OS"
  printf "Continue? [y/N] "
  local response
  local normalized_response
  read -r response
  normalized_response="$(printf '%s' "$response" | tr '[:upper:]' '[:lower:]')"

  case "$normalized_response" in
    y|yes)
      ;;
    *)
      echo "Aborted."
      exit 0
      ;;
  esac
}

has_pandocfilters() {
  local python_bin="$1"
  "$python_bin" - <<'PY' >/dev/null 2>&1
import pandocfilters
PY
}

resolve_python_bin() {
  local candidate
  local -a candidates

  candidates=("/opt/homebrew/bin/python3" "/usr/local/bin/python3")
  if command -v python3 >/dev/null 2>&1; then
    candidates+=("$(command -v python3)")
  fi

  for candidate in "${candidates[@]}"; do
    [[ -n "$candidate" ]] || continue
    [[ -x "$candidate" ]] || continue
    if "$candidate" -c 'import sys; print(sys.executable)' >/dev/null 2>&1; then
      printf '%s' "$candidate"
      return 0
    fi
  done

  return 1
}

ensure_python_bin() {
  if PYTHON_BIN="$(resolve_python_bin)"; then
    echo "Using Python interpreter: $PYTHON_BIN"
    return
  fi

  echo "Error: python3 not found after dependency installation." >&2
  if [[ "$OS" == "Darwin" ]]; then
    echo "Install Python with Homebrew and retry:" >&2
    echo "  brew install python" >&2
  elif [[ "$OS" == "Linux" ]]; then
    echo "Install Python and pip, then retry:" >&2
    echo "  sudo apt-get install -y python3 python3-pip" >&2
  fi
  exit 1
}

ensure_python_pip() {
  local python_bin="$1"
  if "$python_bin" -m pip --version >/dev/null 2>&1; then
    return
  fi

  "$python_bin" -m ensurepip --upgrade >/dev/null 2>&1 || true
  "$python_bin" -m pip --version >/dev/null 2>&1
}

install_python_dependency() {
  local python_bin="$1"

  if ! ensure_python_pip "$python_bin"; then
    echo "Error: pip is not available for $python_bin." >&2
    echo "Install pip and retry. Example:" >&2
    echo "  $python_bin -m ensurepip --upgrade" >&2
    exit 1
  fi

  if has_pandocfilters "$python_bin"; then
    echo "Python dependency already installed: pandocfilters"
    return
  fi

  echo "Installing Python dependency: pandocfilters"
  if "$python_bin" -m pip install --user pandocfilters; then
    return
  fi

  if "$python_bin" -m pip install pandocfilters --break-system-packages; then
    return
  fi

  echo "Failed to install pandocfilters automatically." >&2
  echo "Please install manually with one of:" >&2
  echo "  $python_bin -m pip install --user pandocfilters" >&2
  echo "  $python_bin -m pip install pandocfilters --break-system-packages" >&2
  exit 1
}

ensure_tex_path_macos() {
  local tex_bin="/Library/TeX/texbin"
  if [[ ! -d "$tex_bin" ]]; then
    return
  fi

  case ":$PATH:" in
    *":$tex_bin:"*)
      ;;
    *)
      export PATH="$tex_bin:$PATH"
      ;;
  esac
}

ensure_xelatex_macos() {
  ensure_tex_path_macos
  if command -v xelatex >/dev/null 2>&1; then
    return
  fi

  echo "Installing BasicTeX for xelatex..."
  brew install --cask basictex
  ensure_tex_path_macos

  if command -v xelatex >/dev/null 2>&1; then
    return
  fi

  local tlmgr_bin="/Library/TeX/texbin/tlmgr"
  if [[ -x "$tlmgr_bin" ]]; then
    if [[ -t 0 ]]; then
      echo "BasicTeX installed but xelatex is still missing. Installing TeX collection-xetex..."
      sudo "$tlmgr_bin" install collection-xetex || true
      ensure_tex_path_macos
    else
      echo "BasicTeX installed but xelatex is still missing."
      echo "Run this command to install it:"
      echo "  sudo $tlmgr_bin install collection-xetex"
    fi
  fi

  if command -v xelatex >/dev/null 2>&1; then
    return
  fi

  echo "Error: xelatex is still not available." >&2
  echo "If /Library/TeX/texbin/xelatex exists, add TeX to PATH and restart your shell:" >&2
  echo "  echo 'export PATH=\"/Library/TeX/texbin:\$PATH\"' >> ~/.zshrc" >&2
  echo "  source ~/.zshrc" >&2
  echo "If xelatex binary is missing, install it with:" >&2
  echo "  sudo /Library/TeX/texbin/tlmgr install collection-xetex" >&2
  exit 1
}

install_macos() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required on macOS. Install from https://brew.sh and retry."
    exit 1
  fi

  brew update
  brew install pandoc librsvg python

  if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    brew install node
  fi

  ensure_xelatex_macos
}

install_debian_ubuntu() {
  sudo apt-get update
  sudo apt-get install -y \
    pandoc \
    librsvg2-bin \
    python3 \
    python3-venv \
    python3-pip \
    python3-pandocfilters \
    texlive-xetex

  if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    sudo apt-get install -y nodejs npm
  fi
}

parse_args "$@"
confirm_install

if [[ "$OS" == "Darwin" ]]; then
  install_macos
elif [[ "$OS" == "Linux" ]]; then
  if [[ -f /etc/debian_version ]]; then
    install_debian_ubuntu
  else
    echo "Unsupported Linux distro by this script."
    echo "Please install: pandoc, xelatex, librsvg (rsvg-convert), node/npm, python3+venv."
    exit 1
  fi
else
  echo "Unsupported OS: $OS"
  exit 1
fi

ensure_python_bin
install_python_dependency "$PYTHON_BIN"

echo "Runtime dependencies installed."
