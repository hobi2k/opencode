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
cd ~/Desktop/opencode
bun install
```

## 2. 빌드와 PATH 연결

직접 빌드한 실행 파일을 만듭니다.

```bash
cd ~/Desktop/opencode
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
bun ./packages/opencode/script/build.ts --single
```

Apple Silicon Mac에서는 보통 여기에 생깁니다.

```text
~/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode
```

처음 한 번만 PATH에 연결합니다.

```bash
mkdir -p ~/.local/bin
ln -sf ~/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode ~/.local/bin/opencode
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

연결됐는지 확인합니다.

```bash
which -a opencode
opencode --version
```

`0.0.0-dev-<빌드시각>`이 나와야 합니다. 공식 릴리즈를 같이 깔면 PATH 앞을 막아 세션 기록이 갈리므로 설치하지 않습니다.

```bash
brew uninstall opencode
```

## 3. 로컬 LLM 연결

로컬 LLM 연결은 둘 중 하나로 정합니다.

| 방식 | 쓰는 경우 | 평소 입력 |
| --- | --- | --- |
| `local/env.local` | 모델이나 서버를 자주 바꿀 때 | `opencode` |
| `configs/opencode.local.jsonc` | 모델 하나로 고정할 때 | `opencode` |

두 방식은 동시에 켜지 않습니다. `local/env.local` 방식은 alias를 쓰고, `configs/opencode.local.jsonc` 방식은 `OPENCODE_CONFIG`를 씁니다.

### 방식 A: local/env.local

`~/Desktop/opencode/local/env.local`에 값을 넣습니다.

```env
LOCAL_BACKEND=lmstudio
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:1234/v1
LOCAL_MODEL_ID=서버에_보이는_모델_ID
LOCAL_MODEL_NAME=서버에_보이는_모델_ID
LOCAL_API_KEY=local-dev-token
LOCAL_OPENCODE_PROVIDER_ID=local
```

처음 한 번만 alias를 등록합니다.

```bash
echo 'alias opencode="$HOME/Desktop/opencode/scripts/opencode-local"' >> ~/.zshrc
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

`LOCAL_OPENCODE_BIN`은 비워둡니다. `scripts/opencode-local`이 2단계에서 빌드한 실행 파일을 자동으로 찾습니다. 무엇을 띄우는지는 `opencode --print`의 `bin=` 줄로 확인합니다.

작업 폴더에서 확인합니다.

```bash
cd /원하는/작업/폴더
opencode session list
```

### 방식 B: configs/opencode.local.jsonc

`~/Desktop/opencode/configs/opencode.local.jsonc`에서 아래 값을 직접 맞춥니다.

```text
baseURL
models
model
```

처음 한 번만 환경변수를 등록합니다.

```bash
echo 'export OPENCODE_CONFIG="$HOME/Desktop/opencode/configs/opencode.local.jsonc"' >> ~/.zshrc
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

자세한 설명은 [README-local.md](~/Desktop/opencode/README-local.md)에 있습니다.

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
```

모델 ID에 `/`가 있으면 [README-local.md](~/Desktop/opencode/README-local.md)의 alias proxy 절차를 씁니다.

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
```

터미널:

```bash
opencode
```

## 5. Desktop App

이 리포에서 데스크톱 앱을 빌드해서 씁니다. 리포 빌드는 CLI와 같은 `dev` 채널이라 **세션 기록을 CLI와 공유**합니다.

개발 모드로 바로 실행:

```bash
cd ~/Desktop/opencode
bun dev:desktop
```

설치용 앱 빌드:

```bash
cd ~/Desktop/opencode
bun run --cwd packages/desktop build
bun run --cwd packages/desktop package:mac
```

결과물은 아래에 생깁니다. dmg를 열어 Applications로 옮기면 설치됩니다.

```text
~/Desktop/opencode/packages/desktop/dist/opencode-desktop-mac-arm64.dmg
```

앱 이름은 `OpenCode Dev`입니다. 공식 배포판(`OpenCode`)과 다른 번들이라 섞이지 않습니다.

직접 빌드한 앱은 서명이 없어서 처음 열 때 macOS가 막습니다. 한 번만 격리 속성을 지웁니다.

```bash
xattr -dr com.apple.quarantine "/Applications/OpenCode Dev.app"
```

`OPENCODE_CHANNEL`은 붙이지 않습니다. `beta`나 `prod`로 빌드하면 세션 DB가 `opencode.db`로 갈려서 CLI 기록이 보이지 않습니다.

```bash
OPENCODE_CHANNEL=beta ...    # 쓰지 않는다
```

공식 배포판도 같은 이유로 쓰지 않습니다. 서명된 릴리즈는 `prod` 채널로 고정되어 `opencode.db`를 봅니다.

```bash
brew install --cask opencode-desktop    # 쓰지 않는다
```

## 6. 업데이트 (git pull 후)

pull은 소스만 갱신합니다. `dist/`의 실행 파일은 예전 것이 그대로 남으므로 빌드까지가 한 세트입니다.

```bash
cd ~/Desktop/opencode
git status --short
git pull
bun install
bun run --cwd packages/opencode build --single
```

데스크톱 앱도 쓰면 이어서 실행합니다.

```bash
bun run --cwd packages/desktop build
bun run --cwd packages/desktop package:mac
```

확인은 이 한 줄입니다.

```bash
opencode --version
```

```text
0.0.0-dev-202608191126     정상
```

`OPENCODE_CHANNEL`은 붙이지 않습니다. 채널이 세션 DB 파일명을 정합니다.

`local/env.local`이나 `configs/opencode.local.jsonc`만 바꿀 때는 빌드하지 않습니다.

## 7. 세션이 안 보일 때

실행 파일이 바뀌면 세션 DB도 같이 바뀝니다.

| 실행 | 채널 | 세션 DB |
| --- | --- | --- |
| 리포에서 빌드한 CLI | `dev` | `opencode-dev.db` |
| 리포에서 빌드한 데스크톱 앱 | `dev` | `opencode-dev.db` |
| 공식 릴리즈 (brew, 다운로드) | `latest` / `prod` | `opencode.db` |
| 빌드 없이 소스 실행 | `local` | `opencode-local.db` |

세 줄로 확인합니다.

```bash
opencode --version    # 0.0.0-dev-... 가 아니면 다른 실행 파일이다
opencode --print      # bin= 줄이 dist 실행 파일을 가리키는지
which -a opencode     # 다른 설치본이 PATH 앞을 막는지
```

DB별 세션 수:

```bash
for f in ~/.local/share/opencode/opencode*.db; do
  printf '%s ' "$f"
  sqlite3 "$f" "select count(*) from session;"
done
```

`/rename`이 안 보이면 세션 밖(홈 화면)입니다. 세션 커맨드는 세션 안에서만 등록됩니다. `/sessions`로 세션을 열고 쓰면 됩니다. 자세한 내용은 [README-local.md](README-local.md)에 있습니다.
