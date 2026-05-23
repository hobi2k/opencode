# opencode 로컬 모델 실행 가이드

이 문서는 `opencode` 전용입니다. `claw-code` 설정은 `claw-code` 저장소의 `README-local.md`에서 따로 관리합니다.

목표는 upstream `README.md`와 TypeScript 본체를 건드리지 않고, Ollama, llama.cpp, vLLM, LM Studio, `mlx-lm`, vMLX, vLLM Metal, 직접 만든 OpenAI-compatible 서버에 붙여서 `opencode`를 CLI처럼 실행하는 것입니다.

## 원칙

- `opencode` 소스 코드를 수정하지 않습니다.
- 기존 `README.md`를 수정하지 않습니다.
- 로컬 전용 파일은 `local/`, `configs/`, `scripts/opencode-local*`에만 둡니다.
- 개인 설정은 `local/env.local`에 두고 git에 넣지 않습니다.
- 모델 파일은 `models/` 아래에 둘 수 있지만 git에 넣지 않습니다.
- 전역 `opencode.json`을 덮어쓰지 않습니다.

## 추가 파일

- `local/env.example`: 개인 설정 예시입니다.
- `configs/opencode-local-models.json`: opencode 전용 로컬 모델 프로필입니다.
- `configs/opencode.local.jsonc`: opencode provider 설정 예시입니다.
- `scripts/opencode-local-common.sh`: macOS/Linux/WSL용 공통 profile 해석 코드입니다.
- `scripts/opencode-local`: macOS/Linux/WSL에서 쓰는 opencode 로컬 실행 CLI입니다.
- `scripts/opencode-mlx`: macOS Apple Silicon에서 `mlx-lm`을 기본 backend로 쓰는 짧은 실행 wrapper입니다.
- `scripts/mlx-openai-alias-proxy.py`: `mlx_lm.server`의 slash 포함 모델 id를 opencode용 slash-free alias로 바꿔주는 작은 프록시입니다.
- `scripts/opencode-local.ps1`: Windows PowerShell에서 쓰는 opencode 로컬 실행 CLI입니다.

## 처음부터 실행하는 추천 절차

MacBook Apple Silicon에서 LM Studio/Ollama 없이 자립형으로 시작하려면 이 순서가 가장 단순합니다.

1. 이 repo 의존성을 준비합니다.

```bash
cd /Users/hsahn/Desktop/opencode
bun install
```

2. `mlx-lm`용 Python 가상환경을 만듭니다.

```bash
python3 -m venv ~/.venvs/mlx-lm
source ~/.venvs/mlx-lm/bin/activate
pip install -U pip mlx-lm
```

3. 터미널 1에서 MLX 모델 서버를 띄웁니다.

```bash
cd /Users/hsahn/Desktop/opencode
source ~/.venvs/mlx-lm/bin/activate

mlx_lm.server \
  --model mlx-community/Qwen2.5-Coder-32B-Instruct-4bit \
  --host 127.0.0.1 \
  --port 8080
```

4. 터미널 2에서 `mlx_lm.server`가 응답하는지 확인합니다.

```bash
curl http://127.0.0.1:8080/v1/models
```

5. 터미널 2에서 opencode용 alias proxy를 띄웁니다.

```bash
cd /Users/hsahn/Desktop/opencode

MLX_PROXY_MODEL_ALIAS=qwen-coder-32b \
MLX_PROXY_UPSTREAM_MODEL=mlx-community/Qwen2.5-Coder-32B-Instruct-4bit \
MLX_PROXY_UPSTREAM=http://127.0.0.1:8080 \
MLX_PROXY_PORT=8090 \
  ./scripts/mlx-openai-alias-proxy.py
```

6. 터미널 3에서 alias proxy가 응답하는지 확인합니다.

```bash
curl http://127.0.0.1:8090/v1/models
```

응답에 아래처럼 `qwen-coder-32b`가 보이면 됩니다.

```json
{
  "object": "list",
  "data": [
    {
      "id": "qwen-coder-32b",
      "object": "model",
      "created": 0,
      "owned_by": "mlx-lm"
    }
  ]
}
```

7. 터미널 3에서 opencode 설정이 어떻게 들어가는지 먼저 출력합니다.

