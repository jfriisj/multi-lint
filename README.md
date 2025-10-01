# Multi-Lint: Modular Code Quality Tools

A collection of **focused Docker images** for linting, testing, and code quality analysis across multiple programming languages and technologies. Each image is optimized for specific use cases and published as individual GitHub packages to avoid dependency conflicts.

## 🎯 **Why Modular Images?**

The original monolithic approach suffered from:
- **Dependency conflicts** between tools (e.g., `ruamel.yaml` version conflicts)  
- **Large image sizes** (~1-2GB) with unused tools
- **Complex builds** taking excessive time
- **Maintenance overhead** with interdependent tools

The modular approach provides:
- ✅ **No dependency conflicts** - each image is isolated
- ✅ **Smaller images** - only download what you need (~100-400MB each)
- ✅ **Faster builds** - parallel building and focused updates  
- ✅ **Better maintenance** - independent versioning per tool category

## 🏗️ **Available Images**

| Image | Description | Tools Included | Size |
|-------|-------------|----------------|------|
| **[multi-lint-python](./images/python/)** | Python linting & testing | ruff, black, mypy, pylint, flake8, pytest, vulture, safety | ~200MB |
| **[multi-lint-javascript](./images/javascript/)** | JavaScript/TypeScript tools | eslint, prettier, typescript, jest, stylelint, React/Vue/Angular | ~300MB |
| **[multi-lint-infrastructure](./images/infrastructure/)** | Infrastructure as Code | tflint, tfsec, ansible-lint, kubeval, kube-score, cfn-lint | ~180MB |
| **[multi-lint-security](./images/security/)** | Security scanning | semgrep, trivy, bandit, safety | ~300MB |
| **[multi-lint-unity](./images/unity/)** | Unity C# development | dotnet-format, StyleCop, Unity analyzers, Roslyn tools | ~400MB |
| **[multi-lint-docker](./images/docker/)** | Docker & container tools | hadolint, dive, trivy, container-structure-test, docker-bench | ~150MB |

## Features

✅ **10+ Languages Supported**: Python, JavaScript, TypeScript, Go, Rust, Shell, Docker, Markdown, YAML, JSON
✅ **30+ Tools Included**: Ruff, Black, ESLint, Prettier, Clippy, ShellCheck, Hadolint, and more
✅ **MCP Compatible**: JSON-based interface for AI agent integration
✅ **Easy Configuration**: Customize via Dockerfile ENV variables
✅ **Auto-fix Support**: Many tools support automatic fixing
✅ **GitHub Packages Ready**: Build and publish easily

## Quick Start

### Pull from GitHub Packages

```bash
# Python tools
docker pull ghcr.io/jfriisj/multi-lint-python:latest

# JavaScript/TypeScript tools  
docker pull ghcr.io/jfriisj/multi-lint-javascript:latest

# Unity C# development tools
docker pull ghcr.io/jfriisj/multi-lint-unity:latest

# Infrastructure as Code tools
docker pull ghcr.io/jfriisj/multi-lint-infrastructure:latest

# Security scanning tools
docker pull ghcr.io/jfriisj/multi-lint-security:latest
```

### Build Locally with Docker Compose

```bash
# Build all images
docker compose build

# Build specific image
docker compose build python-lint

# Build Unity development image
docker compose build unity-lint
```

### Basic Usage

```bash
# List all available Python tools
docker compose run python-lint --stdin <<< '{"action": "list"}'

# Run Ruff on Python code
docker compose run python-lint --stdin <<< '{
  "action": "run",
  "language": "python", 
  "tool": "ruff",
  "path": "/workspace"
}'

# Run all Python tools
docker compose run python-lint --stdin <<< '{
  "action": "run_suite",
  "language": "python",
  "path": "/workspace"
}'

# Unity development workflow
docker compose run unity-lint --stdin <<< '{
  "action": "unity_workflow",
  "path": "/workspace",
  "config": "Debug"
}'

# JavaScript/TypeScript linting
docker compose run javascript-lint --stdin <<< '{
  "action": "run_suite",
  "language": "javascript",
  "path": "/workspace"
}'

# Docker tools - Dockerfile audit
docker compose run docker-lint --stdin <<< '{
  "action": "dockerfile_audit",
  "path": "/workspace/Dockerfile"
}'

# Docker image analysis
docker compose run docker-lint --stdin <<< '{
  "action": "image_analysis",
  "path": "myimage:latest"
}'
```

### Using the CLI Wrapper

```bash
# List Python tools
docker compose run python-lint lint list

# Run specific Python tool
docker compose run python-lint lint run python ruff /workspace

# Run all Python tools
docker compose run python-lint lint suite python /workspace

# Unity development workflow
docker compose run unity-lint lint workflow /workspace Debug
```

## Supported Languages & Tools

### Python 🐍
- **Ruff** ⚡ (ultra-fast linter & formatter)
- Black (formatter)
- MyPy (type checking)
- Pylint (linter)
- Flake8 (linter)
- Bandit (security)
- Pytest (testing)
- Coverage (test coverage)
- isort (import sorting)

### JavaScript/TypeScript 📜
- ESLint (linter)
- Prettier (formatter)
- TypeScript Compiler (type checking)
- Jest (testing)
- JSHint (linter)
- Stylelint (CSS linting)

### Go 🐹
- golangci-lint (meta-linter)
- golint (linter)
- gofmt (formatter)
- staticcheck (linter)
- gosec (security)

### Rust 🦀
- Clippy (linter)
- rustfmt (formatter)
- cargo-audit (security)
- cargo-tarpaulin (coverage)

### Shell 🐚
- ShellCheck (linter)
- shfmt (formatter)

### Docker 🐳
- Hadolint (Dockerfile linter)

### Markdown 📝
- markdownlint

