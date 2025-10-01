# Multi-Language Testing & Linting Tool
# Optimized for MCP (Model Context Protocol) integration
FROM python:3.12-slim

# ============================================================================
# CONFIGURATION SECTION - Easily customize tool versions here
# ============================================================================
ENV RUFF_VERSION=0.8.4 \
    ESLINT_VERSION=9.15.0 \
    PRETTIER_VERSION=3.4.2 \
    BLACK_VERSION=24.10.0 \
    MYPY_VERSION=1.13.0 \
    PYLINT_VERSION=3.3.1 \
    FLAKE8_VERSION=7.1.1 \
    SHELLCHECK_VERSION=0.10.0 \
    HADOLINT_VERSION=2.12.0 \
    MARKDOWNLINT_VERSION=0.43.0 \
    NODE_VERSION=20 \
    GO_VERSION=1.22.0 \
    RUST_VERSION=stable \
    # Additional Python Tools \
    VULTURE_VERSION=2.11 \
    PYRIGHT_VERSION=1.1.380 \
    PYFLAKES_VERSION=3.2.0 \
    SAFETY_VERSION=3.2.7 \
    # Infrastructure as Code Tools \
    TFLINT_VERSION=0.52.0 \
    TFSEC_VERSION=1.28.10 \
    CFNLINT_VERSION=1.14.1 \
    ANSIBLE_LINT_VERSION=24.9.2 \
    KUBEVAL_VERSION=0.16.1 \
    KUBESCORE_VERSION=1.18.0 \
    # Web Technologies \
    HTML5VALIDATOR_VERSION=0.4.2 \
    ESLINT_PLUGIN_REACT_VERSION=7.37.2 \
    ESLINT_PLUGIN_VUE_VERSION=9.28.0 \
    ANGULAR_ESLINT_VERSION=18.4.1 \
    SASS_VERSION=1.80.6 \
    # Security Tools \
    SEMGREP_VERSION=1.93.0 \
    TRIVY_VERSION=0.56.2 \
    # Config File Tools \
    TAPLO_VERSION=0.9.3

# Language-specific tool selections (ON/OFF)
ENV ENABLE_PYTHON=true \
    ENABLE_JAVASCRIPT=true \
    ENABLE_TYPESCRIPT=true \
    ENABLE_GO=true \
    ENABLE_RUST=true \
    ENABLE_SHELL=true \
    ENABLE_DOCKER=true \
    ENABLE_MARKDOWN=true \
    ENABLE_YAML=true \
    ENABLE_JSON=true \
    ENABLE_IAC=true \
    ENABLE_WEB_EXTENDED=true \
    ENABLE_SECURITY=true \
    ENABLE_CONFIG_FILES=true

# Default configurations
ENV RUFF_CONFIG=/config/ruff.toml \
    ESLINT_CONFIG=/config/.eslintrc.json \
    PYLINT_CONFIG=/config/.pylintrc \
    MCP_SERVER_PORT=3000

# ============================================================================
# SYSTEM DEPENDENCIES
# ============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    wget \
    ca-certificates \
    build-essential \
    pkg-config \
    libssl-dev \
    xz-utils \
    libxml2-utils \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# PYTHON TOOLS (Ruff, Black, MyPy, Pylint, Flake8, Bandit)
# ============================================================================
RUN if [ "$ENABLE_PYTHON" = "true" ]; then \
    pip install --no-cache-dir \
        ruff==${RUFF_VERSION} \
        black==${BLACK_VERSION} \
        mypy==${MYPY_VERSION} \
        pylint==${PYLINT_VERSION} \
        flake8==${FLAKE8_VERSION} \
        bandit[toml]==1.7.10 \
        pytest==8.3.4 \
        pytest-cov==6.0.0 \
        coverage==7.6.9 \
        isort==5.13.2 \
        autoflake==2.3.1 \
        pycodestyle==2.12.1 \
        pydocstyle==6.3.0 \
        vulture==${VULTURE_VERSION} \
        pyright==${PYRIGHT_VERSION} \
        pyflakes==${PYFLAKES_VERSION} \
        safety==${SAFETY_VERSION}; \
    fi

