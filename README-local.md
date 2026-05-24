# opencode 로컬 LLM 실행 가이드

## 기본 사용

평소 터미널에는 이것만 입력합니다.

```bash
opencode
```

현재 폴더가 아니라 다른 폴더를 바로 열 때만 경로를 붙입니다.

```bash
opencode /path/to/project
```

로컬 모델 연결은 두 가지 중 하나로 정합니다.

| 방식 | 쓰는 경우 | 평소 입력 |
| --- | --- | --- |
| `local/env.local` | 모델이나 서버를 자주 바꿀 때 | `opencode` |
| `configs/opencode.local.jsonc` | 모델 하나로 고정할 때 | `opencode` |

두 방식은 동시에 켜지 않습니다. `local/env.local` 방식은 alias를 쓰고, `configs/opencode.local.jsonc` 방식은 `OPENCODE_CONFIG`를 씁니다.

설정만 바꾸는 경우에는 다시 빌드하지 않습니다.

## 방식 A: local/env.local

모델이나 서버를 자주 바꿀 때 이 방식을 씁니다.

`/Users/hsahn/Desktop/opencode/local/env.local`에 값을 넣습니다.

```env
LOCAL_BACKEND=lmstudio
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:1234/v1
LOCAL_MODEL_ID=서버에_보이는_모델_ID
LOCAL_MODEL_NAME=서버에_보이는_모델_ID
LOCAL_API_KEY=local-dev-token
LOCAL_OPENCODE_PROVIDER_ID=local
LOCAL_OPENCODE_BIN=/Users/hsahn/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode
```

`LOCAL_MODEL_ID`는 LM Studio, Ollama, llama.cpp, mlx-lm, vLLM 같은 서버의 `/v1/models`에 보이는 모델 ID입니다. 고정된 지원 모델 목록은 없습니다.

처음 한 번만 alias를 등록합니다.

```bash
echo "alias opencode='/Users/hsahn/Desktop/opencode/scripts/opencode-local'" >> ~/.zshrc
source ~/.zshrc
```

그 뒤에는 원하는 작업 폴더에서 실행합니다.

```bash
opencode
```

설정 확인:

```bash
opencode --print
```

## 방식 B: configs/opencode.local.jsonc

모델 하나로 고정해서 쓸 때 이 방식을 씁니다.

`/Users/hsahn/Desktop/opencode/configs/opencode.local.jsonc`에서 아래 값을 직접 맞춥니다.

```text
baseURL
models
model
```

처음 한 번만 환경변수를 등록합니다.

```bash
echo 'export OPENCODE_CONFIG=/Users/hsahn/Desktop/opencode/configs/opencode.local.jsonc' >> ~/.zshrc
source ~/.zshrc
```

그 뒤에는 원하는 작업 폴더에서 실행합니다.

```bash
opencode
```

이 방식은 `local/env.local`을 쓰지 않습니다.

`local/env.local` 방식으로 등록했던 alias가 있으면 config 파일 방식으로 바꾸기 전에 제거합니다.

```bash
unalias opencode
```

## backend 목록

| backend | 기본 URL | 서버 |
| --- | --- | --- |
| `lmstudio` | `http://127.0.0.1:1234/v1` | LM Studio Local Server |
| `ollama` | `http://127.0.0.1:11434/v1` | Ollama |
| `llamacpp` | `http://127.0.0.1:8080/v1` | llama.cpp `llama-server` |
| `mlx-lm` | `http://127.0.0.1:8080/v1` | `mlx_lm.server` |
| `vmlx` | `http://127.0.0.1:8000/v1` | vMLX 계열 OpenAI-compatible 서버 |
| `vllm` | `http://127.0.0.1:8000/v1` | vLLM OpenAI server |
| `vllm-metal` | `http://127.0.0.1:8000/v1` | Mac용 vLLM Metal 계열 |
| `openai-compatible` | `http://127.0.0.1:8000/v1` | 직접 만든 OpenAI-compatible 서버 |

## LM Studio

LM Studio에서 할 일:

1. 모델 로드
2. Local Server 켜기
3. 모델 ID 확인

`local/env.local`:

```env
LOCAL_BACKEND=lmstudio
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:1234/v1
LOCAL_MODEL_ID=LM_STUDIO_모델_ID
LOCAL_MODEL_NAME=LM_STUDIO_모델_ID
LOCAL_API_KEY=local-dev-token
LOCAL_OPENCODE_PROVIDER_ID=local
LOCAL_OPENCODE_BIN=/Users/hsahn/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode
```

터미널:

```bash
opencode
```

## Ollama

서버 준비:

```bash
ollama pull 모델이름
```

`local/env.local`:

```env
LOCAL_BACKEND=ollama
LOCAL_MODEL_ID=모델이름
LOCAL_MODEL_NAME=모델이름
LOCAL_API_KEY=local-dev-token
LOCAL_OPENCODE_PROVIDER_ID=local
LOCAL_OPENCODE_BIN=/Users/hsahn/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode
```

터미널:

```bash
opencode
```

## llama.cpp

서버 실행:

```bash
llama-server \
  -m models/모델파일.gguf \
  --alias my-model \
  --host 127.0.0.1 \
  --port 8080
```

`local/env.local`:

