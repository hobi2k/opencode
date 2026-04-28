# opencode 로컬 모델 실행 가이드

이 문서는 `opencode` 전용입니다. `claw-code` 설정은 `claw-code` 저장소의 `README-local.md`에서 따로 관리합니다.

목표는 upstream `README.md`와 TypeScript 본체를 건드리지 않고, Ollama, llama.cpp, vLLM, LM Studio, 직접 만든 OpenAI-compatible 서버에 붙여서 `opencode`를 CLI처럼 실행하는 것입니다.

## 원칙

- `opencode` 소스 코드를 수정하지 않습니다.
- 기존 `README.md`를 수정하지 않습니다.
- 로컬 전용 파일은 `local/`, `configs/`, `scripts/opencode-local`에만 둡니다.
- 개인 설정은 `local/env.local`에 두고 git에 넣지 않습니다.
- 모델 파일은 `models/` 아래에 둘 수 있지만 git에 넣지 않습니다.
- 전역 `opencode.json`을 덮어쓰지 않습니다.

## 추가 파일

- `local/env.example`: 개인 설정 예시입니다.
- `configs/opencode-local-models.json`: opencode 전용 로컬 모델 프로필입니다.
- `configs/opencode.local.jsonc`: opencode provider 설정 예시입니다.
- `scripts/opencode-local-common.sh`: macOS/Linux/WSL용 공통 profile 해석 코드입니다.
- `scripts/opencode-local`: macOS/Linux/WSL에서 쓰는 opencode 로컬 실행 CLI입니다.
- `scripts/opencode-local.ps1`: Windows PowerShell에서 쓰는 opencode 로컬 실행 CLI입니다.

## 중요한 차이

`opencode`는 모델을 `provider/model` 형식으로 선택합니다. 그래서 모델 id 자체에 `/`가 들어가면 selector가 깨질 수 있습니다.

예를 들어 Hugging Face 모델 id인 `Qwen/Qwen2.5-Coder-7B-Instruct`나 `google/gemma-4-E4B-it`를 그대로 selector에 넣지 않습니다. 대신 backend에서 slash 없는 alias를 노출시키고, opencode에는 아래처럼 전달합니다.

```text
local/qwen-coder-7b
local/gemma-4-e4b
```

Ollama 모델 tag인 `qwen2.5-coder:7b`는 `/`가 없으므로 그대로 사용할 수 있습니다.

## 지원 모델

| Profile | opencode 모델 id | 설명 |
| --- | --- | --- |
| `gemma-4-e4b` | `gemma-4-e4b` | Gemma 4 E4B instruction 모델 alias |
| `gemma-4-e2b` | `gemma-4-e2b` | 더 작은 Gemma 4 alias |
| `qwen-coder-7b` | Ollama는 `qwen2.5-coder:7b`, 그 외는 `qwen-coder-7b` | 로컬 코딩 기본 추천 |
| `qwen-coder-3b` | Ollama는 `qwen2.5-coder:3b`, 그 외는 `qwen-coder-3b` | 노트북용 빠른 코딩 |
| `qwen-coder-1.5b` | Ollama는 `qwen2.5-coder:1.5b`, 그 외는 `qwen-coder-1.5b` | 가벼운 smoke test |

## 실행 방식

`scripts/opencode-local`은 실행 시 `OPENCODE_CONFIG_CONTENT`를 만들어 현재 프로세스에만 주입합니다. 그래서 전역 `opencode.json`이나 repo root의 `opencode.json`을 만들 필요가 없습니다.

wrapper는 기본적으로 이 순서로 opencode를 실행합니다.

1. `LOCAL_OPENCODE_BIN`이 있으면 그 binary를 실행합니다.
2. 현재 저장소의 source CLI가 있고 `bun`이 있으면 `bun run --cwd packages/opencode --conditions=browser ./src/index.ts`를 실행합니다.
3. 아니면 PATH의 `opencode`를 실행합니다.

## Ollama로 실행

모델을 받습니다.

```bash
ollama pull qwen2.5-coder:7b
```

설정 확인:

```bash
LOCAL_MODEL_PROFILE=qwen-coder-7b LOCAL_BACKEND=ollama ./scripts/opencode-local --print
```

대화형 실행:

```bash
LOCAL_MODEL_PROFILE=qwen-coder-7b LOCAL_BACKEND=ollama \
  ./scripts/opencode-local
```

명령 인자를 그대로 넘기고 싶으면 뒤에 붙이면 됩니다.

```bash
LOCAL_MODEL_PROFILE=qwen-coder-7b LOCAL_BACKEND=ollama \
  ./scripts/opencode-local --help
```

## llama.cpp로 실행

`llama-server`를 OpenAI-compatible server로 띄웁니다. opencode selector가 안전하게 동작하도록 `--alias`를 profile 이름과 맞춥니다.

