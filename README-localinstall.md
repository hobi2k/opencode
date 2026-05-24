# opencode 설치 및 실행 가이드

## 1. 처음 설치

```bash
cd ~/Desktop
git clone https://github.com/hobi2k/opencode.git
cd opencode
bun install
```

Bun이 없으면 먼저 설치합니다.

```bash
curl -fsSL https://bun.sh/install | bash
source ~/.zshrc
bun --version
```

`bun: command not found`가 계속 나오면 현재 터미널에 PATH를 넣습니다.

```bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
bun --version
```

이미 clone되어 있으면 여기서 시작합니다.

```bash
cd /Users/hsahn/Desktop/opencode
bun install
```

## 2. 빌드와 PATH 연결

직접 빌드한 실행 파일을 만듭니다.

```bash
cd /Users/hsahn/Desktop/opencode
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
bun ./packages/opencode/script/build.ts --single
```

Apple Silicon Mac에서는 보통 여기에 생깁니다.

```text
/Users/hsahn/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode
```

처음 한 번만 PATH에 연결합니다.

```bash
mkdir -p ~/.local/bin
ln -sf /Users/hsahn/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode ~/.local/bin/opencode
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

이후 원하는 작업 폴더에서 실행합니다.

```bash
opencode
```

다른 프로젝트를 바로 열 때만 경로를 붙입니다.

```bash
opencode /path/to/project
```

빌드란 원본 코드를 수정하는 것이 아니라 실행 파일을 새로 만드는 작업입니다. 같은 위치의 실행 파일을 갱신하므로 빌드할 때마다 PATH를 다시 잡을 필요는 없습니다.

## 3. 로컬 LLM 연결

로컬 LLM 연결은 둘 중 하나로 정합니다.

| 방식 | 쓰는 경우 | 평소 입력 |
| --- | --- | --- |
| `local/env.local` | 모델이나 서버를 자주 바꿀 때 | `opencode` |
| `configs/opencode.local.jsonc` | 모델 하나로 고정할 때 | `opencode` |

두 방식은 동시에 켜지 않습니다. `local/env.local` 방식은 alias를 쓰고, `configs/opencode.local.jsonc` 방식은 `OPENCODE_CONFIG`를 씁니다.

### 방식 A: local/env.local

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

`LOCAL_MODEL_ID`는 서버의 `/v1/models`에 보이는 모델 ID입니다. 고정된 지원 모델 목록은 없습니다.

### 방식 B: configs/opencode.local.jsonc

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

## 4. 서버별 설정

자세한 설명은 [README-local.md](/Users/hsahn/Desktop/opencode/README-local.md)에 있습니다.

### LM Studio

LM Studio 앱에서 모델을 로드하고 Local Server를 켭니다.

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

### Ollama

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

### llama.cpp

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

터미널:

```bash
opencode
```

### mlx-lm

```bash
python3 -m venv ~/.venvs/mlx-lm
source ~/.venvs/mlx-lm/bin/activate
pip install -U pip mlx-lm
mlx_lm.server \
  --model mlx-community/모델이름 \
  --host 127.0.0.1 \
  --port 8080
```

모델 ID 확인:

```bash
curl http://127.0.0.1:8080/v1/models
```

`local/env.local`:

```env
LOCAL_BACKEND=mlx-lm
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8080/v1
LOCAL_MODEL_ID=서버에_보이는_모델_ID
LOCAL_MODEL_NAME=서버에_보이는_모델_ID
LOCAL_API_KEY=local-dev-token
LOCAL_OPENCODE_PROVIDER_ID=local
LOCAL_OPENCODE_BIN=/Users/hsahn/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode
```

모델 ID에 `/`가 있으면 [README-local.md](/Users/hsahn/Desktop/opencode/README-local.md)의 alias proxy 절차를 씁니다.

터미널:

```bash
opencode
```

### vMLX

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

### vLLM

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

터미널:

```bash
opencode
```

### vLLM Metal

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

터미널:

```bash
opencode
```

### 직접 만든 OpenAI-compatible 서버

서버가 아래 endpoint를 제공해야 합니다.

```text
/v1/models
/v1/chat/completions
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

## 5. Desktop app

개발 모드:

```bash
cd /Users/hsahn/Desktop/opencode
bun dev:desktop
```

패키징:

```bash
cd /Users/hsahn/Desktop/opencode
bun run --cwd packages/desktop build
bun run --cwd packages/desktop package:mac
```

공식 배포판:

```bash
brew install --cask opencode-desktop
```

## 6. 업데이트

```bash
cd /Users/hsahn/Desktop/opencode
git status --short
git pull
bun install
```

직접 빌드한 실행 파일을 새로 만들 때만:

```bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
bun ./packages/opencode/script/build.ts --single
```

`local/env.local`이나 `configs/opencode.local.jsonc`만 바꾸는 경우에는 다시 빌드하지 않습니다.