```bash
cd /Users/hsahn/Desktop/opencode

LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8090/v1 \
LOCAL_MODEL_ID=qwen-coder-32b \
  ./scripts/opencode-mlx --print
```

8. 출력이 정상이라면 opencode를 실행합니다.

```bash
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8090/v1 \
LOCAL_MODEL_ID=qwen-coder-32b \
  ./scripts/opencode-mlx /path/to/your/project
```

현재 폴더를 대상으로 실행하려면 마지막 인자를 `.`로 둡니다.

```bash
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8090/v1 \
LOCAL_MODEL_ID=qwen-coder-32b \
  ./scripts/opencode-mlx .
```

9. 종료할 때는 각 터미널에서 `Ctrl+C`를 누릅니다.

종료 순서는 보통 opencode, alias proxy, `mlx_lm.server` 순서면 됩니다.

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

## Backend 빠른 선택

| Backend | 기본 URL | 성격 |
| --- | --- | --- |
| `ollama` | `http://127.0.0.1:11434/v1` | 가장 쉬운 터미널형 모델 서버 |
| `llamacpp` | `http://127.0.0.1:8080/v1` | GGUF + Metal, 세밀한 튜닝용 |
| `vllm` | `http://127.0.0.1:8000/v1` | Linux/NVIDIA 중심, Mac에서는 실험적 |
| `mlx-lm` | `http://127.0.0.1:8080/v1` | Apple 공식 MLX 계열의 가장 직접적인 Python 서버 |
| `vmlx` | `http://127.0.0.1:8000/v1` | MLX 기반 OpenAI-compatible 서버 앱/런타임 |
| `vllm-metal` | `http://127.0.0.1:8000/v1` | vLLM 인터페이스 + Apple Silicon Metal/MLX 계열 실험 backend |
| `lmstudio` | `http://127.0.0.1:1234/v1` | GUI 모델 관리 + MLX/GGUF |
| `openai-compatible` | `http://127.0.0.1:8000/v1` | 직접 만든 서버나 기타 호환 서버 |

Apple Silicon에서 완전 자립형에 가깝게 쓰려면 `mlx-lm`부터 시작합니다. GUI 없이 Python + MLX만으로 서버를 띄울 수 있고, opencode 쪽에는 OpenAI-compatible endpoint만 넘기면 됩니다.

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

## mlx-lm으로 실행

`mlx-lm`은 LM Studio나 Ollama 없이 MLX 모델을 직접 띄우는 가장 단순한 경로입니다. 서버는 OpenAI Chat Completions와 비슷한 HTTP API를 제공합니다.

### 준비물

- Apple Silicon Mac
- Python 3.10 이상 권장
- `mlx-lm`이 지원하는 MLX 모델
- opencode repo 의존성 설치용 Bun

repo 준비:

```bash
cd /Users/hsahn/Desktop/opencode
bun install
```

가상환경을 만들고 설치합니다.

```bash
python3 -m venv ~/.venvs/mlx-lm
source ~/.venvs/mlx-lm/bin/activate
pip install -U pip mlx-lm
```

### 모델 서버 실행

모델 서버를 띄웁니다.

```bash
mlx_lm.server \
  --model mlx-community/Qwen2.5-Coder-32B-Instruct-4bit \
  --host 127.0.0.1 \
  --port 8080
```

서버 확인:

```bash
curl http://127.0.0.1:8080/v1/models
```

응답의 `id`가 `mlx-community/Qwen2.5-Coder-32B-Instruct-4bit`처럼 `/`를 포함하면, 아래 alias proxy 경로를 추천합니다. 응답의 `id`가 이미 `qwen-coder-32b`처럼 slash-free라면 proxy 없이 바로 붙여도 됩니다.

### proxy 없이 바로 붙이기

다른 터미널에서 opencode를 실행합니다.

```bash
cd /Users/hsahn/Desktop/opencode

LOCAL_BACKEND=mlx-lm \
LOCAL_MODEL_PROFILE=qwen-coder-7b \
LOCAL_MODEL_ID=mlx-community/Qwen2.5-Coder-32B-Instruct-4bit \
  ./scripts/opencode-local
```

