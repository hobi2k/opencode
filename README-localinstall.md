# opencode 소스 설치 및 실행 가이드

이 문서는 opencode를 공식 설치 스크립트가 아니라 GitHub repository clone 기반으로 직접 설치하고 실행하는 방법을 정리합니다.

목표:

- opencode 소스를 직접 보관합니다.
- `bun dev` 또는 직접 빌드한 binary로 Claude Code/Codex처럼 터미널 CLI를 실행합니다.
- 필요하면 desktop app도 개발 모드로 실행하거나 패키징합니다.
- 로컬 LLM 연결은 `README-local.md`의 wrapper와 함께 씁니다.

## 전체 구조

opencode repo에서 중요한 패키지는 아래와 같습니다.

```text
packages/opencode   터미널 CLI, TUI, server 본체
packages/app        web/desktop에서 쓰는 공유 UI
packages/desktop    Electron desktop app
```

루트 `package.json` 기준 주요 명령:

```bash
bun dev             # packages/opencode/src/index.ts 실행, CLI 개발 모드
bun dev:desktop     # packages/desktop 개발 모드 실행
bun dev:web         # packages/app 개발 서버 실행
```

## 1. 준비물

macOS Apple Silicon 기준 권장 준비물:

```text
Git
Bun 1.3+
Node.js는 직접 실행에는 필수는 아니지만 일부 생태계 도구에서 필요할 수 있음
```

Bun 확인:

```bash
bun --version
```

Bun이 없다면 설치:

```bash
curl -fsSL https://bun.sh/install | bash
```

설치가 끝난 뒤 새 터미널을 열거나 shell 설정을 다시 불러옵니다.

```bash
source ~/.zshrc
```

확인합니다.

```bash
bun --version
```

만약 여전히 `zsh: command not found: bun`이 나오면 현재 터미널에 PATH를 직접 넣어 확인합니다.

```bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
bun --version
```

이 명령으로는 동작하는데 새 터미널에서 다시 안 잡히면 `~/.zshrc`에 아래 줄이 있는지 확인합니다.

```bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
```

## 2. Git clone

공식 upstream을 받을 경우:

```bash
cd ~/Desktop
git clone https://github.com/anomalyco/opencode.git
cd opencode
```

이 로컬 포크를 받을 경우:

```bash
cd ~/Desktop
git clone https://github.com/hobi2k/opencode.git
cd opencode
```

이미 `/Users/hsahn/Desktop/opencode`에 clone되어 있다면:

```bash
cd /Users/hsahn/Desktop/opencode
```

현재 remote 확인:

```bash
git remote -v
git status --short --branch
```

## 3. 의존성 설치

repo root에서 실행합니다.

```bash
cd /Users/hsahn/Desktop/opencode
bun install
```

설치가 끝나면 source CLI를 실행할 수 있습니다.

## 4. CLI를 Claude Code/Codex처럼 실행하기

개발 모드에서 `bun dev`는 설치된 `opencode` 명령과 같은 CLI 역할을 합니다.

도움말:

```bash
cd /Users/hsahn/Desktop/opencode
bun dev --help
```

현재 repo 자체를 대상으로 실행:

```bash
bun dev .
```

다른 프로젝트를 대상으로 실행:

```bash
bun dev /path/to/your/project
```

예:

```bash
bun dev ~/Desktop/my-project
```

이 방식은 `opencode`를 전역 설치하지 않아도 됩니다. 다만 항상 opencode repo 안에서 `bun dev <target>`로 실행합니다.

## 5. CLI 전역 명령처럼 쓰기

매번 repo로 이동하기 싫으면 shell alias를 둡니다.

zsh 기준:

```bash
echo 'alias opencode="cd /Users/hsahn/Desktop/opencode && bun dev"' >> ~/.zshrc
source ~/.zshrc
```

이후:

```bash
opencode /path/to/your/project
```

주의: 이 alias는 현재 shell을 opencode repo로 이동시킨 뒤 실행합니다. 단순하고 투명한 방식입니다.

## 6. standalone CLI binary 빌드

소스에서 직접 binary를 만들고 싶으면:

```bash
cd /Users/hsahn/Desktop/opencode
./packages/opencode/script/build.ts --single
```

Apple Silicon Mac에서는 보통 아래 경로에 binary가 생깁니다.

```text
packages/opencode/dist/opencode-darwin-arm64/bin/opencode
```

실행 확인:

```bash
./packages/opencode/dist/opencode-darwin-arm64/bin/opencode --help
```

프로젝트에서 실행:

```bash
./packages/opencode/dist/opencode-darwin-arm64/bin/opencode /path/to/your/project
```

## 7. 직접 빌드한 binary를 PATH에 연결

사용자 bin 디렉터리를 만듭니다.

```bash
mkdir -p ~/.local/bin
```

심볼릭 링크를 만듭니다.

```bash
ln -sf /Users/hsahn/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode ~/.local/bin/opencode
```

`~/.local/bin`이 PATH에 없다면:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

확인:

```bash
opencode --help
```

이제 어디서든:

```bash
opencode /path/to/your/project
```

## 8. 로컬 LLM과 함께 CLI 실행

로컬 LLM 연결은 `README-local.md`의 wrapper를 사용합니다.

가장 추천하는 Apple Silicon 자립형 경로:

```text
mlx_lm.server
scripts/mlx-openai-alias-proxy.py
scripts/opencode-mlx
```

설정 확인:

