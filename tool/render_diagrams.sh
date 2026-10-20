#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
chrome_bin=${CHROME_BIN:-}
if [ -z "$chrome_bin" ]; then
  for candidate in google-chrome chromium chromium-browser; do
    if command -v "$candidate" >/dev/null 2>&1; then
      chrome_bin=$(command -v "$candidate")
      break
    fi
  done
fi
if [ -z "$chrome_bin" ] && [ -x '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' ]; then
  chrome_bin='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
fi
if [ -z "$chrome_bin" ]; then
  echo 'Chrome or Chromium is required; set CHROME_BIN to its executable.' >&2
  exit 1
fi

render_tmp=$(mktemp -d "${TMPDIR:-/tmp}/domain-error-diagrams.XXXXXX")
chrome_pid=
cleanup() {
  if [ -n "$chrome_pid" ] && kill -0 "$chrome_pid" 2>/dev/null; then
    kill -TERM "$chrome_pid" 2>/dev/null || true
    sleep 1
    kill -KILL "$chrome_pid" 2>/dev/null || true
    wait "$chrome_pid" 2>/dev/null || true
  fi
  rm -rf "$render_tmp"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
for diagram in cover overview flow fold; do
  height=900
  if [ "$diagram" = cover ]; then
    height=640
  fi
  "$chrome_bin" --headless=new --disable-gpu \
    --disable-background-networking --disable-component-update --disable-sync \
    --hide-scrollbars --force-device-scale-factor=1 --window-size="1600,$height" \
    --user-data-dir="$render_tmp/$diagram" \
    --screenshot="$render_tmp/$diagram.png" \
    "file://$project_dir/assets/$diagram.html" >"$render_tmp/$diagram.log" 2>&1 &
  chrome_pid=$!
  seconds=0
  while kill -0 "$chrome_pid" 2>/dev/null; do
    if [ -s "$render_tmp/$diagram.png" ] && grep -q 'bytes written to file' "$render_tmp/$diagram.log"; then
      break
    fi
    if [ "$seconds" -ge 30 ]; then
      echo "Screenshot timed out: $diagram" >&2
      cat "$render_tmp/$diagram.log" >&2
      exit 1
    fi
    sleep 1
    seconds=$((seconds + 1))
  done
  # Some Chrome versions keep running after writing a complete screenshot.
  if kill -0 "$chrome_pid" 2>/dev/null; then
    kill -TERM "$chrome_pid" 2>/dev/null || true
    sleep 1
    kill -KILL "$chrome_pid" 2>/dev/null || true
  fi
  wait "$chrome_pid" 2>/dev/null || true
  chrome_pid=
  if [ ! -s "$render_tmp/$diagram.png" ]; then
    echo "Missing screenshot: $diagram" >&2
    exit 1
  fi
  cp "$render_tmp/$diagram.png" "$project_dir/assets/$diagram.png"
  echo "Rendered assets/$diagram.png"
done
