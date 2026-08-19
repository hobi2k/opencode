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

설정만 바꾸면 빌드하지 않습니다. `git pull`로 소스를 갱신했으면 빌드까지 해야 합니다. 절차는 [업데이트](#업데이트)에 있습니다.

`opencode` alias는 `scripts/opencode-local`을 타고, 그 스크립트가 `packages/opencode/dist` 밑의 빌드된 실행 파일을 자동으로 찾습니다. 그래서 `local/env.local`의 `LOCAL_OPENCODE_BIN`은 비워둡니다.

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

## 업데이트

`git pull` 하면 빌드까지가 한 세트입니다. pull은 소스만 갱신하고 `dist/`의 실행 파일은 예전 것이 그대로 남습니다.

```bash
cd ~/Desktop/opencode
git pull
bun install
bun run --cwd packages/opencode build --single
```

데스크톱 앱도 쓰면 이어서 실행합니다.

```bash
bun run --cwd packages/desktop build
bun run --cwd packages/desktop package:mac
```

`packages/desktop/dist`에 생긴 dmg를 열어 Applications로 옮깁니다.

확인은 이 한 줄입니다.

```bash
opencode --version
```

```text
0.0.0-dev-202608191126     정상
```

`OPENCODE_CHANNEL`은 붙이지 않습니다. 채널이 세션 DB 파일명을 정하기 때문에, 붙여서 빌드하면 기록이 다른 파일로 갈립니다.

아래만 바꿀 때는 빌드하지 않습니다.

```text
local/env.local
configs/opencode.local.jsonc
```

## 세션이 안 보일 때

실행 파일이 바뀌면 세션 DB도 같이 바뀝니다. 세 줄로 확인합니다.

```bash
opencode --version    # 0.0.0-dev-... 가 아니면 다른 실행 파일이다
opencode --print      # bin= 줄이 dist 실행 파일을 가리키는지
which -a opencode     # 다른 설치본이 PATH 앞을 막는지
```

DB는 채널로 갈립니다.

| 실행 | 채널 | 세션 DB |
| --- | --- | --- |
| 리포에서 빌드한 CLI | `dev` | `opencode-dev.db` |
| 리포에서 빌드한 데스크톱 앱 | `dev` | `opencode-dev.db` |
| 공식 릴리즈 (brew, 다운로드) | `latest` / `prod` | `opencode.db` |
| 빌드 없이 소스 실행 | `local` | `opencode-local.db` |

리포에서 빌드한 CLI와 데스크톱 앱은 같은 `opencode-dev.db`를 씁니다. 공식 릴리즈를 섞어 쓰면 기록이 안 보이므로 설치하지 않습니다.

```bash
brew uninstall opencode
```

세션 수를 직접 셀 수 있습니다.

```bash
for f in ~/.local/share/opencode/opencode*.db; do
  printf '%s ' "$f"
  sqlite3 "$f" "select count(*) from session;"
done
```

## 슬래시 커맨드

세션 밖과 세션 안에서 쓸 수 있는 커맨드가 다릅니다.

| 어디서 | 커맨드 |
| --- | --- |
| 홈 화면 포함 어디서나 | `/sessions` `/new` `/models` `/agents` `/mcps` `/skills` `/variants` `/themes` `/status` `/help` `/exit` |
| 세션 안에서만 | `/rename` `/share` `/compact` `/fork` `/timeline` `/undo` `/redo` `/copy` `/export` |

홈 화면에서 `/rename`이 안 보이는 것은 정상입니다. `/sessions`로 기존 세션을 열거나 `/new`로 시작한 뒤에 씁니다.

## 프로젝트 폴더 이름을 바꿨을 때

opencode는 프로젝트의 `worktree` 경로를 처음 한 번만 기록하고 이후 갱신하지 않습니다. 폴더 이름을 바꾸면 `/sessions`가 빈 목록으로 보입니다. DB를 직접 고칩니다.

```bash
sqlite3 ~/.local/share/opencode/opencode-dev.db \
  "select id, worktree from project;"
```

없는 경로가 보이면 그 행을 새 경로로 바꿉니다. opencode를 모두 종료한 뒤 실행합니다.

```bash
sqlite3 ~/.local/share/opencode/opencode-dev.db "
UPDATE project SET worktree='/새/경로', sandboxes='[]' WHERE id='해당ID';
UPDATE session SET directory='/새/경로' WHERE project_id='해당ID' AND directory='/옛/경로';
"
```
