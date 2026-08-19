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

설정만 바꾸는 경우에는 다시 빌드하지 않습니다. opencode 소스를 `git pull`로 갱신했으면 다시 빌드합니다. 절차는 아래 [업데이트](#업데이트) 항목에 있습니다.

`opencode`는 alias로 `scripts/opencode-local`을 타고, 그 스크립트가 빌드된 실행 파일을 찾아서 띄웁니다. 아래 경로를 자동으로 잡으니 `LOCAL_OPENCODE_BIN`은 비워둬도 됩니다.

```text
packages/opencode/dist/opencode-<os>-<arch>/bin/opencode
```

다른 실행 파일을 쓰고 싶을 때만 `local/env.local`에 직접 적습니다.

```env
LOCAL_OPENCODE_BIN=$HOME/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode
```

지금 무엇을 띄우는지는 `--print`로 확인합니다.

```bash
opencode --print
```

```text
bin=/Users/사용자/Desktop/opencode/packages/opencode/dist/opencode-darwin-arm64/bin/opencode
```

`bin=<source>`로 나오면 빌드된 실행 파일이 없어서 소스로 떨어진 상태입니다. 그때는 세션이 `opencode-local.db`로 가고 프로젝트가 opencode repo로 고정되니, 빌드부터 합니다.

## 방식 A: local/env.local

모델이나 서버를 자주 바꿀 때 이 방식을 씁니다.

`~/Desktop/opencode/local/env.local`에 값을 넣습니다.

```env
LOCAL_BACKEND=lmstudio
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:1234/v1
LOCAL_MODEL_ID=서버에_보이는_모델_ID
LOCAL_MODEL_NAME=서버에_보이는_모델_ID
LOCAL_API_KEY=local-dev-token
LOCAL_OPENCODE_PROVIDER_ID=local
```

`LOCAL_MODEL_ID`는 LM Studio, Ollama, llama.cpp, mlx-lm, vLLM 같은 서버의 `/v1/models`에 보이는 모델 ID입니다. 고정된 지원 모델 목록은 없습니다.

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

## 방식 B: configs/opencode.local.jsonc

모델 하나로 고정해서 쓸 때 이 방식을 씁니다.

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

## backend 목록

| backend | 기본 URL | 서버 |
| --- | --- | --- |
| `lmstudio` | `http://127.0.0.1:1234/v1` | LM Studio Local Server |
| `ollama` | `http://127.0.0.1:11434/v1` | Ollama |
| `llamacpp` | `http://127.0.0.1:8080/v1` | llama.cpp `llama-server` |
| `mlx-lm` | `http://127.0.0.1:8080/v1` | `mlx_lm.server` |
| `vmlx` | `http://127.0.0.1:8000/v1` | vMLX 계열 OpenAI-compatible 서버 |
| `omlx` | `http://127.0.0.1:8001/v1` | omlx 계열 OpenAI-compatible 서버 |
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
```

모델 ID에 `/`가 있으면 alias proxy를 켭니다.

```bash
cd ~/Desktop/opencode
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
```

터미널:

```bash
opencode
```

## omlx

omlx에서 OpenAI-compatible server를 켠 뒤 모델 ID를 확인합니다.

```bash
curl http://127.0.0.1:8001/v1/models
```

`local/env.local`:

```env
LOCAL_BACKEND=omlx
LOCAL_OPENAI_BASE_URL=http://127.0.0.1:8001/v1
LOCAL_MODEL_ID=서버에_보이는_모델_ID
LOCAL_MODEL_NAME=서버에_보이는_모델_ID
LOCAL_API_KEY=local-dev-token
LOCAL_OPENCODE_PROVIDER_ID=local
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

opencode 본체 코드를 수정했거나 `git pull`로 소스를 갱신했으면 다시 빌드합니다.

## 업데이트

`git pull` 뒤에는 아래 네 줄을 한 묶음으로 실행합니다. 빌드까지가 한 세트입니다.

```bash
cd ~/Desktop/opencode
git pull
bun install
bun run --cwd packages/opencode build --single
```

빌드 끝에 스모크 테스트가 새 버전을 찍습니다. 이 줄이 나오면 실행 파일이 갱신된 것입니다.

```text
building opencode-darwin-arm64
Running smoke test: dist/opencode-darwin-arm64/bin/opencode --version
Smoke test passed: 0.0.0-dev-202608190116
```

`git pull`만 하고 빌드를 빼면 소스는 최신인데 실행 파일은 예전 것이 그대로 남습니다. 실행 파일 시각이 마지막 커밋 시각보다 앞서면 빌드가 안 된 상태입니다.

```bash
ls -la packages/opencode/dist/opencode-darwin-arm64/bin/opencode
git log -1 --format='%ad' --date=iso
```

버전 문자열로도 확인합니다.

```bash
opencode --version
```

```text
0.0.0-dev-202608190116   직접 빌드한 실행 파일
1.18.15                  brew 등으로 설치한 공식 릴리즈
local                    빌드 없이 소스로 실행된 상태
```

`0.0.0-dev-`로 시작하지 않으면 의도한 실행 파일이 아닙니다. 아래 순서로 잡습니다.

```text
1. opencode --print 의 bin= 줄이 dist 실행 파일을 가리키는지 본다
2. which -a opencode 로 다른 설치본이 앞을 막는지 본다
3. 다시 빌드한다
```

## 브랜치를 바꿀 때

세션 기록은 `~/.local/share/opencode/` 밑 SQLite 파일에 들어가고, 파일 이름이 빌드 시점의 git 브랜치를 따릅니다. `dev`에서 빌드하면 `opencode-dev.db`입니다. 다른 브랜치에서 빌드하면 기록이 다른 파일로 갈립니다.

브랜치와 무관하게 한 파일을 쓰려면 `local/env.local`에 `export`로 고정합니다.

```env
export OPENCODE_DB=opencode-dev.db
```

`local/env.local`은 `.` (source)로 읽히므로 opencode 본체에 넘길 값은 `export`를 붙입니다. `LOCAL_*`는 스크립트가 직접 쓰니 `export` 없이도 됩니다.

현재 어떤 파일에 세션이 쌓여 있는지 확인:

```bash
for f in ~/.local/share/opencode/opencode*.db; do
  printf '%s ' "$f"
  sqlite3 "$f" "select count(*) from session;"
done
```

## 슬래시 커맨드

세션 밖(홈 화면)과 세션 안에서 쓸 수 있는 커맨드가 다릅니다.

| 어디서 | 커맨드 |
| --- | --- |
| 홈 화면 포함 어디서나 | `/sessions` `/new` `/models` `/agents` `/mcps` `/skills` `/variants` `/themes` `/status` `/help` `/exit` `/connect` `/workspaces` `/editor` `/warp` `/move` `/debug` |
| 세션 안에서만 | `/rename` `/share` `/unshare` `/compact` `/fork` `/timeline` `/undo` `/redo` `/copy` `/export` `/timestamps` `/thinking` |

홈 화면에서 `/rename`이 안 보이는 것은 정상입니다. `/sessions`로 기존 세션을 열거나 `/new`로 새 세션을 시작한 뒤에 씁니다. 세션 이름 바꾸기는 `ctrl+r`로도 됩니다.

```bash
opencode --continue
```