# ============================================================================
# NODE.JS & JAVASCRIPT/TYPESCRIPT TOOLS
# ============================================================================
RUN if [ "$ENABLE_JAVASCRIPT" = "true" ] || [ "$ENABLE_TYPESCRIPT" = "true" ]; then \
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g \
        eslint@${ESLINT_VERSION} \
        prettier@${PRETTIER_VERSION} \
        typescript@5.7.2 \
        ts-node@10.9.2 \
        @typescript-eslint/parser@8.18.1 \
        @typescript-eslint/eslint-plugin@8.18.1 \
        eslint-config-prettier@9.1.0 \
        jest@29.7.0 \
        stylelint@16.12.0 \
        jshint@2.13.6 \
        standard@17.1.2; \
    fi

# ============================================================================
# GO TOOLS
# ============================================================================
RUN if [ "$ENABLE_GO" = "true" ]; then \
    wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz; \
    fi

ENV PATH="/usr/local/go/bin:${PATH}" \
    GOPATH="/go" \
    GO111MODULE=on

RUN if [ "$ENABLE_GO" = "true" ]; then \
    go install golang.org/x/lint/golint@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.62.2 && \
    go install honnef.co/go/tools/cmd/staticcheck@2024.1.1 && \
    go install github.com/securego/gosec/v2/cmd/gosec@latest; \
    fi

ENV PATH="/go/bin:${PATH}"

# ============================================================================
# RUST TOOLS (Fixed with proper dependencies)
# ============================================================================
RUN if [ "$ENABLE_RUST" = "true" ]; then \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${RUST_VERSION} && \
    . $HOME/.cargo/env && \
    rustup component add clippy rustfmt && \
    cargo install cargo-audit --locked && \
    cargo install cargo-tarpaulin --locked; \
    fi

ENV PATH="/root/.cargo/bin:${PATH}"