```env
LOCAL_BACKEND=llamacpp
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8080/v1
LOCAL_MODEL_ID=my-model
LOCAL_MODEL_NAME=my-model
LOCAL_API_KEY=local-dev-token
LOCAL_OPENCODE_PROVIDER_ID=local
LOCAL_OPENCODE_BIN=/Users/hsahn/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode
```

`LOCAL_MODEL_ID`는 `llama-server --alias` 값과 맞춥니다.

터미널:

```bash
opencode
```

## mlx-lm

설치:

```bash
python3 -m venv ~/.venvs/mlx-lm
source ~/.venvs/mlx-lm/bin/activate
pip install -U pip mlx-lm
```

서버 실행:

```bash
source ~/.venvs/mlx-lm/bin/activate
mlx_lm.server \
  --model mlx-community/모델이름 \
  --host 127.0.0.1 \
  --port 8080
```

모델 ID 확인:

```bash
curl http://127.0.0.1:8080/v1/models
```

모델 ID에 `/`가 없으면 `local/env.local`:

```env
LOCAL_BACKEND=mlx-lm
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8080/v1
LOCAL_MODEL_ID=서버에_보이는_모델_ID
LOCAL_MODEL_NAME=서버에_보이는_모델_ID
LOCAL_API_KEY=local-dev-token
LOCAL_OPENCODE_PROVIDER_ID=local
LOCAL_OPENCODE_BIN=/Users/hsahn/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode
```

모델 ID에 `/`가 있으면 alias proxy를 켭니다.

```bash
cd /Users/hsahn/Desktop/opencode
MLX_PROXY_MODEL_ALIAS=my-model \
MLX_PROXY_UPSTREAM_MODEL=mlx-community/모델이름 \
MLX_PROXY_UPSTREAM=http://127.0.0.1:8080 \
MLX_PROXY_PORT=8090 \
  ./scripts/mlx-openai-alias-proxy.py
```

alias proxy를 쓸 때 `local/env.local`:

```env
LOCAL_BACKEND=mlx-lm
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8090/v1
LOCAL_MODEL_ID=my-model
LOCAL_MODEL_NAME=my-model
LOCAL_API_KEY=local-dev-token
LOCAL_OPENCODE_PROVIDER_ID=local
LOCAL_OPENCODE_BIN=/Users/hsahn/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode
```

터미널:

```bash
opencode
```

## vMLX

vMLX에서 OpenAI-compatible server를 켠 뒤 모델 ID를 확인합니다.

```bash
curl http://127.0.0.1:8000/v1/models
```

`local/env.local`:

```env
LOCAL_BACKEND=vmlx
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8000/v1
LOCAL_MODEL_ID=서버에_보이는_모델_ID
LOCAL_MODEL_NAME=서버에_보이는_모델_ID
LOCAL_API_KEY=local-dev-token
LOCAL_OPENCODE_PROVIDER_ID=local
LOCAL_OPENCODE_BIN=/Users/hsahn/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode
```

터미널:

```bash
opencode
```

## vLLM

서버 실행:

```bash
python -m vllm.entrypoints.openai.api_server \
  --model org/model-name \
  --served-model-name my-model \
  --host 127.0.0.1 \
  --port 8000
```

`local/env.local`:

```env
LOCAL_BACKEND=vllm
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8000/v1
LOCAL_MODEL_ID=my-model
LOCAL_MODEL_NAME=my-model
LOCAL_API_KEY=local-dev-token
LOCAL_OPENCODE_PROVIDER_ID=local
LOCAL_OPENCODE_BIN=/Users/hsahn/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode
```

`LOCAL_MODEL_ID`는 `--served-model-name` 값과 맞춥니다.

터미널:

```bash
opencode
```

## vLLM Metal

vLLM Metal 계열 서버를 켠 뒤 모델 ID를 확인합니다.

```bash
curl http://127.0.0.1:8000/v1/models
```

`local/env.local`:

```env
LOCAL_BACKEND=vllm-metal
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8000/v1
LOCAL_MODEL_ID=서버에_보이는_모델_ID
LOCAL_MODEL_NAME=서버에_보이는_모델_ID
LOCAL_API_KEY=local-dev-token
LOCAL_OPENCODE_PROVIDER_ID=local
LOCAL_OPENCODE_BIN=/Users/hsahn/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode
```

서버가 일반 OpenAI-compatible API만 제공한다면 `LOCAL_BACKEND=openai-compatible`로 써도 됩니다.

터미널:

```bash
opencode
```

## 직접 만든 OpenAI-compatible 서버

서버 조건:

```text
/v1/models
/v1/chat/completions
```

확인:

```bash
curl http://127.0.0.1:8000/v1/models
```

`local/env.local`:

```env
LOCAL_BACKEND=openai-compatible
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8000/v1
LOCAL_MODEL_ID=서버에_보이는_모델_ID
LOCAL_MODEL_NAME=서버에_보이는_모델_ID
LOCAL_API_KEY=local-dev-token
LOCAL_OPENCODE_PROVIDER_ID=local
LOCAL_OPENCODE_BIN=/Users/hsahn/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode
```

터미널:

```bash
opencode
```

## 빌드

아래만 바꾸면 다시 빌드하지 않습니다.

```text
local/env.local
LOCAL_BACKEND
LOCAL_OPENAI_BASE_URL
LOCAL_MODEL_ID
configs/opencode.local.jsonc
```

opencode 본체 코드를 수정했거나 최신 빌드 실행 파일을 새로 만들 때만 다시 빌드합니다.
