# Multi-Lint: Infrastructure as Code Tools
# Focused image for Terraform, Kubernetes, Ansible, and CloudFormation tools
# Published as: ghcr.io/jfriisj/multi-lint-infrastructure

FROM python:3.12-slim

# Tool versions
ENV TFLINT_VERSION=0.52.0 \
    TFSEC_VERSION=1.28.10 \
    KUBEVAL_VERSION=0.16.1 \
    KUBESCORE_VERSION=1.18.0 \
    ANSIBLE_LINT_VERSION=24.9.2 \
    CFNLINT_VERSION=1.14.1

ENV MCP_SERVER_PORT=3000

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Python-based IaC tools (avoiding conflicts by using compatible versions)
RUN pip install --no-cache-dir \
    cfn-lint==${CFNLINT_VERSION} \
    ansible-lint==${ANSIBLE_LINT_VERSION} \
    yamllint==1.35.1 \
    && pip cache purge

# Install TFLint
RUN wget -qO /tmp/tflint.zip "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip" && \
    cd /tmp && unzip -q tflint.zip && \
    mv tflint /usr/local/bin/ && \
    chmod +x /usr/local/bin/tflint && \
    rm -f /tmp/tflint.zip

# Install TFSec
RUN wget -qO /usr/local/bin/tfsec "https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64" && \
    chmod +x /usr/local/bin/tfsec

# Install Kubeval
RUN wget -qO /tmp/kubeval.tar.gz "https://github.com/instrumenta/kubeval/releases/download/v${KUBEVAL_VERSION}/kubeval-linux-amd64.tar.gz" && \
    cd /tmp && tar -xzf kubeval.tar.gz && \
    mv kubeval /usr/local/bin/ && \
    chmod +x /usr/local/bin/kubeval && \
    rm -f /tmp/kubeval.tar.gz

# Install Kube-Score
RUN wget -qO /tmp/kube-score.tar.gz "https://github.com/zegl/kube-score/releases/download/v${KUBESCORE_VERSION}/kube-score_${KUBESCORE_VERSION}_linux_amd64.tar.gz" && \
    cd /tmp && tar -xzf kube-score.tar.gz && \
    mv kube-score /usr/local/bin/ && \
    chmod +x /usr/local/bin/kube-score && \
    rm -f /tmp/kube-score.tar.gz

# Create MCP server
WORKDIR /app
COPY mcp.json /app/mcp.json
COPY --chmod=755 <<'EOF' /app/mcp-tool-server.py
#!/usr/bin/env python3
"""
MCP-Compatible Infrastructure as Code Linting Tool Server
Provides unified interface for Terraform, Kubernetes, Ansible, and CloudFormation tools
"""
import json
import subprocess
import sys
from typing import Dict, Optional

TOOL_REGISTRY = {
    "terraform": {
        "tflint": {"cmd": "tflint", "fix": "tflint --fix", "config": "--config"},
        "tfsec": {"cmd": "tfsec", "fix": None, "config": None},
    },
    "kubernetes": {
        "kubeval": {"cmd": "kubeval", "fix": None, "config": None},
        "kube-score": {"cmd": "kube-score score", "fix": None, "config": None},
    },
    "ansible": {
        "ansible-lint": {"cmd": "ansible-lint", "fix": None, "config": "-c"},
    },
    "cloudformation": {
        "cfn-lint": {"cmd": "cfn-lint", "fix": None, "config": "--config-file"},
    },
    "yaml": {
        "yamllint": {"cmd": "yamllint", "fix": None, "config": "-c"},
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
        print("Infrastructure as Code Multi-Lint Tool")
        print("Usage: python3 mcp-tool-server.py --stdin")
EOF

# Create CLI wrapper
COPY --chmod=755 <<'EOF' /usr/local/bin/lint
#!/bin/bash
ACTION=${1:-list}
LANGUAGE=${2:-terraform}
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
    echo "Languages: terraform, kubernetes, ansible, cloudformation, yaml"
    echo "Examples:"
    echo "  lint list"
    echo "  lint run terraform tflint /iac"
    echo "  lint suite kubernetes /k8s"
fi
EOF

WORKDIR /workspace
EXPOSE ${MCP_SERVER_PORT}
ENTRYPOINT ["python3", "/app/mcp-tool-server.py"]
CMD ["--stdin"]