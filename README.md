# Multi-Language Testing & Linting Tool

A Docker-based multi-language testing and linting tool optimized for MCP (Model Context Protocol) integration. Supports Python (with Ruff!), JavaScript, TypeScript, Go, Rust, Shell, Docker, Markdown, YAML, and JSON.

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
docker pull ghcr.io/jfriisj/multi-lint:latest
```

### Build Locally

```bash
docker build -t multi-lint .
```

### Basic Usage

```bash
# List all available tools
docker run --rm multi-lint --stdin <<< '{"action": "list"}'

# Run Ruff on Python code
docker run --rm -v $(pwd):/workspace multi-lint --stdin <<< '{
  "action": "run",
  "language": "python",
  "tool": "ruff",
  "path": "/workspace"
}'

# Run all Python tools
docker run --rm -v $(pwd):/workspace multi-lint --stdin <<< '{
  "action": "run_suite",
  "language": "python",
  "path": "/workspace"
}'

# Auto-fix with Ruff
docker run --rm -v $(pwd):/workspace multi-lint --stdin <<< '{
  "action": "run",
  "language": "python",
  "tool": "ruff",
  "path": "/workspace",
  "fix": true
}'
```

### Using the CLI Wrapper

```bash
# List tools
docker run --rm multi-lint lint list

# Run specific tool
docker run --rm -v $(pwd):/workspace multi-lint lint run python ruff /workspace

# Run all tools for a language
docker run --rm -v $(pwd):/workspace multi-lint lint suite python /workspace
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

### JSON API

The tool accepts JSON input via stdin:

```json
{
  "action": "run|run_suite|list",
  "language": "python|javascript|go|rust|...",
  "tool": "ruff|eslint|clippy|...",
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