짧은 wrapper를 써도 됩니다. `scripts/opencode-mlx`는 기본 backend를 `mlx-lm`으로 잡아둔 alias입니다.

```bash
LOCAL_MODEL_ID=mlx-community/Qwen2.5-Coder-32B-Instruct-4bit \
  ./scripts/opencode-mlx
```

`LOCAL_MODEL_ID`는 `mlx_lm.server`가 받는 모델 id와 맞춥니다. Hugging Face repo id처럼 `/`가 들어간 값을 서버가 요구하면 그대로 넣어도 됩니다. wrapper는 provider id와 model id를 JSON config로 주입하므로, 문제가 생길 때는 먼저 아래로 실제 selector를 확인합니다.

```bash
LOCAL_BACKEND=mlx-lm \
LOCAL_MODEL_ID=mlx-community/Qwen2.5-Coder-32B-Instruct-4bit \
  ./scripts/opencode-local --print
```

### alias proxy로 안전하게 붙이기

만약 opencode 모델 선택에서 `/`가 문제를 만들면, 서버가 slash 없는 alias를 노출하도록 별도 wrapper 서버를 두거나 `LOCAL_MODEL_ID=qwen-coder-32b` 같은 alias를 받는 서버를 사용합니다.

이 repo에는 그 용도의 작은 프록시가 있습니다. 첫 번째 터미널에서 `mlx_lm.server`를 띄웁니다.

```bash
mlx_lm.server \
  --model mlx-community/Qwen2.5-Coder-32B-Instruct-4bit \
  --host 127.0.0.1 \
  --port 8080
```

두 번째 터미널에서 alias proxy를 띄웁니다.

```bash
MLX_PROXY_MODEL_ALIAS=qwen-coder-32b \
MLX_PROXY_UPSTREAM_MODEL=mlx-community/Qwen2.5-Coder-32B-Instruct-4bit \
MLX_PROXY_UPSTREAM=http://127.0.0.1:8080 \
MLX_PROXY_PORT=8090 \
  ./scripts/mlx-openai-alias-proxy.py
```

세 번째 터미널에서 opencode를 실행합니다.

```bash
LOCAL_BACKEND=mlx-lm \
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8090/v1 \
LOCAL_MODEL_ID=qwen-coder-32b \
  ./scripts/opencode-mlx
```

이 방식은 opencode에는 `local/qwen-coder-32b`만 보이게 하고, 실제 요청은 프록시가 `mlx-community/Qwen2.5-Coder-32B-Instruct-4bit`로 바꿔서 `mlx_lm.server`에 전달합니다.

### 고정 설정으로 쓰기

매번 환경변수를 붙이기 싫으면 `local/env.local`을 만듭니다.

```bash
cp local/env.example local/env.local
```

alias proxy를 쓰는 경우 예시:

```env
LOCAL_MODEL_PROFILE=qwen-coder-7b
LOCAL_BACKEND=mlx-lm
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8090/v1
LOCAL_MODEL_ID=qwen-coder-32b
LOCAL_API_KEY=local-dev-token
LOCAL_OPENCODE_PROVIDER_ID=local
```

이후에는 alias proxy와 `mlx_lm.server`를 먼저 켠 뒤:

```bash
./scripts/opencode-mlx /path/to/your/project
```

### 모델 교체

다른 MLX 모델로 바꾸려면 세 곳을 같이 맞춥니다.

1. `mlx_lm.server --model`
2. `MLX_PROXY_UPSTREAM_MODEL`
3. `LOCAL_MODEL_ID` 또는 `MLX_PROXY_MODEL_ALIAS`

예를 들어 14B 모델을 `qwen-coder-14b` alias로 쓰려면:

```bash
mlx_lm.server \
  --model mlx-community/Qwen2.5-Coder-14B-Instruct-4bit \
  --host 127.0.0.1 \
  --port 8080
```

```bash
MLX_PROXY_MODEL_ALIAS=qwen-coder-14b \
MLX_PROXY_UPSTREAM_MODEL=mlx-community/Qwen2.5-Coder-14B-Instruct-4bit \
MLX_PROXY_PORT=8090 \
  ./scripts/mlx-openai-alias-proxy.py
```