```bash
cd /Users/hsahn/Desktop/opencode
./scripts/opencode-mlx --print
```

프로젝트 실행:

```bash
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8090/v1 \
LOCAL_MODEL_ID=qwen-coder-32b \
  ./scripts/opencode-mlx /path/to/your/project
```

직접 빌드한 binary를 wrapper가 쓰게 하려면:

```bash
LOCAL_OPENCODE_BIN=/Users/hsahn/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode \
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8090/v1 \
LOCAL_MODEL_ID=qwen-coder-32b \
  ./scripts/opencode-mlx /path/to/your/project
```

## 9. headless server 실행

CLI/TUI 없이 server만 띄우려면:

```bash
cd /Users/hsahn/Desktop/opencode
bun dev serve
```

기본 포트는 `4096`입니다.

포트 지정:

```bash
bun dev serve --port 4096
```

server에 attach:

```bash
bun dev attach http://localhost:4096
```

또는 전역/빌드 binary가 있다면:

```bash
opencode-local attach http://localhost:4096
```

## 10. web UI 개발 서버 실행

server를 먼저 켭니다.

```bash
cd /Users/hsahn/Desktop/opencode
bun dev serve
```

다른 터미널에서 web app을 켭니다.

```bash
cd /Users/hsahn/Desktop/opencode
bun run --cwd packages/app dev
```

터미널에 표시되는 localhost URL로 접속합니다. 보통 Vite dev server 포트가 표시됩니다.

## 11. Desktop app 개발 모드 실행

desktop app은 Electron 앱이며 `packages/app` UI를 감쌉니다.

repo root에서:

```bash
cd /Users/hsahn/Desktop/opencode
bun dev:desktop
```

또는 package 디렉터리에서 직접:

```bash
cd /Users/hsahn/Desktop/opencode
bun run --cwd packages/desktop dev
```

처음 실행 전후로 `packages/desktop/scripts/predev.ts`가 필요한 준비 작업을 수행합니다.

## 12. Desktop app 패키징

desktop build:

```bash
cd /Users/hsahn/Desktop/opencode
bun run --cwd packages/desktop build
```

macOS 패키지:

```bash
bun run --cwd packages/desktop package:mac
```

전체 package 명령:

```bash
bun run --cwd packages/desktop package
```

결과물은 보통 아래에 생성됩니다.

```text
packages/desktop/dist
```

주의:

- 로컬 패키징은 코드서명/notarization 설정이 없으면 경고가 나거나 배포용 품질이 아닐 수 있습니다.
- 개인 테스트용이면 개발 모드 `bun dev:desktop`이 더 간단합니다.

## 13. 공식 Desktop app 설치

소스 빌드가 아니라 공식 배포판을 쓰려면:

```bash
brew install --cask opencode-desktop
```

또는 GitHub releases / 공식 다운로드 페이지에서 받습니다.

```text
https://github.com/anomalyco/opencode/releases
https://opencode.ai/download
```

macOS Apple Silicon용 파일 이름은 보통:

```text
opencode-desktop-mac-arm64.dmg
```

## 14. 업데이트

소스 repo 업데이트:

```bash
cd /Users/hsahn/Desktop/opencode
git status --short
git pull
bun install
```

직접 빌드한 binary도 새로 만들려면:

```bash
./packages/opencode/script/build.ts --single
```

## 15. 문제 해결

### `bun: command not found`

Bun이 설치되어 있지 않거나 PATH에 안 잡힌 상태입니다.

먼저 설치합니다.

```bash
curl -fsSL https://bun.sh/install | bash
```

설치 후 새 터미널을 열거나 shell 설정을 다시 로드합니다.

```bash
source ~/.zshrc
```

확인:

```bash
bun --version
```

그래도 안 되면 현재 터미널에 PATH를 직접 추가합니다.

```bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
bun --version
```

그 다음 다시 실행합니다.

```bash
cd /Users/hsahn/Desktop/opencode
bun install
bun dev
```

### `bun install`이 실패함

네트워크나 registry 문제일 수 있습니다. 다시 실행합니다.

```bash
bun install
```

### CLI가 모델을 못 찾음

로컬 LLM 서버의 모델 목록을 먼저 확인합니다.

```bash
curl http://127.0.0.1:8090/v1/models
```

wrapper 설정 출력:

```bash
./scripts/opencode-mlx --print
```

`opencode_selector`의 provider/model 값과 `/v1/models`의 model id가 맞아야 합니다.

### desktop app이 안 켜짐

먼저 CLI가 실행되는지 확인합니다.

```bash
bun dev --help
```

그 다음 desktop만 다시 실행합니다.

```bash
bun dev:desktop
```

### 포트가 이미 사용 중임

대표 포트 확인:

```bash
lsof -ti tcp:4096
lsof -ti tcp:5173
lsof -ti tcp:8080
lsof -ti tcp:8090
```

필요하면 서버를 끄거나 다른 포트를 사용합니다.

## 16. 추천 사용 패턴

매일 쓰는 CLI:

```bash
opencode-local /path/to/project
```

소스 개발/디버깅:

```bash
cd /Users/hsahn/Desktop/opencode
bun dev /path/to/project
```

Apple Silicon 로컬 MLX:

```bash
cd /Users/hsahn/Desktop/opencode
./scripts/opencode-mlx /path/to/project
```

desktop 개발:

```bash
cd /Users/hsahn/Desktop/opencode
bun dev:desktop
```
