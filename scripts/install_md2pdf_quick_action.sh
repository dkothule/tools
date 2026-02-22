#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Deepak Kothule
set -euo pipefail

resolve_script_dir() {
  local source="${BASH_SOURCE[0]}"
  while [[ -L "$source" ]]; do
    local dir
    dir="$(cd -P "$(dirname "$source")" && pwd)"
    source="$(readlink "$source")"
    if [[ "$source" != /* ]]; then
      source="$dir/$source"
    fi
  done
  cd -P "$(dirname "$source")" && pwd
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: Finder Quick Action installer is only supported on macOS." >&2
  exit 1
fi

WORKFLOW_NAME="${WORKFLOW_NAME:-Convert Markdown to PDF}"
WORKFLOW_DIR="$HOME/Library/Services/${WORKFLOW_NAME}.workflow"
CONTENTS_DIR="$WORKFLOW_DIR/Contents"
SCRIPT_DIR="$(resolve_script_dir)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MD2PDF_SCRIPT=""
if [[ -x "$PROJECT_ROOT/bin/md2pdf" ]]; then
  MD2PDF_SCRIPT="$PROJECT_ROOT/bin/md2pdf"
elif command -v md2pdf >/dev/null 2>&1; then
  MD2PDF_SCRIPT="$(command -v md2pdf)"
fi

if [[ -z "$MD2PDF_SCRIPT" ]]; then
  cat >&2 <<'EOF'
Error: could not find md2pdf executable.
Install from this repo first:
  ./setup-local-deps.sh
Or install globally:
  npm i -g @dkothule/md2pdf
EOF
  exit 1
fi

ACTION_UUID="$(uuidgen)"
INPUT_UUID="$(uuidgen)"
OUTPUT_UUID="$(uuidgen)"

mkdir -p "$CONTENTS_DIR"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSServices</key>
  <array>
    <dict>
      <key>NSBackgroundColorName</key>
      <string>background</string>
      <key>NSIconName</key>
      <string>NSActionTemplate</string>
      <key>NSMenuItem</key>
      <dict>
        <key>default</key>
        <string>Convert Markdown to PDF</string>
      </dict>
      <key>NSMessage</key>
      <string>runWorkflowAsService</string>
      <key>NSRequiredContext</key>
      <dict>
        <key>NSApplicationIdentifier</key>
        <string>com.apple.finder</string>
      </dict>
      <key>NSSendFileTypes</key>
      <array>
        <string>net.daringfireball.markdown</string>
        <string>md</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
PLIST

cat > "$CONTENTS_DIR/document.wflow" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>AMApplicationBuild</key>
  <string>533</string>
  <key>AMApplicationVersion</key>
  <string>2.10</string>
  <key>AMDocumentVersion</key>
  <string>2</string>
  <key>actions</key>
  <array>
    <dict>
      <key>action</key>
      <dict>
        <key>ActionBundlePath</key>
        <string>/System/Library/Automator/Run Shell Script.action</string>
        <key>ActionName</key>
        <string>Run Shell Script</string>
        <key>ActionParameters</key>
        <dict>
          <key>CheckedForUserDefaultShell</key>
          <true/>
          <key>COMMAND_STRING</key>
          <string>export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/TeX/texbin:$HOME/.npm-global/bin"
MD2PDF_SCRIPT="$MD2PDF_SCRIPT"
if [[ ! -x "\$MD2PDF_SCRIPT" ]] &amp;&amp; [[ -z "\$(command -v md2pdf 2&gt;/dev/null)" ]]; then
  print -u2 -- "Error: md2pdf is not in PATH: \$PATH"
  exit 127
fi

unset PYTHONNOUSERSITE
pick_python_with_pandocfilters() {
  local candidate
  local -a candidates
  candidates=("/opt/homebrew/bin/python3" "/usr/local/bin/python3")
  if [[ -n "\$(command -v python3 2&gt;/dev/null)" ]]; then
    candidates+=("\$(command -v python3)")
  fi

  for candidate in "\${candidates[@]}"; do
    [[ -n "\$candidate" ]] || continue
    [[ -x "\$candidate" ]] || continue
    if "\$candidate" - &lt;&lt;'PY' &gt;/dev/null 2&gt;&amp;1
import pandocfilters
PY
    then
      print -r -- "\$candidate"
      return 0
    fi
  done
  return 1
}

PYTHON_BIN="\$(pick_python_with_pandocfilters || true)"
if [[ -z "\$PYTHON_BIN" ]]; then
  print -u2 -- "Error: Missing Python dependency: pandocfilters."
  print -u2 -- "Install with:"
  if [[ -x /opt/homebrew/bin/python3 ]]; then
    print -u2 -- "  /opt/homebrew/bin/python3 -m pip install --user pandocfilters"
  fi
  print -u2 -- "  python3 -m pip install --user pandocfilters"
  exit 1
fi
export PYTHON="\$PYTHON_BIN"

for f in "\$@"; do
  case "\$f" in
    *.md|*.MD) ;;
    *) continue ;;
  esac
  if [[ -x "\$MD2PDF_SCRIPT" ]]; then
    "\$MD2PDF_SCRIPT" "\$f"
  else
    md2pdf "\$f"
  fi
done
</string>
          <key>inputMethod</key>
          <integer>1</integer>
          <key>shell</key>
          <string>/bin/zsh</string>
          <key>source</key>
          <string></string>
        </dict>
        <key>AMAccepts</key>
        <dict>
          <key>Container</key>
          <string>List</string>
          <key>Optional</key>
          <true/>
          <key>Types</key>
          <array>
            <string>com.apple.cocoa.string</string>
          </array>
        </dict>
        <key>AMActionVersion</key>
        <string>2.0.3</string>
        <key>AMApplication</key>
        <array>
          <string>Automator</string>
        </array>
        <key>AMParameterProperties</key>
        <dict>
          <key>CheckedForUserDefaultShell</key>
          <dict/>
          <key>COMMAND_STRING</key>
          <dict/>
          <key>inputMethod</key>
          <dict/>
          <key>shell</key>
          <dict/>
          <key>source</key>
          <dict/>
        </dict>
        <key>AMProvides</key>
        <dict>
          <key>Container</key>
          <string>List</string>
          <key>Types</key>
          <array>
            <string>com.apple.cocoa.string</string>
          </array>
        </dict>
        <key>BundleIdentifier</key>
        <string>com.apple.RunShellScript</string>
        <key>CanShowSelectedItemsWhenRun</key>
        <false/>
        <key>CanShowWhenRun</key>
        <true/>
        <key>Category</key>
        <array>
          <string>AMCategoryUtilities</string>
        </array>
        <key>CFBundleVersion</key>
        <string>2.0.3</string>
        <key>Class Name</key>
        <string>RunShellScriptAction</string>
        <key>InputUUID</key>
        <string>$INPUT_UUID</string>
        <key>OutputUUID</key>
        <string>$OUTPUT_UUID</string>
        <key>UUID</key>
        <string>$ACTION_UUID</string>
        <key>isViewVisible</key>
        <integer>1</integer>
      </dict>
      <key>isViewVisible</key>
      <integer>1</integer>
    </dict>
  </array>
  <key>connectors</key>
  <dict/>
  <key>workflowMetaData</key>
  <dict>
    <key>applicationBundleID</key>
    <string>com.apple.finder</string>
    <key>applicationBundleIDsByPath</key>
    <dict>
      <key>/System/Library/CoreServices/Finder.app</key>
      <string>com.apple.finder</string>
    </dict>
    <key>applicationPath</key>
    <string>/System/Library/CoreServices/Finder.app</string>
    <key>applicationPaths</key>
    <array>
      <string>/System/Library/CoreServices/Finder.app</string>
    </array>
    <key>inputTypeIdentifier</key>
    <string>com.apple.Automator.fileSystemObject</string>
    <key>outputTypeIdentifier</key>
    <string>com.apple.Automator.nothing</string>
    <key>presentationMode</key>
    <integer>15</integer>
    <key>processesInput</key>
    <false/>
    <key>serviceApplicationBundleID</key>
    <string>com.apple.finder</string>
    <key>serviceApplicationPath</key>
    <string>/System/Library/CoreServices/Finder.app</string>
    <key>serviceInputTypeIdentifier</key>
    <string>com.apple.Automator.fileSystemObject</string>
    <key>serviceOutputTypeIdentifier</key>
    <string>com.apple.Automator.nothing</string>
    <key>serviceProcessesInput</key>
    <false/>
    <key>systemImageName</key>
    <string>NSActionTemplate</string>
    <key>useAutomaticInputType</key>
    <false/>
    <key>workflowTypeIdentifier</key>
    <string>com.apple.Automator.servicesMenu</string>
  </dict>
</dict>
</plist>
PLIST

plutil -lint "$CONTENTS_DIR/Info.plist" >/dev/null
plutil -lint "$CONTENTS_DIR/document.wflow" >/dev/null

echo "Installed Quick Action: $WORKFLOW_NAME"
echo "Location: $WORKFLOW_DIR"
echo "Using md2pdf executable: $MD2PDF_SCRIPT"
echo
echo "If it does not appear in Finder context menu:"
echo "  1) Right-click a .md file -> Quick Actions -> Customize..."
echo "  2) Enable '$WORKFLOW_NAME' in Extensions -> Finder"
echo "  3) Restart Finder"
echo "  killall Finder"
