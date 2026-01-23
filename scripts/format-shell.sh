#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

if ! command -v shfmt >/dev/null 2>&1; then
  echo "shfmt not found. Install with: go install mvdan.cc/sh/v3/cmd/shfmt@latest" >&2
  exit 1
fi

files=()
if command -v rg >/dev/null 2>&1; then
  mapfile -t files < <(rg --files -g '*.sh' bootstrap scripts)
else
  mapfile -t files < <(find bootstrap scripts -type f -name '*.sh')
fi

if [ "${#files[@]}" -eq 0 ]; then
  echo "No shell scripts found."
  exit 0
fi

# 1) Format
shfmt -w -i 2 -ci "${files[@]}"

# 2) Normalize EOL to LF (convert CRLF -> LF, also lone CR -> LF)
#    -pi: in-place
#    -e : program
perl -pi -e 's/\r\n?/\n/g' "${files[@]}"