```bash
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8090/v1 \
LOCAL_MODEL_ID=qwen-coder-14b \
  ./scripts/opencode-mlx /path/to/project
```

## vMLX로 실행

vMLX는 MLX 기반 로컬 서버/앱 계열입니다. 목표는 LM Studio나 Ollama 없이 Apple Silicon에서 OpenAI-compatible API를 직접 제공하는 것입니다.

vMLX 앱이나 CLI에서 서버를 켜고 OpenAI-compatible endpoint를 확인합니다. 기본 예시는 `8000` 포트를 사용합니다.

```bash
curl http://127.0.0.1:8000/v1/models
```

응답의 model id가 `default`라면:

```bash
LOCAL_BACKEND=vmlx \
LOCAL_MODEL_PROFILE=qwen-coder-7b \
LOCAL_MODEL_ID=default \
  ./scripts/opencode-local
```

응답의 model id가 `qwen-coder-32b`라면:

```bash
LOCAL_BACKEND=vmlx \
LOCAL_MODEL_PROFILE=qwen-coder-7b \
LOCAL_MODEL_ID=qwen-coder-32b \
  ./scripts/opencode-local
```

포트가 다르면 `LOCAL_OPENAI_BASE_URL`을 바꿉니다.

```bash
LOCAL_BACKEND=vmlx \
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:9000/v1 \
LOCAL_MODEL_ID=default \
  ./scripts/opencode-local
```

## vLLM Metal로 실행

`vllm-metal`은 Mac에서 vLLM식 API/스케줄러 감각을 Apple Silicon Metal/MLX 쪽으로 가져오는 실험 backend입니다. 일반 vLLM과 달리 Linux/NVIDIA CUDA를 전제로 하지 않는 방향이지만, 모델 호환성과 설치 절차는 버전에 따라 바뀔 수 있습니다.

서버가 OpenAI-compatible `/v1/chat/completions`와 `/v1/models`를 제공하도록 띄운 뒤 연결합니다.

```bash
curl http://127.0.0.1:8000/v1/models
```

모델 id가 `default`라면:

```bash
LOCAL_BACKEND=vllm-metal \
LOCAL_MODEL_PROFILE=qwen-coder-7b \
LOCAL_MODEL_ID=default \
  ./scripts/opencode-local
```

모델 id를 직접 노출한다면 그 값을 사용합니다.

```bash
LOCAL_BACKEND=vllm-metal \
LOCAL_MODEL_PROFILE=qwen-coder-7b \
LOCAL_MODEL_ID=qwen-coder-32b \
  ./scripts/opencode-local
```

`vllm-metal`은 아직 빠르게 변하는 영역이므로, opencode 쪽에서는 backend를 `openai-compatible`로 두고 URL/model만 맞춰도 됩니다.

```bash
LOCAL_BACKEND=openai-compatible \
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8000/v1 \
LOCAL_MODEL_ID=default \
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

MLX만 기본으로 쓰고 싶으면:

```env
LOCAL_MODEL_PROFILE=qwen-coder-7b
LOCAL_BACKEND=mlx-lm
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8080/v1
LOCAL_MODEL_ID=mlx-community/Qwen2.5-Coder-32B-Instruct-4bit
LOCAL_API_KEY=local-dev-token
LOCAL_OPENCODE_PROVIDER_ID=local
```

이후에는:

```bash
./scripts/opencode-mlx
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

mlx-lm 확인:

```bash
LOCAL_BACKEND=mlx-lm \
LOCAL_MODEL_ID=mlx-community/Qwen2.5-Coder-32B-Instruct-4bit \
  ./scripts/opencode-local --print
```

vMLX 확인:

```bash
LOCAL_BACKEND=vmlx LOCAL_MODEL_ID=default ./scripts/opencode-local --print
```

vLLM Metal 확인:

```bash
LOCAL_BACKEND=vllm-metal LOCAL_MODEL_ID=default ./scripts/opencode-local --print
```

출력의 핵심은 `opencode_selector`입니다. 예를 들어 `local/gemma-4-e4b`이면 provider id는 `local`, model id는 `gemma-4-e4b`입니다.
