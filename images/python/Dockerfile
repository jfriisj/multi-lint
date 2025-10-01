# Multi-Lint: Python Tools
# Focused image for Python linting, testing, and code quality tools
# Published as: ghcr.io/jfriisj/multi-lint-python

FROM python:3.12-slim

# Tool versions
ENV RUFF_VERSION=0.8.4 \
    BLACK_VERSION=24.10.0 \
    MYPY_VERSION=1.13.0 \
    PYLINT_VERSION=3.3.1 \
    FLAKE8_VERSION=7.1.1 \
    VULTURE_VERSION=2.11 \
    PYFLAKES_VERSION=3.2.0 \
    SAFETY_VERSION=3.2.7

ENV MCP_SERVER_PORT=3000

# Install Python tools (avoiding conflicting packages)
RUN pip install --no-cache-dir \
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
    pyflakes==${PYFLAKES_VERSION} \
    safety==${SAFETY_VERSION} \
    && pip cache purge

# Create MCP server
WORKDIR /app
COPY mcp.json /app/mcp.json
COPY --chmod=755 <<'EOF' /app/mcp-tool-server.py
#!/usr/bin/env python3
"""
MCP-Compatible Python Linting & Testing Tool Server
Provides unified interface for Python code quality tools
"""
import json
import subprocess
import sys
from typing import Dict, Optional

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
        "pyflakes": {"cmd": "pyflakes", "fix": None, "config": None},
        "safety": {"cmd": "safety check", "fix": None, "config": None},
        "coverage": {"cmd": "coverage run -m pytest", "fix": None, "config": None},
        "autoflake": {"cmd": "autoflake --check", "fix": "autoflake --in-place", "config": None},
    }
}

def run_tool(language: str, tool: str, path: str, fix: bool = False, config: Optional[str] = None) -> Dict:
    if language != "python" or tool not in TOOL_REGISTRY["python"]:
        return {"success": False, "error": f"Tool '{tool}' not available for '{language}'"}
    
    tool_info = TOOL_REGISTRY["python"][tool]
    cmd = tool_info["fix"] if fix and tool_info["fix"] else tool_info["cmd"]
    command = cmd.split()
    
    if config and tool_info["config"]:
        command.extend([tool_info["config"], config])
    
    command.append(path)
    
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=300)
        return {
            "success": result.returncode == 0,
            "returncode": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "command": " ".join(command)
        }
    except Exception as e:
        return {"success": False, "error": str(e)}

def run_language_suite(language: str, path: str, fix: bool = False) -> Dict:
    if language != "python":
        return {"success": False, "error": f"Language '{language}' not supported"}
    
    results = {}
    for tool_name in TOOL_REGISTRY["python"].keys():
        results[tool_name] = run_tool("python", tool_name, path, fix)
    return {"success": True, "results": results}

def mcp_handler(request: Dict) -> Dict:
    action = request.get("action", "")
    if action == "list":
        return {"success": True, "tools": TOOL_REGISTRY}
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
        try:
            request = json.load(sys.stdin)
            response = mcp_handler(request)
            print(json.dumps(response, indent=2))
        except json.JSONDecodeError as e:
            print(json.dumps({"success": False, "error": f"Invalid JSON: {e}"}))
    else:
        print("Python Multi-Lint Tool")
        print("Usage: python mcp-tool-server.py --stdin")
EOF

# Create CLI wrapper
COPY --chmod=755 <<'EOF' /usr/local/bin/lint
#!/bin/bash
ACTION=${1:-list}
TOOL=${2:-}
PATH_TO_CHECK=${3:-.}

if [ "$ACTION" = "list" ]; then
    echo '{"action": "list"}' | python3 /app/mcp-tool-server.py --stdin
elif [ "$ACTION" = "suite" ]; then
    echo "{\"action\": \"run_suite\", \"language\": \"python\", \"path\": \"$PATH_TO_CHECK\"}" | python3 /app/mcp-tool-server.py --stdin
elif [ "$ACTION" = "run" ]; then
    echo "{\"action\": \"run\", \"language\": \"python\", \"tool\": \"$TOOL\", \"path\": \"$PATH_TO_CHECK\"}" | python3 /app/mcp-tool-server.py --stdin
else
    echo "Usage: lint [list|run|suite] [tool] [path]"
    echo "Examples:"
    echo "  lint list"
    echo "  lint run ruff /code"
    echo "  lint suite /code"
fi
EOF

WORKDIR /workspace
EXPOSE ${MCP_SERVER_PORT}
ENTRYPOINT ["python3", "/app/mcp-tool-server.py"]
CMD ["--stdin"]