# ============================================================================
# SHELL TOOLS
# ============================================================================
RUN if [ "$ENABLE_SHELL" = "true" ]; then \
    wget -qO- "https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz" | tar -xJv && \
    mv "shellcheck-v${SHELLCHECK_VERSION}/shellcheck" /usr/local/bin/ && \
    rm -rf "shellcheck-v${SHELLCHECK_VERSION}" && \
    curl -s https://raw.githubusercontent.com/mvdan/sh/master/cmd/shfmt/shfmt.1.scd | sh -s -- -b /usr/local/bin || \
    (apt-get update && apt-get install -y shfmt && rm -rf /var/lib/apt/lists/*); \
    fi

# ============================================================================
# DOCKER LINTING
# ============================================================================
RUN if [ "$ENABLE_DOCKER" = "true" ]; then \
    wget -qO /usr/local/bin/hadolint "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64" && \
    chmod +x /usr/local/bin/hadolint; \
    fi

# ============================================================================
# MARKDOWN, YAML, JSON TOOLS
# ============================================================================
RUN if [ "$ENABLE_MARKDOWN" = "true" ]; then \
    npm install -g markdownlint-cli@${MARKDOWNLINT_VERSION}; \
    fi

RUN if [ "$ENABLE_YAML" = "true" ]; then \
    pip install --no-cache-dir yamllint==1.35.1; \
    fi

RUN if [ "$ENABLE_JSON" = "true" ]; then \
    npm install -g jsonlint@1.6.3; \
    fi

# ============================================================================
# INFRASTRUCTURE AS CODE TOOLS
# ============================================================================
RUN if [ "$ENABLE_IAC" = "true" ]; then \
    # TFLint \
    wget -qO- "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip" | \
    busybox unzip -d /tmp - && mv /tmp/tflint /usr/local/bin/ && \
    # TFSec \
    wget -qO /usr/local/bin/tfsec "https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64" && \
    chmod +x /usr/local/bin/tfsec && \
    # CFN-Lint \
    pip install --no-cache-dir cfn-lint==${CFNLINT_VERSION} && \
    # Ansible-Lint \
    pip install --no-cache-dir ansible-lint==${ANSIBLE_LINT_VERSION} && \
    # Kubeval \
    wget -qO- "https://github.com/instrumenta/kubeval/releases/download/v${KUBEVAL_VERSION}/kubeval-linux-amd64.tar.gz" | \
    tar -xzC /tmp && mv /tmp/kubeval /usr/local/bin/ && \
    # Kube-Score \
    wget -qO /usr/local/bin/kube-score "https://github.com/zegl/kube-score/releases/download/v${KUBESCORE_VERSION}/kube-score_${KUBESCORE_VERSION}_linux_amd64.tar.gz" && \
    tar -xzf /usr/local/bin/kube-score -C /tmp && mv /tmp/kube-score /usr/local/bin/ && rm /usr/local/bin/kube-score; \
    fi

# Fix kube-score installation
RUN if [ "$ENABLE_IAC" = "true" ]; then \
    wget -qO- "https://github.com/zegl/kube-score/releases/download/v${KUBESCORE_VERSION}/kube-score_${KUBESCORE_VERSION}_linux_amd64.tar.gz" | \
    tar -xzC /tmp && mv /tmp/kube-score /usr/local/bin/; \
    fi

# ============================================================================
# EXTENDED WEB TECHNOLOGIES
# ============================================================================
RUN if [ "$ENABLE_WEB_EXTENDED" = "true" ]; then \
    # HTML5 Validator \
    pip install --no-cache-dir html5validator==${HTML5VALIDATOR_VERSION} && \
    # React, Vue, Angular ESLint plugins \
    npm install -g \
        eslint-plugin-react@${ESLINT_PLUGIN_REACT_VERSION} \
        eslint-plugin-vue@${ESLINT_PLUGIN_VUE_VERSION} \
        @angular-eslint/eslint-plugin@${ANGULAR_ESLINT_VERSION} \
        @angular-eslint/template-parser@${ANGULAR_ESLINT_VERSION} \
        sass@${SASS_VERSION} \
        stylelint-scss@6.8.1; \
    fi

# ============================================================================
# SECURITY & VULNERABILITY SCANNING
# ============================================================================
RUN if [ "$ENABLE_SECURITY" = "true" ]; then \
    # Semgrep \
    pip install --no-cache-dir semgrep==${SEMGREP_VERSION} && \
    # Trivy \
    wget -qO- "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" | \
    tar -xzC /tmp && mv /tmp/trivy /usr/local/bin/; \
    fi

# ============================================================================
# CONFIGURATION FILE TOOLS
# ============================================================================
RUN if [ "$ENABLE_CONFIG_FILES" = "true" ]; then \
    # TOML linting with Taplo \
    npm install -g @taplo/cli@${TAPLO_VERSION}; \
    fi

# ============================================================================
# MCP SERVER & ORCHESTRATION SCRIPT
# ============================================================================
WORKDIR /app

# Create the MCP-compatible tool wrapper
COPY --chmod=755 <<'EOF' /app/mcp-tool-server.py
#!/usr/bin/env python3
"""
MCP-Compatible Multi-Language Testing & Linting Tool Server
Provides a unified interface for all linting and testing tools
"""
import json
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional
import os

TOOL_REGISTRY = {
    "python": {
        "ruff": {"cmd": "ruff check", "fix": "ruff check --fix", "config": "--config"},
        "black": {"cmd": "black --check", "fix": "black", "config": "--config"},
        "mypy": {"cmd": "mypy", "fix": None, "config": "--config-file"},
        "pylint": {"cmd": "pylint", "fix": None, "config": "--rcfile"},
        "flake8": {"cmd": "flake8", "fix": None, "config": "--config"},
        "bandit": {"cmd": "bandit -r", "fix": None, "config": "-c"},
        "pytest": {"cmd": "pytest", "fix": None, "config": "-c"},
        "isort": {"cmd": "isort --check", "fix": "isort", "config": "--settings-file"},
        "vulture": {"cmd": "vulture", "fix": None, "config": None},
        "pyright": {"cmd": "pyright", "fix": None, "config": None},
        "pyflakes": {"cmd": "pyflakes", "fix": None, "config": None},
        "safety": {"cmd": "safety check", "fix": None, "config": None},
    },
    "javascript": {
        "eslint": {"cmd": "eslint", "fix": "eslint --fix", "config": "-c"},
        "prettier": {"cmd": "prettier --check", "fix": "prettier --write", "config": "--config"},
        "jshint": {"cmd": "jshint", "fix": None, "config": "--config"},
        "jest": {"cmd": "jest", "fix": None, "config": "--config"},
        "stylelint": {"cmd": "stylelint", "fix": "stylelint --fix", "config": "--config"},
    },
    "typescript": {
        "eslint": {"cmd": "eslint", "fix": "eslint --fix", "config": "-c"},
        "prettier": {"cmd": "prettier --check", "fix": "prettier --write", "config": "--config"},
        "tsc": {"cmd": "tsc --noEmit", "fix": None, "config": "-p"},
        "stylelint": {"cmd": "stylelint", "fix": "stylelint --fix", "config": "--config"},
    },
    "go": {
        "golint": {"cmd": "golint", "fix": None, "config": None},
        "golangci-lint": {"cmd": "golangci-lint run", "fix": "golangci-lint run --fix", "config": "-c"},
        "gofmt": {"cmd": "gofmt -l", "fix": "gofmt -w", "config": None},
        "staticcheck": {"cmd": "staticcheck", "fix": None, "config": None},
        "gosec": {"cmd": "gosec", "fix": None, "config": "-conf"},
    },
    "rust": {
        "clippy": {"cmd": "cargo clippy -- -D warnings", "fix": "cargo clippy --fix", "config": None},
        "rustfmt": {"cmd": "cargo fmt -- --check", "fix": "cargo fmt", "config": None},
        "cargo-audit": {"cmd": "cargo audit", "fix": None, "config": None},
    },
    "shell": {
        "shellcheck": {"cmd": "shellcheck", "fix": None, "config": None},
        "shfmt": {"cmd": "shfmt -d", "fix": "shfmt -w", "config": None},
    },
    "docker": {
        "hadolint": {"cmd": "hadolint", "fix": None, "config": "--config"},
    },
    "markdown": {
        "markdownlint": {"cmd": "markdownlint", "fix": "markdownlint --fix", "config": "-c"},
    },
    "yaml": {
        "yamllint": {"cmd": "yamllint", "fix": None, "config": "-c"},
    },
    "json": {
        "jsonlint": {"cmd": "jsonlint -q", "fix": None, "config": None},
    },
    "iac": {
        "tflint": {"cmd": "tflint", "fix": "tflint --fix", "config": "--config"},
        "tfsec": {"cmd": "tfsec", "fix": None, "config": None},
        "cfn-lint": {"cmd": "cfn-lint", "fix": None, "config": "--config-file"},
        "ansible-lint": {"cmd": "ansible-lint", "fix": None, "config": "-c"},
        "kubeval": {"cmd": "kubeval", "fix": None, "config": None},
        "kube-score": {"cmd": "kube-score score", "fix": None, "config": None},
    },
    "web": {
        "html5validator": {"cmd": "html5validator", "fix": None, "config": None},
        "eslint-react": {"cmd": "eslint --ext .jsx,.tsx", "fix": "eslint --ext .jsx,.tsx --fix", "config": "-c"},
        "eslint-vue": {"cmd": "eslint --ext .vue", "fix": "eslint --ext .vue --fix", "config": "-c"},
        "eslint-angular": {"cmd": "eslint --ext .ts,.html", "fix": "eslint --ext .ts,.html --fix", "config": "-c"},
        "sass": {"cmd": "sass --check", "fix": None, "config": None},
        "stylelint-scss": {"cmd": "stylelint **/*.scss", "fix": "stylelint **/*.scss --fix", "config": "--config"},
    },
    "security": {
        "semgrep": {"cmd": "semgrep --config=auto", "fix": None, "config": "--config"},
        "trivy": {"cmd": "trivy fs", "fix": None, "config": None},
    },
    "config": {
        "xmllint": {"cmd": "xmllint --noout", "fix": None, "config": None},
        "taplo": {"cmd": "taplo check", "fix": "taplo format", "config": None},
    },
}

def run_tool(language: str, tool: str, path: str, fix: bool = False, config: Optional[str] = None) -> Dict:
    """Run a specific linting/testing tool"""
    if language not in TOOL_REGISTRY:
        return {"success": False, "error": f"Language '{language}' not supported"}
    
    if tool not in TOOL_REGISTRY[language]:
        return {"success": False, "error": f"Tool '{tool}' not available for '{language}'"}
    
    tool_info = TOOL_REGISTRY[language][tool]
    cmd = tool_info["fix"] if fix and tool_info["fix"] else tool_info["cmd"]
    
    # Build command
    command = cmd.split()
    
    # Add config if provided
    if config and tool_info["config"]:
        command.extend([tool_info["config"], config])
    elif config and not tool_info["config"]:
        print(f"Warning: {tool} doesn't support custom config", file=sys.stderr)
    
    command.append(path)
    
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=300
        )
        
        return {
            "success": result.returncode == 0,
            "returncode": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "command": " ".join(command)
        }
    except subprocess.TimeoutExpired:
        return {"success": False, "error": "Tool execution timed out"}
    except FileNotFoundError:
        return {"success": False, "error": f"Tool '{tool}' not found in PATH"}
    except Exception as e:
        return {"success": False, "error": str(e)}

def run_language_suite(language: str, path: str, fix: bool = False) -> Dict:
    """Run all available tools for a language"""
    results = {}
    if language not in TOOL_REGISTRY:
        return {"success": False, "error": f"Language '{language}' not supported"}
    
    for tool_name in TOOL_REGISTRY[language].keys():
        results[tool_name] = run_tool(language, tool_name, path, fix)
    
    return {"success": True, "results": results}

def list_tools() -> Dict:
    """List all available tools"""
    return {"success": True, "tools": TOOL_REGISTRY}

def mcp_handler(request: Dict) -> Dict:
    """Handle MCP-style requests"""
    action = request.get("action", "")
    
    if action == "list":
        return list_tools()
    elif action == "run":
        return run_tool(
            request.get("language", ""),
            request.get("tool", ""),
            request.get("path", "."),
            request.get("fix", False),
            request.get("config")
        )
    elif action == "run_suite":
        return run_language_suite(
            request.get("language", ""),
            request.get("path", "."),
            request.get("fix", False)
        )
    else:
        return {"success": False, "error": f"Unknown action: {action}"}

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--stdin":
        # MCP mode: read JSON from stdin
        try:
            request = json.load(sys.stdin)
            response = mcp_handler(request)
            print(json.dumps(response, indent=2))
        except json.JSONDecodeError as e:
            print(json.dumps({"success": False, "error": f"Invalid JSON: {e}"}))
    else:
        # CLI mode
        print("Multi-Language Testing & Linting Tool")
        print("Usage: mcp-tool-server.py --stdin")
        print("\nExample JSON input:")
        print(json.dumps({
            "action": "run",
            "language": "python",
            "tool": "ruff",
            "path": ".",
            "fix": False
        }, indent=2))
EOF

# Create default configuration files
RUN mkdir -p /config

# Ruff configuration
COPY <<'EOF' /config/ruff.toml
# Ruff configuration for multi-language tool
line-length = 88
target-version = "py312"

[lint]
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # pyflakes
    "I",   # isort
    "N",   # pep8-naming
    "UP",  # pyupgrade
    "B",   # flake8-bugbear
    "C4",  # flake8-comprehensions
    "SIM", # flake8-simplify
]
ignore = []

[lint.per-file-ignores]
"__init__.py" = ["F401"]
EOF

# ESLint configuration
COPY <<'EOF' /config/.eslintrc.json
{
  "env": {
    "browser": true,
    "es2021": true,
    "node": true
  },
  "extends": [
    "eslint:recommended",
    "prettier"
  ],
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module"
  },
  "rules": {
    "no-console": "warn",
    "no-unused-vars": "warn"
  }
}
EOF

# Pylint configuration
COPY <<'EOF' /config/.pylintrc
[MASTER]
max-line-length=88
disable=C0114,C0115,C0116
EOF

# Create CLI wrapper for easier usage
COPY --chmod=755 <<'EOF' /usr/local/bin/lint
#!/bin/bash
# Simple CLI wrapper for the MCP tool server

ACTION=${1:-list}
LANGUAGE=${2:-}
TOOL=${3:-}
PATH_TO_CHECK=${4:-.}

if [ "$ACTION" = "list" ]; then
    echo '{"action": "list"}' | python3 /app/mcp-tool-server.py --stdin
elif [ "$ACTION" = "suite" ]; then
    echo "{\"action\": \"run_suite\", \"language\": \"$LANGUAGE\", \"path\": \"$PATH_TO_CHECK\"}" | python3 /app/mcp-tool-server.py --stdin
elif [ "$ACTION" = "run" ]; then
    echo "{\"action\": \"run\", \"language\": \"$LANGUAGE\", \"tool\": \"$TOOL\", \"path\": \"$PATH_TO_CHECK\"}" | python3 /app/mcp-tool-server.py --stdin
else
    echo "Usage: lint [list|run|suite] [language] [tool] [path]"
    echo "Examples:"
    echo "  lint list"
    echo "  lint run python ruff /code"
    echo "  lint suite python /code"
fi
EOF

# Health check script
COPY --chmod=755 <<'EOF' /usr/local/bin/healthcheck
#!/bin/bash
echo "Checking installed tools..."
tools=("ruff" "black" "eslint" "prettier" "go" "cargo" "shellcheck" "hadolint")
for tool in "${tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        echo "✓ $tool"
    else
        echo "✗ $tool (disabled or not installed)"
    fi
done
EOF

WORKDIR /workspace

# Expose port for potential HTTP MCP server
EXPOSE ${MCP_SERVER_PORT}

ENTRYPOINT ["python3", "/app/mcp-tool-server.py"]
CMD ["--stdin"]