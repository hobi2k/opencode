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
      printf 'Supported: ollama, llamacpp, vllm, mlx-lm, vmlx, vllm-metal, lmstudio, openai-compatible\n' >&2
      exit 2
      ;;
  esac
  LOCAL_RESOLVED_BACKEND=$backend
  LOCAL_RESOLVED_API_KEY=${LOCAL_API_KEY:-local-dev-token}
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
}
