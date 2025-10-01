# Multi-Lint: Security Tools
# Focused image for security scanning and vulnerability detection
# Published as: ghcr.io/jfriisj/multi-lint-security

FROM python:3.12-slim

# Tool versions
ENV TRIVY_VERSION=0.56.2 \
    SEMGREP_VERSION=1.93.0 \
    BANDIT_VERSION=1.7.10

ENV MCP_SERVER_PORT=3000

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Python-based security tools (avoiding ruamel.yaml conflicts)
RUN pip install --no-cache-dir \
    semgrep==${SEMGREP_VERSION} \
    bandit[toml]==${BANDIT_VERSION} \
    safety==3.2.7 \
    && pip cache purge

# Install Trivy binary
RUN cd /tmp && \
    wget -qO- "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" | tar -xzC /tmp && \
    mv trivy /usr/local/bin/ && \
    rm -rf /tmp/* && \
    chmod +x /usr/local/bin/trivy

# Create MCP server
WORKDIR /app
COPY mcp.json /app/mcp.json
COPY --chmod=755 <<'EOF' /app/mcp-tool-server.py
#!/usr/bin/env python3
"""
MCP-Compatible Security Scanning Tool Server
Provides unified interface for security and vulnerability scanning tools
"""
import json
import subprocess
import sys
from typing import Dict, Optional

TOOL_REGISTRY = {
    "security": {
        "semgrep": {"cmd": "semgrep --config=auto", "fix": None, "config": "--config"},
        "trivy": {"cmd": "trivy fs", "fix": None, "config": None},
        "bandit": {"cmd": "bandit -r", "fix": None, "config": "-c"},
        "safety": {"cmd": "safety check", "fix": None, "config": None},
    },
    "container": {
        "trivy-image": {"cmd": "trivy image", "fix": None, "config": None},
        "trivy-config": {"cmd": "trivy config", "fix": None, "config": None},
    }
}

def run_tool(language: str, tool: str, path: str, fix: bool = False, config: Optional[str] = None) -> Dict:
    if language not in TOOL_REGISTRY or tool not in TOOL_REGISTRY[language]:
        return {"success": False, "error": f"Tool '{tool}' not available for '{language}'"}
    
    tool_info = TOOL_REGISTRY[language][tool]
    cmd = tool_info["fix"] if fix and tool_info["fix"] else tool_info["cmd"]
    command = cmd.split()
    
    if config and tool_info["config"]:
        command.extend([tool_info["config"], config])
    
    # Special handling for image scanning (path is image name)
    if tool == "trivy-image":
        command.append(path)
    else:
        command.append(path)
    
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=600)  # Longer timeout for security scans
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
    if language not in TOOL_REGISTRY:
        return {"success": False, "error": f"Language '{language}' not supported"}
    
    results = {}
    for tool_name in TOOL_REGISTRY[language].keys():
        results[tool_name] = run_tool(language, tool_name, path, fix)
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
        print("Security Multi-Lint Tool")
        print("Usage: python3 mcp-tool-server.py --stdin")
EOF

# Create CLI wrapper
COPY --chmod=755 <<'EOF' /usr/local/bin/lint
#!/bin/bash
ACTION=${1:-list}
CATEGORY=${2:-security}
TOOL=${3:-}
TARGET=${4:-.}

if [ "$ACTION" = "list" ]; then
    echo '{"action": "list"}' | python3 /app/mcp-tool-server.py --stdin
elif [ "$ACTION" = "suite" ]; then
    echo "{\"action\": \"run_suite\", \"language\": \"$CATEGORY\", \"path\": \"$TARGET\"}" | python3 /app/mcp-tool-server.py --stdin
elif [ "$ACTION" = "run" ]; then
    echo "{\"action\": \"run\", \"language\": \"$CATEGORY\", \"tool\": \"$TOOL\", \"path\": \"$TARGET\"}" | python3 /app/mcp-tool-server.py --stdin
else
    echo "Usage: lint [list|run|suite] [category] [tool] [target]"
    echo "Categories: security, container"
    echo "Examples:"
    echo "  lint list"
    echo "  lint run security semgrep /code"
    echo "  lint run container trivy-image nginx:latest"
    echo "  lint suite security /code"
fi
EOF

WORKDIR /workspace
EXPOSE ${MCP_SERVER_PORT}
ENTRYPOINT ["python3", "/app/mcp-tool-server.py"]
CMD ["--stdin"]