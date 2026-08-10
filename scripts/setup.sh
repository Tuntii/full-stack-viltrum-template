#!/usr/bin/env bash
# Ensure `import viltrum` resolves via ~/.vmodules/viltrum.
set -euo pipefail

VMOD="${HOME}/.vmodules"
mkdir -p "${VMOD}"

if [[ -n "${VILTRUM_PATH:-}" ]]; then
  ROOT="$(cd "${VILTRUM_PATH}" && pwd)"
  ln -sfn "${ROOT}" "${VMOD}/viltrum"
  echo "linked: ${VMOD}/viltrum -> ${ROOT}"
elif [[ -e "${VMOD}/viltrum/v.mod" ]] || [[ -e "${VMOD}/viltrum/viltrum.v" ]]; then
  echo "using existing: ${VMOD}/viltrum"
else
  CLONE_DIR="${VMOD}/_src/viltrum"
  mkdir -p "${VMOD}/_src"
  if [[ -d "${CLONE_DIR}/.git" ]]; then
    echo "updating ${CLONE_DIR}"
    git -C "${CLONE_DIR}" pull --ff-only || true
  else
    echo "cloning Tuntii/viltrum -> ${CLONE_DIR}"
    git clone --depth 1 https://github.com/Tuntii/viltrum.git "${CLONE_DIR}"
  fi
  ROOT="$(cd "${CLONE_DIR}" && pwd)"
  ln -sfn "${ROOT}" "${VMOD}/viltrum"
  echo "linked: ${VMOD}/viltrum -> ${ROOT}"
fi

if command -v v >/dev/null 2>&1; then
  echo "v: $(v version 2>/dev/null | head -1)"
  echo "try: v run ."
else
  echo "v not on PATH; install from https://github.com/vlang/v"
fi