```bash
llama-server \
  -m models/qwen2.5-coder-7b-instruct-q4_k_m.gguf \
  --alias qwen-coder-7b \
  --host 127.0.0.1 \
  --port 8080
```

실행:

```bash
LOCAL_MODEL_PROFILE=qwen-coder-7b LOCAL_BACKEND=llamacpp \
  ./scripts/opencode-local
```

alias가 다르면 `LOCAL_MODEL_ID`로 덮어씁니다.

```bash
LOCAL_MODEL_PROFILE=qwen-coder-7b \
LOCAL_BACKEND=llamacpp \
LOCAL_MODEL_ID=my-qwen-alias \
  ./scripts/opencode-local
```

## vLLM으로 실행

vLLM은 실제 HF 모델 id와 opencode용 alias를 분리하는 방식이 안전합니다.

```bash
python -m vllm.entrypoints.openai.api_server \
  --model Qwen/Qwen2.5-Coder-7B-Instruct \
  --served-model-name qwen-coder-7b \
  --host 127.0.0.1 \
  --port 8000
```

실행:

```bash
LOCAL_MODEL_PROFILE=qwen-coder-7b LOCAL_BACKEND=vllm \
  ./scripts/opencode-local
```

Gemma 4 E2B:

```bash
python -m vllm.entrypoints.openai.api_server \
  --model google/gemma-4-E2B-it \
  --served-model-name gemma-4-e2b \
  --host 127.0.0.1 \
  --port 8000
```

```bash
LOCAL_MODEL_PROFILE=gemma-4-e2b LOCAL_BACKEND=vllm \
  ./scripts/opencode-local
```

Gemma 4 E4B:

```bash
python -m vllm.entrypoints.openai.api_server \
  --model google/gemma-4-E4B-it \
  --served-model-name gemma-4-e4b \
  --host 127.0.0.1 \
  --port 8000
```

```bash
LOCAL_MODEL_PROFILE=gemma-4-e4b LOCAL_BACKEND=vllm \
  ./scripts/opencode-local
```

## LM Studio

LM Studio에서 OpenAI-compatible server를 켜고, 모델 id를 slash 없는 alias로 맞춥니다.

```bash
LOCAL_MODEL_PROFILE=qwen-coder-7b LOCAL_BACKEND=lmstudio \
  ./scripts/opencode-local
```

LM Studio 기본 URL은 `http://127.0.0.1:1234/v1`입니다.

## 직접 만든 OpenAI-compatible 서버

`/v1/chat/completions`를 제공하는 서버라면 다음처럼 붙입니다.

```bash
LOCAL_MODEL_PROFILE=gemma-4-e4b \
LOCAL_BACKEND=openai-compatible \
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8000/v1 \
LOCAL_MODEL_ID=gemma-4-e4b \
  ./scripts/opencode-local
```

`LOCAL_MODEL_ID`는 서버가 `/v1/chat/completions`에서 받는 모델 id와 같아야 합니다.

## 개인 설정 고정

매번 환경변수를 쓰기 싫으면:

```bash
cp local/env.example local/env.local
```

예시:

```env
LOCAL_MODEL_PROFILE=qwen-coder-3b
LOCAL_BACKEND=ollama
LOCAL_API_KEY=local-dev-token
LOCAL_OPENCODE_PROVIDER_ID=local
```

이후에는:

```bash
./scripts/opencode-local
```

## Windows PowerShell

PowerShell에서는:

```powershell
$env:LOCAL_MODEL_PROFILE = "qwen-coder-7b"
$env:LOCAL_BACKEND = "ollama"
.\scripts\opencode-local.ps1 -Print
.\scripts\opencode-local.ps1
```

vLLM alias를 쓰는 경우:

```powershell
$env:LOCAL_MODEL_PROFILE = "gemma-4-e4b"
$env:LOCAL_BACKEND = "vllm"
.\scripts\opencode-local.ps1
```

## CLI처럼 쓰기

repo 안에서는:

```bash
./scripts/opencode-local
```

전역 명령처럼 쓰고 싶으면 shell alias를 둡니다.

```bash
alias opencode-local="/path/to/opencode/scripts/opencode-local"
```

그러면 어디서든:

```bash
opencode-local
```

## 확인 명령

기본 설정 확인:

```bash
./scripts/opencode-local --print
```

Qwen 1.5B Ollama 확인:

```bash
LOCAL_MODEL_PROFILE=qwen-coder-1.5b LOCAL_BACKEND=ollama ./scripts/opencode-local --print
```

Gemma 4 E4B vLLM alias 확인:

```bash
LOCAL_MODEL_PROFILE=gemma-4-e4b LOCAL_BACKEND=vllm ./scripts/opencode-local --print
```

출력의 핵심은 `opencode_selector`입니다. 예를 들어 `local/gemma-4-e4b`이면 provider id는 `local`, model id는 `gemma-4-e4b`입니다.
