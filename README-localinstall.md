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

연결이 됐는지 확인합니다.

```bash
which -a opencode
opencode --version
```

```text
0.0.0-dev-202608190116   직접 빌드한 실행 파일
1.18.15                  brew 등으로 설치한 공식 릴리즈
local                    빌드 없이 소스로 실행된 상태
```

`brew install opencode`로 받은 `/opt/homebrew/bin/opencode`는 보통 `~/.local/bin`보다 PATH 앞입니다. 직접 빌드한 것만 쓸 거라면 지웁니다. 공식 릴리즈와 직접 빌드는 세션 기록 파일이 서로 다르므로 번갈아 쓰지 않습니다.

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

`LOCAL_OPENCODE_BIN`은 비워둬도 됩니다. `scripts/opencode-local`이 2단계에서 빌드한 실행 파일을 자동으로 찾습니다.

```text
packages/opencode/dist/opencode-<os>-<arch>/bin/opencode
```

무엇을 띄우는지 확인합니다.

```bash
opencode --print
```

```text
bin=/Users/사용자/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode
```

`bin=<source>`면 빌드된 실행 파일이 없어서 소스로 떨어진 상태입니다. 그러면 세션 기록 파일이 갈리고 프로젝트가 opencode repo로 고정되니, 2단계 빌드를 먼저 합니다.

작업 폴더에서 제대로 붙었는지 확인합니다.

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

## 5. Desktop App (BETA)

이 repo에서 데스크톱 앱을 실행하거나 직접 설치 파일을 만들 수 있습니다.

개발 모드로 바로 실행:

```bash
cd ~/Desktop/opencode
bun dev:desktop
```

macOS 앱을 직접 빌드:

```bash
cd ~/Desktop/opencode
bun run --cwd packages/desktop build
bun run --cwd packages/desktop package:mac
```

BETA 채널 이름으로 macOS 앱을 직접 빌드:

```bash
cd ~/Desktop/opencode
OPENCODE_CHANNEL=beta bun run --cwd packages/desktop build
OPENCODE_CHANNEL=beta bun run --cwd packages/desktop package:mac
```

패키징 결과물은 아래 폴더에 생깁니다.

```text
~/Desktop/opencode/packages/desktop/dist
```

Apple Silicon Mac에서는 보통 이런 파일이 생깁니다.

```text
opencode-desktop-mac-arm64.dmg
```

DMG를 열어서 Applications로 옮기면 설치됩니다.

공식 배포판을 받을 때만 아래 방법을 씁니다.

```bash
brew install --cask opencode-desktop
```

공식 다운로드 페이지:

```text
https://opencode.ai/download
https://github.com/anomalyco/opencode/releases
```

## 6. 업데이트 (git pull 후 최신화)

`git pull`은 소스만 갱신합니다. `dist/`의 실행 파일은 그대로 남으므로 빌드까지 해야 최신화가 끝납니다. 아래를 한 묶음으로 실행합니다.

```bash
cd ~/Desktop/opencode
git status --short
git pull
bun install
bun run --cwd packages/opencode build --single
```

`git status --short`에 내가 고친 파일이 남아 있으면 pull 전에 정리합니다. `local/env.local`은 git이 추적하지 않으므로 pull에 영향받지 않습니다.

빌드 끝에 스모크 테스트가 새 버전을 찍습니다. 이 줄이 나오면 실행 파일이 갱신된 것입니다.

```text
building opencode-darwin-arm64
Running smoke test: dist/opencode-darwin-arm64/bin/opencode --version
Smoke test passed: 0.0.0-dev-202608190116
```

마무리 확인 세 줄입니다.

```bash
opencode --version
which -a opencode
ls -la packages/opencode/dist/opencode-darwin-arm64/bin/opencode
```

확인 기준:

```text
opencode --version 이 0.0.0-dev-<빌드시각> 인지
which -a opencode 첫 줄이 alias 또는 ~/.local/bin/opencode 인지
dist 실행 파일 시각이 마지막 커밋 시각보다 뒤인지
```

마지막 커밋 시각은 이렇게 봅니다.

```bash
git log -1 --format='%ad' --date=iso
```

`local/env.local`이나 `configs/opencode.local.jsonc`만 바꾸는 경우에는 다시 빌드하지 않습니다.

### 세션 기록 위치

세션은 `~/.local/share/opencode/` 밑 SQLite 파일에 들어가고, 파일 이름이 빌드 시점의 git 브랜치를 따릅니다. `dev`에서 빌드하면 `opencode-dev.db`입니다. 공식 릴리즈는 `opencode.db`, 빌드 없이 소스로 실행하면 `opencode-local.db`를 씁니다.

그래서 실행 경로를 바꾸면 세션 목록이 비어 보입니다. 실행 경로를 하나로 유지하는 것이 원칙입니다.

브랜치를 바꿔도 한 파일을 쓰려면 `local/env.local`에 `export`로 고정합니다.

```env
export OPENCODE_DB=opencode-dev.db
```

`local/env.local`은 `.` (source)로 읽히므로 opencode 본체에 넘길 값은 `export`를 붙입니다. `LOCAL_*`는 스크립트가 직접 쓰니 `export` 없이도 됩니다.

어느 파일에 세션이 쌓여 있는지 확인:

```bash
for f in ~/.local/share/opencode/opencode*.db; do
  printf '%s ' "$f"
  sqlite3 "$f" "select count(*) from session;"
done
```

### 슬래시 커맨드

업데이트 뒤에 `/rename`이 안 보이면 세션 밖(홈 화면)일 가능성이 큽니다. 커맨드 범위가 둘로 나뉩니다.

| 어디서 | 커맨드 |
| --- | --- |
| 홈 화면 포함 어디서나 | `/sessions` `/new` `/models` `/agents` `/mcps` `/skills` `/variants` `/themes` `/status` `/help` `/exit` `/connect` `/workspaces` `/editor` `/warp` `/move` `/debug` |
| 세션 안에서만 | `/rename` `/share` `/unshare` `/compact` `/fork` `/timeline` `/undo` `/redo` `/copy` `/export` `/timestamps` `/thinking` |

`/sessions`로 기존 세션을 열거나 `/new`로 시작한 뒤에 씁니다. 세션 이름 바꾸기는 `ctrl+r`로도 됩니다.

```bash
opencode --continue
```