### YAML 📋
- yamllint

### JSON 🔧
- jsonlint

### Unity C# 🎮
- **dotnet format** (code formatter)
- **StyleCop.Analyzers** (style analysis)
- **Microsoft.Unity.Analyzers** (Unity-specific rules)
- **Roslynator** (advanced C# analysis)
- **Security scan** (security analysis)
- **EditorConfig** (consistent coding styles)
- **Dependency analysis** (outdated packages)
- **Unit testing** (NUnit/MSTest support)

### Docker & Containers 🐳
- **Hadolint** (Dockerfile linter & best practices)
- **Dive** (Docker image layer analysis & optimization)
- **Trivy** (vulnerability scanning for images, configs & secrets)
- **container-structure-test** (Google's container testing framework)
- **Docker Bench Security** (CIS Docker security benchmark)
- **Multi-stage optimization** (build efficiency analysis)
- **Layer analysis** (size & waste detection)
- **Configuration auditing** (security misconfiguration detection)

## Configuration

### Customize Tool Versions

Edit the Dockerfile ENV section:

```dockerfile
ENV RUFF_VERSION=0.8.4 \
    ESLINT_VERSION=9.15.0 \
    BLACK_VERSION=24.10.0
```

### Enable/Disable Languages

```dockerfile
ENV ENABLE_PYTHON=true \
    ENABLE_JAVASCRIPT=true \
    ENABLE_RUST=false
```

### Custom Configuration Files

Mount your config files:

```bash
docker run --rm \
  -v $(pwd):/workspace \
  -v $(pwd)/custom-ruff.toml:/config/ruff.toml \
  multi-lint --stdin <<< '{
    "action": "run",
    "language": "python",
    "tool": "ruff",
    "path": "/workspace",
    "config": "/config/ruff.toml"
  }'
```

## MCP Integration

### Configuration Files

Each Docker image includes a complete MCP configuration file:

- **Root Registry**: [`mcp.json`](./mcp.json) - Complete server registry
- **Python Tools**: [`images/python/mcp.json`](./images/python/mcp.json) 
- **JavaScript Tools**: [`images/javascript/mcp.json`](./images/javascript/mcp.json)
- **Infrastructure Tools**: [`images/infrastructure/mcp.json`](./images/infrastructure/mcp.json)
- **Security Tools**: [`images/security/mcp.json`](./images/security/mcp.json)
- **Unity Tools**: [`images/unity/mcp.json`](./images/unity/mcp.json)
- **Docker Tools**: [`images/docker/mcp.json`](./images/docker/mcp.json)

### JSON API

The tool accepts JSON input via stdin:

```json
{
  "action": "run|run_suite|list|workflow_name",
  "language": "python|javascript|dockerfile|...",
  "tool": "ruff|eslint|hadolint|...",
  "path": "/workspace",
  "fix": false,
  "config": "/path/to/config"
}
```

### Response Format

```json
{
  "success": true,
  "returncode": 0,
  "stdout": "All checks passed!",
  "stderr": "",
  "command": "ruff check /workspace"
}
```

### Server Discovery

Use the root `mcp.json` to discover all available servers:

```bash
# List all available MCP servers
curl -s https://raw.githubusercontent.com/jfriisj/multi-lint/main/mcp.json | jq '.servers'

# Get specific server configuration
docker compose run python-lint cat /app/mcp.json | jq '.tools'
```

## Publishing to GitHub Packages

### 1. Build and Tag

```bash
docker build -t ghcr.io/jfriisj/multi-lint:latest .
docker build -t ghcr.io/jfriisj/multi-lint:v1.0.0 .
```

### 2. Login to GitHub Container Registry

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u jfriisj --password-stdin
```

### 3. Push

```bash
docker push ghcr.io/jfriisj/multi-lint:latest
docker push ghcr.io/jfriisj/multi-lint:v1.0.0
```

### 4. Make Public (Optional)

Go to: https://github.com/users/jfriisj/packages/container/multi-lint/settings
Set visibility to "Public"

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Lint Code

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Pull linting tool
        run: docker pull ghcr.io/jfriisj/multi-lint:latest
      
      - name: Run Python linting
        run: |
          docker run --rm -v ${{ github.workspace }}:/workspace \
            ghcr.io/jfriisj/multi-lint:latest --stdin <<< '{
              "action": "run_suite",
              "language": "python",
              "path": "/workspace"
            }'
```

## Advanced Usage

### Run Multiple Languages

```bash
#!/bin/bash
LANGUAGES=("python" "javascript" "shell")

for lang in "${LANGUAGES[@]}"; do
  echo "Running $lang suite..."
  docker run --rm -v $(pwd):/workspace multi-lint --stdin <<< "{
    \"action\": \"run_suite\",
    \"language\": \"$lang\",
    \"path\": \"/workspace\"
  }"
done
```

### Health Check

```bash
docker run --rm multi-lint healthcheck
```

## Troubleshooting

### Tool Not Found

Check if the language is enabled in the Dockerfile:
```dockerfile
ENV ENABLE_RUST=true
```

### Permission Issues

Ensure the workspace directory is readable:
```bash
docker run --rm -v $(pwd):/workspace:ro multi-lint ...
```

### Custom Python Packages

Extend the Dockerfile:
```dockerfile
FROM ghcr.io/jfriisj/multi-lint:latest
RUN pip install --no-cache-dir your-custom-tool
```

## Why Ruff?

Ruff is **10-100x faster** than traditional Python linters:
- Replaces Flake8, isort, pydocstyle, pyupgrade, and more
- Written in Rust for maximum performance
- Drop-in replacement for existing tools
- Actively maintained by Astral

## Contributing

Feel free to open issues or PRs to add more tools or languages!

## License

MIT License - See LICENSE file for details