#!/usr/bin/env sh
set -eu

opencode_local_load_env() {
  root=$1
  env_file=${LOCAL_ENV_FILE:-"$root/local/env.local"}
  if [ -f "$env_file" ]; then
    # shellcheck disable=SC1090
    . "$env_file"
  fi
}

opencode_local_model() {
  if [ -z "${LOCAL_MODEL_ID:-}" ]; then
    printf 'LOCAL_MODEL_ID is required. Set it to the model id shown by your local server.\n' >&2
    exit 2
  fi
  LOCAL_RESOLVED_MODEL_NAME=${LOCAL_MODEL_NAME:-$LOCAL_MODEL_ID}
}

opencode_local_resolve_backend() {
  backend=${LOCAL_BACKEND:-ollama}
  case "$backend" in
    ollama)
      LOCAL_RESOLVED_BASE_URL=${LOCAL_OPENAI_BASE_URL:-http://127.0.0.1:11434/v1}
      LOCAL_RESOLVED_MODEL=$LOCAL_MODEL_ID
      ;;
    llamacpp)
      LOCAL_RESOLVED_BASE_URL=${LOCAL_OPENAI_BASE_URL:-http://127.0.0.1:8080/v1}
      LOCAL_RESOLVED_MODEL=$LOCAL_MODEL_ID
      ;;
    vllm)
      LOCAL_RESOLVED_BASE_URL=${LOCAL_OPENAI_BASE_URL:-http://127.0.0.1:8000/v1}
      LOCAL_RESOLVED_MODEL=$LOCAL_MODEL_ID
      ;;
    mlx-lm | mlxlm)
      LOCAL_RESOLVED_BASE_URL=${LOCAL_OPENAI_BASE_URL:-http://127.0.0.1:8080/v1}
      LOCAL_RESOLVED_MODEL=$LOCAL_MODEL_ID
      ;;
    vmlx)
      LOCAL_RESOLVED_BASE_URL=${LOCAL_OPENAI_BASE_URL:-http://127.0.0.1:8000/v1}
      LOCAL_RESOLVED_MODEL=$LOCAL_MODEL_ID
      ;;
    omlx)
      LOCAL_RESOLVED_BASE_URL=${LOCAL_OPENAI_BASE_URL:-http://127.0.0.1:8001/v1}
      LOCAL_RESOLVED_MODEL=$LOCAL_MODEL_ID
      ;;
    vllm-metal | vllmmetal)
      LOCAL_RESOLVED_BASE_URL=${LOCAL_OPENAI_BASE_URL:-http://127.0.0.1:8000/v1}
      LOCAL_RESOLVED_MODEL=$LOCAL_MODEL_ID
      ;;
    lmstudio)
      LOCAL_RESOLVED_BASE_URL=${LOCAL_OPENAI_BASE_URL:-http://127.0.0.1:1234/v1}
      LOCAL_RESOLVED_MODEL=$LOCAL_MODEL_ID
      ;;
    openai-compatible)
      LOCAL_RESOLVED_BASE_URL=${LOCAL_OPENAI_BASE_URL:-http://127.0.0.1:8000/v1}
      LOCAL_RESOLVED_MODEL=$LOCAL_MODEL_ID
      ;;
    *)
      printf 'Unknown LOCAL_BACKEND: %s\n' "$backend" >&2
      printf 'Supported: ollama, llamacpp, vllm, mlx-lm, vmlx, omlx, vllm-metal, lmstudio, openai-compatible\n' >&2
      exit 2
      ;;
  esac
  LOCAL_RESOLVED_BACKEND=$backend
  LOCAL_RESOLVED_API_KEY=${LOCAL_API_KEY:-local-dev-token}
}

opencode_local_resolve_bin() {
  root=$1

  if [ -n "${LOCAL_OPENCODE_BIN:-}" ]; then
    LOCAL_RESOLVED_BIN=$LOCAL_OPENCODE_BIN
    return 0
  fi

  # Prefer the dist binary for this platform. Running from source instead would
  # pin the channel to "local" (separate session db) and force the project to
  # the repo root, because `bun run --cwd` replaces process.cwd().
  bin_os=$(uname -s 2>/dev/null || printf '')
  bin_arch=$(uname -m 2>/dev/null || printf '')
  case "$bin_os" in
    Darwin) bin_os=darwin ;;
    Linux) bin_os=linux ;;
    *) bin_os= ;;
  esac
  case "$bin_arch" in
    arm64 | aarch64) bin_arch=arm64 ;;
    x86_64 | amd64) bin_arch=x64 ;;
    *) bin_arch= ;;
  esac

  if [ -n "$bin_os" ] && [ -n "$bin_arch" ]; then
    candidate="$root/packages/opencode/dist/opencode-$bin_os-$bin_arch/bin/opencode"
    if [ -x "$candidate" ]; then
      LOCAL_RESOLVED_BIN=$candidate
      return 0
    fi
  fi

  for candidate in "$root"/packages/opencode/dist/opencode-*/bin/opencode; do
    if [ -x "$candidate" ]; then
      LOCAL_RESOLVED_BIN=$candidate
      return 0
    fi
  done

  LOCAL_RESOLVED_BIN=
  return 0
}

opencode_local_json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

opencode_local_print() {
  printf 'model_id=%s\n' "$LOCAL_MODEL_ID"
  printf 'name=%s\n' "$LOCAL_RESOLVED_MODEL_NAME"
  printf 'backend=%s\n' "$LOCAL_RESOLVED_BACKEND"
  printf 'base_url=%s\n' "$LOCAL_RESOLVED_BASE_URL"
  printf 'model=%s\n' "$LOCAL_RESOLVED_MODEL"
  printf 'bin=%s\n' "${LOCAL_RESOLVED_BIN:-<source>}"
}
