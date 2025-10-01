# Multi-Lint: JavaScript/TypeScript Tools
# Focused image for JavaScript, TypeScript, and web development tools
# Published as: ghcr.io/jfriisj/multi-lint-javascript

FROM node:20-slim

# Tool versions
ENV ESLINT_VERSION=9.15.0 \
    PRETTIER_VERSION=3.4.2 \
    TYPESCRIPT_VERSION=5.7.2 \
    STYLELINT_VERSION=16.12.0

ENV MCP_SERVER_PORT=3000

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Install JavaScript/TypeScript tools
RUN npm install -g --no-optional \
    eslint@${ESLINT_VERSION} \
    prettier@${PRETTIER_VERSION} \
    typescript@${TYPESCRIPT_VERSION} \
    ts-node@10.9.2 \
    @typescript-eslint/parser@8.18.1 \
    @typescript-eslint/eslint-plugin@8.18.1 \
    eslint-config-prettier@9.1.0 \
    jest@29.7.0 \
    stylelint@${STYLELINT_VERSION} \
    jshint@2.13.6 \
    standard@17.1.2 \
    eslint-plugin-react@7.37.2 \
    eslint-plugin-vue@9.28.0 \
    @angular-eslint/eslint-plugin@18.4.1 \
    sass@1.80.6 \
    stylelint-scss@6.8.1 \
    && npm cache clean --force

# Create MCP server
WORKDIR /app
COPY mcp.json /app/mcp.json
COPY --chmod=755 <<'EOF' /app/mcp-tool-server.py
#!/usr/bin/env python3
"""
MCP-Compatible JavaScript/TypeScript Linting Tool Server
Provides unified interface for JavaScript and TypeScript tools
"""
import json
import subprocess
import sys
from typing import Dict, Optional

TOOL_REGISTRY = {
    "javascript": {
        "eslint": {"cmd": "eslint", "fix": "eslint --fix", "config": "-c"},
        "prettier": {"cmd": "prettier --check", "fix": "prettier --write", "config": "--config"},
        "jshint": {"cmd": "jshint", "fix": None, "config": "--config"},
        "jest": {"cmd": "jest", "fix": None, "config": "--config"},
        "stylelint": {"cmd": "stylelint", "fix": "stylelint --fix", "config": "--config"},
        "standard": {"cmd": "standard", "fix": "standard --fix", "config": None},
    },
    "typescript": {
        "eslint": {"cmd": "eslint", "fix": "eslint --fix", "config": "-c"},
        "prettier": {"cmd": "prettier --check", "fix": "prettier --write", "config": "--config"},
        "tsc": {"cmd": "tsc --noEmit", "fix": None, "config": "-p"},
        "stylelint": {"cmd": "stylelint", "fix": "stylelint --fix", "config": "--config"},
    },
    "web": {
        "eslint-react": {"cmd": "eslint --ext .jsx,.tsx", "fix": "eslint --ext .jsx,.tsx --fix", "config": "-c"},
        "eslint-vue": {"cmd": "eslint --ext .vue", "fix": "eslint --ext .vue --fix", "config": "-c"},
        "eslint-angular": {"cmd": "eslint --ext .ts,.html", "fix": "eslint --ext .ts,.html --fix", "config": "-c"},
        "sass": {"cmd": "sass --check", "fix": None, "config": None},
        "stylelint-scss": {"cmd": "stylelint **/*.scss", "fix": "stylelint **/*.scss --fix", "config": "--config"},
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
        print("JavaScript/TypeScript Multi-Lint Tool")
        print("Usage: python3 mcp-tool-server.py --stdin")
EOF

# Create CLI wrapper
COPY --chmod=755 <<'EOF' /usr/local/bin/lint
#!/bin/bash
ACTION=${1:-list}
LANGUAGE=${2:-javascript}
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
    echo "Languages: javascript, typescript, web"
    echo "Examples:"
    echo "  lint list"
    echo "  lint run javascript eslint /code"
    echo "  lint suite typescript /code"
fi
EOF

WORKDIR /workspace
EXPOSE ${MCP_SERVER_PORT}
ENTRYPOINT ["python3", "/app/mcp-tool-server.py"]
CMD ["--stdin"]