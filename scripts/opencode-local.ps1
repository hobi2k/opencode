param(
  [string]$Profile,
  [string]$Backend,
  [switch]$Print,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$OpenCodeArgs
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

function Resolve-LocalProfile {
  param([string]$Name)
  switch ($Name) {
    "gemma-4-e4b" { @{ Display = "Gemma 4 E4B IT"; Alias = "gemma-4-e4b"; Ollama = "" } }
    "gemma-4-e2b" { @{ Display = "Gemma 4 E2B IT"; Alias = "gemma-4-e2b"; Ollama = "" } }
    "qwen-coder-7b" { @{ Display = "Qwen2.5 Coder 7B Instruct"; Alias = "qwen-coder-7b"; Ollama = "qwen2.5-coder:7b" } }
    "qwen-coder-3b" { @{ Display = "Qwen2.5 Coder 3B Instruct"; Alias = "qwen-coder-3b"; Ollama = "qwen2.5-coder:3b" } }
    "qwen-coder-1.5b" { @{ Display = "Qwen2.5 Coder 1.5B Instruct"; Alias = "qwen-coder-1.5b"; Ollama = "qwen2.5-coder:1.5b" } }
    default { throw "Unknown LOCAL_MODEL_PROFILE: $Name" }
  }
}

$LocalEnv = Join-Path $Root "local/env.local"
if (Test-Path $LocalEnv) {
  Get-Content $LocalEnv | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+?)=(.*)$') {
      [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), "Process")
    }
  }
}

if (-not $Profile) { $Profile = if ($env:LOCAL_MODEL_PROFILE) { $env:LOCAL_MODEL_PROFILE } else { "qwen-coder-7b" } }
if (-not $Backend) { $Backend = if ($env:LOCAL_BACKEND) { $env:LOCAL_BACKEND } else { "ollama" } }

$ProfileData = Resolve-LocalProfile $Profile
$BaseUrl = $env:LOCAL_OPENAI_BASE_URL
$Model = $env:LOCAL_MODEL_ID

switch ($Backend) {
  "ollama" {
    if (-not $BaseUrl) { $BaseUrl = "http://127.0.0.1:11434/v1" }
    if (-not $Model) { $Model = if ($ProfileData.Ollama) { $ProfileData.Ollama } else { $ProfileData.Alias } }
  }
  "llamacpp" {
    if (-not $BaseUrl) { $BaseUrl = "http://127.0.0.1:8080/v1" }
    if (-not $Model) { $Model = $ProfileData.Alias }
  }
  "vllm" {
    if (-not $BaseUrl) { $BaseUrl = "http://127.0.0.1:8000/v1" }
    if (-not $Model) { $Model = $ProfileData.Alias }
  }
  { $_ -in @("mlx-lm", "mlxlm") } {
    if (-not $BaseUrl) { $BaseUrl = "http://127.0.0.1:8080/v1" }
    if (-not $Model) { $Model = $ProfileData.Alias }
  }
  "vmlx" {
    if (-not $BaseUrl) { $BaseUrl = "http://127.0.0.1:8000/v1" }
    if (-not $Model) { $Model = $ProfileData.Alias }
  }
  { $_ -in @("vllm-metal", "vllmmetal") } {
    if (-not $BaseUrl) { $BaseUrl = "http://127.0.0.1:8000/v1" }
    if (-not $Model) { $Model = $ProfileData.Alias }
  }
  "lmstudio" {
    if (-not $BaseUrl) { $BaseUrl = "http://127.0.0.1:1234/v1" }
    if (-not $Model) { $Model = $ProfileData.Alias }
  }
  "openai-compatible" {
    if (-not $BaseUrl) { $BaseUrl = "http://127.0.0.1:8000/v1" }
    if (-not $Model) { $Model = $ProfileData.Alias }
  }
  default { throw "Unknown LOCAL_BACKEND: $Backend" }
}

$ProviderId = if ($env:LOCAL_OPENCODE_PROVIDER_ID) { $env:LOCAL_OPENCODE_PROVIDER_ID } else { "local" }
$ApiKey = if ($env:LOCAL_API_KEY) { $env:LOCAL_API_KEY } else { "local-dev-token" }
$Config = @{
  '$schema' = 'https://opencode.ai/config.json'
  model = "$ProviderId/$Model"
  provider = @{
    $ProviderId = @{
      npm = '@ai-sdk/openai-compatible'
      name = 'Local OpenAI-compatible'
      options = @{
        baseURL = $BaseUrl
        apiKey = $ApiKey
      }
      models = @{
        $Model = @{
          name = $ProfileData.Display
        }
      }
    }
  }
}
$ConfigJson = $Config | ConvertTo-Json -Depth 10

if ($Print) {
  "profile=$Profile"
  "name=$($ProfileData.Display)"
  "backend=$Backend"
  "base_url=$BaseUrl"
  "model=$Model"
  "provider=$ProviderId"
  "opencode_selector=$ProviderId/$Model"
  $ConfigJson
  exit 0
}

$env:OPENCODE_CONFIG_CONTENT = $ConfigJson

if ($env:LOCAL_OPENCODE_BIN) {
  & $env:LOCAL_OPENCODE_BIN @OpenCodeArgs
  exit $LASTEXITCODE
}

$SourceCli = Join-Path $Root "packages/opencode/src/index.ts"
if ((Test-Path $SourceCli) -and (Get-Command bun -ErrorAction SilentlyContinue)) {
  & bun run --cwd (Join-Path $Root "packages/opencode") --conditions=browser ./src/index.ts @OpenCodeArgs
  exit $LASTEXITCODE
}

& opencode @OpenCodeArgs
