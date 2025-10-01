# Multi-Lint: Docker Tools
# Focused image for Dockerfile linting, security scanning, and best practices
# Published as: ghcr.io/jfriisj/multi-lint-docker

FROM alpine:3.19

# Tool versions
ENV HADOLINT_VERSION=v2.12.0 \
    DIVE_VERSION=0.12.0 \
    TRIVY_VERSION=0.58.0 \
    DOCKERFILE_LINT_VERSION=0.3.1 \
    CONTAINER_STRUCTURE_TEST_VERSION=1.16.0 \
    DOCKER_BENCH_VERSION=1.5.0

ENV MCP_SERVER_PORT=3000

# Install system dependencies
RUN apk add --no-cache \
    wget \
    curl \
    tar \
    gzip \
    python3 \
    py3-pip \
    bash \
    git \
    jq \
    ca-certificates

# Install Hadolint (Dockerfile linter)
RUN wget -qO /usr/local/bin/hadolint \
        "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-x86_64" && \
    chmod +x /usr/local/bin/hadolint

# Install Dive (Docker image layer analyzer)
RUN wget -qO /tmp/dive.tar.gz \
        "https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.tar.gz" && \
    tar -xzf /tmp/dive.tar.gz -C /tmp && \
    mv /tmp/dive /usr/local/bin/dive && \
    chmod +x /usr/local/bin/dive && \
    rm -rf /tmp/dive.tar.gz

# Install Trivy (vulnerability scanner)
RUN wget -qO /tmp/trivy.tar.gz \
        "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" && \
    tar -xzf /tmp/trivy.tar.gz -C /tmp && \
    mv /tmp/trivy /usr/local/bin/trivy && \
    chmod +x /usr/local/bin/trivy && \
    rm -rf /tmp/trivy.tar.gz

# Note: dockerfile-lint removed as Hadolint provides comprehensive Dockerfile linting

# Install container-structure-test (Google's container testing framework)
RUN wget -qO /usr/local/bin/container-structure-test \
        "https://storage.googleapis.com/container-structure-test/v${CONTAINER_STRUCTURE_TEST_VERSION}/container-structure-test-linux-amd64" && \
    chmod +x /usr/local/bin/container-structure-test

# Install Docker Bench Security
RUN wget -qO /tmp/docker-bench.tar.gz \
        "https://github.com/docker/docker-bench-security/archive/refs/tags/v${DOCKER_BENCH_VERSION}.tar.gz" && \
    tar -xzf /tmp/docker-bench.tar.gz -C /tmp && \
    mv "/tmp/docker-bench-security-${DOCKER_BENCH_VERSION}" /opt/docker-bench-security && \
    ln -s /opt/docker-bench-security/docker-bench-security.sh /usr/local/bin/docker-bench-security && \
    chmod +x /opt/docker-bench-security/docker-bench-security.sh && \
    rm -rf /tmp/docker-bench.tar.gz

# Create MCP server
WORKDIR /app
COPY mcp.json /app/mcp.json
COPY --chmod=755 <<'EOF' /app/mcp-tool-server.py
#!/usr/bin/env python3
"""
MCP-Compatible Docker Tools Server
Provides unified interface for Dockerfile linting, image analysis, and security scanning
"""
import json
import subprocess
import sys
import os
from typing import Dict, Optional

TOOL_REGISTRY = {
    "dockerfile": {
        "hadolint": {"cmd": "hadolint", "fix": None, "config": "--config"},
        "best-practices": {"cmd": "hadolint", "fix": None, "config": "--ignore"},
        "syntax-check": {"cmd": "hadolint --format json", "fix": None, "config": None},
    },
    "image": {
        "dive": {"cmd": "dive --ci", "fix": None, "config": "--highestUserWastedPercent"},
        "trivy-image": {"cmd": "trivy image", "fix": None, "config": "--format"},
        "trivy-fs": {"cmd": "trivy fs", "fix": None, "config": "--format"},
        "structure-test": {"cmd": "container-structure-test test", "fix": None, "config": "--config"},
    },
    "security": {
        "trivy-config": {"cmd": "trivy config", "fix": None, "config": "--format"},
        "trivy-secrets": {"cmd": "trivy fs --scanners secret", "fix": None, "config": "--format"},
        "docker-bench": {"cmd": "docker-bench-security", "fix": None, "config": None},
        "cve-scan": {"cmd": "trivy image --format json", "fix": None, "config": None},
    },
    "analysis": {
        "layer-analysis": {"cmd": "dive --ci --lowestEfficiency", "fix": None, "config": None},
        "size-analysis": {"cmd": "dive --ci --highestWastedBytes", "fix": None, "config": None},
        "dockerfile-complexity": {"cmd": "hadolint --format json", "fix": None, "config": None},
        "multi-stage-check": {"cmd": "hadolint --ignore DL3006", "fix": None, "config": None},
    }
}

def run_tool(language: str, tool: str, path: str, fix: bool = False, config: Optional[str] = None) -> Dict:
    if language not in TOOL_REGISTRY or tool not in TOOL_REGISTRY[language]:
        return {"success": False, "error": f"Tool '{tool}' not available for '{language}'"}
    
    tool_info = TOOL_REGISTRY[language][tool]
    cmd = tool_info["cmd"]
    command = cmd.split()
    
    # Special handling for different tools
    if tool == "hadolint":
        if path.endswith("Dockerfile") or os.path.basename(path) == "Dockerfile":
            command.append(path)
        else:
            # Find Dockerfile in directory
            dockerfile_path = os.path.join(path, "Dockerfile")
            if os.path.exists(dockerfile_path):
                command.append(dockerfile_path)
            else:
                return {"success": False, "error": f"No Dockerfile found in {path}"}
        
        if config:
            command.extend(["--config", config])
            
    elif tool == "dockerfile-lint":
        if path.endswith("Dockerfile") or os.path.basename(path) == "Dockerfile":
            command.extend(["-f", path])
        else:
            dockerfile_path = os.path.join(path, "Dockerfile")
            if os.path.exists(dockerfile_path):
                command.extend(["-f", dockerfile_path])
            else:
                return {"success": False, "error": f"No Dockerfile found in {path}"}
                
    elif tool.startswith("dive"):
        # Dive needs Docker image name or tar file
        if config:
            command.extend([config.split("=")[0], config.split("=")[1]])
        command.append(path)  # path should be image name or tar file
        
    elif tool.startswith("trivy"):
        if tool == "trivy-image":
            command.append(path)  # path should be image name
        elif tool in ["trivy-fs", "trivy-config", "trivy-secrets"]:
            command.append(path)  # path should be directory
        
        if config:
            command.extend(["--format", config])
        else:
            command.extend(["--format", "table"])
            
    elif tool == "structure-test":
        if config:
            command.extend(["--config", config])
        command.extend(["--image", path])  # path should be image name
        
    elif tool == "docker-bench":
        # Docker bench runs system-wide checks
        pass
    else:
        if path != "." and not any(x in tool for x in ["bench", "dive"]):
            command.append(path)
    
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=300,
            cwd=path if os.path.isdir(path) and tool not in ["dive", "trivy-image", "structure-test"] else None
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
    except Exception as e:
        return {"success": False, "error": str(e)}

def run_language_suite(language: str, path: str, fix: bool = False) -> Dict:
    if language not in TOOL_REGISTRY:
        return {"success": False, "error": f"Language '{language}' not supported"}
    
    results = {}
    for tool_name in TOOL_REGISTRY[language].keys():
        results[tool_name] = run_tool(language, tool_name, path, fix)
    return {"success": True, "results": results}

def run_dockerfile_audit(path: str) -> Dict:
    """Run comprehensive Dockerfile audit"""
    audit_steps = [
        ("dockerfile", "hadolint", "Lint Dockerfile"),
        ("dockerfile", "best-practices", "Best practices check"),
        ("security", "trivy-config", "Configuration security scan"),
        ("analysis", "dockerfile-complexity", "Complexity analysis"),
    ]
    
    results = {}
    for category, tool, description in audit_steps:
        print(f"Running: {description}...", file=sys.stderr)
        results[f"{category}_{tool}"] = run_tool(category, tool, path)
    
    return {"success": True, "audit_results": results}

def run_image_analysis(image_name: str) -> Dict:
    """Run comprehensive Docker image analysis"""
    analysis_steps = [
        ("image", "dive", "Layer efficiency analysis"),
        ("image", "trivy-image", "Vulnerability scan"),
        ("security", "cve-scan", "CVE analysis"),
        ("analysis", "layer-analysis", "Layer optimization check"),
    ]
    
    results = {}
    for category, tool, description in analysis_steps:
        print(f"Running: {description}...", file=sys.stderr)
        results[f"{category}_{tool}"] = run_tool(category, tool, image_name)
    
    return {"success": True, "analysis_results": results}

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
    elif action == "dockerfile_audit":
        return run_dockerfile_audit(request.get("path", "."))
    elif action == "image_analysis":
        return run_image_analysis(request.get("path", ""))
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
        print("Docker Tools Multi-Lint Server")
        print("Usage: python3 mcp-tool-server.py --stdin")
        print("\nSupported languages: dockerfile, image, security, analysis")
        print("Special actions: dockerfile_audit, image_analysis")
EOF

# Create CLI wrapper
COPY --chmod=755 <<'EOF' /usr/local/bin/lint
#!/bin/bash
ACTION=${1:-list}
LANGUAGE=${2:-dockerfile}
TOOL=${3:-}
PATH_TO_CHECK=${4:-.}

if [ "$ACTION" = "list" ]; then
    echo '{"action": "list"}' | python3 /app/mcp-tool-server.py --stdin
elif [ "$ACTION" = "suite" ]; then
    echo "{\"action\": \"run_suite\", \"language\": \"$LANGUAGE\", \"path\": \"$PATH_TO_CHECK\"}" | python3 /app/mcp-tool-server.py --stdin
elif [ "$ACTION" = "run" ]; then
    echo "{\"action\": \"run\", \"language\": \"$LANGUAGE\", \"tool\": \"$TOOL\", \"path\": \"$PATH_TO_CHECK\"}" | python3 /app/mcp-tool-server.py --stdin
elif [ "$ACTION" = "audit" ]; then
    echo "{\"action\": \"dockerfile_audit\", \"path\": \"$PATH_TO_CHECK\"}" | python3 /app/mcp-tool-server.py --stdin
elif [ "$ACTION" = "analyze" ]; then
    echo "{\"action\": \"image_analysis\", \"path\": \"$PATH_TO_CHECK\"}" | python3 /app/mcp-tool-server.py --stdin
else
    echo "Usage: lint [list|run|suite|audit|analyze] [language] [tool] [path]"
    echo "Languages: dockerfile, image, security, analysis"
    echo "Examples:"
    echo "  lint list"
    echo "  lint run dockerfile hadolint /workspace/Dockerfile"
    echo "  lint suite dockerfile /workspace"
    echo "  lint audit /workspace"
    echo "  lint analyze myimage:latest"
fi
EOF

# Create Docker-specific configuration templates
RUN mkdir -p /config/docker

# Hadolint configuration
COPY <<'EOF' /config/docker/.hadolint.yaml
# Hadolint configuration for Docker best practices
failure-threshold: warning
format: json

ignored:
  # Allow pinning to latest for base images in development
  - DL3006
  # Allow root user in containers (sometimes necessary)
  - DL3002

trustedRegistries:
  - docker.io
  - gcr.io
  - ghcr.io
  - mcr.microsoft.com
  - quay.io

override:
  error:
    # Always pin package versions
    - DL3008
    # Always use specific tags
    - DL3007
  warning:
    # Prefer COPY over ADD
    - DL3020
  info:
    # Use multi-stage builds
    - DL3022
  style:
    # Use --no-cache-dir with pip
    - DL3042
EOF

# dockerfile-lint rules
COPY <<'EOF' /config/docker/dockerfile-lint-rules.yaml
profile:
  name: "Default"
  description: "Default Dockerfile linting rules"
line_rules:
  FROM:
    paramSyntaxRegex: /^[\w./\-:]+(:[\w.]+)?$/
    rules:
      - label: "is_latest_tag"
        regex: /latest/
        level: "warn"
        message: "Using latest tag is not recommended"
      - label: "no_tag"
        regex: /^[^:]+$/
        level: "error"
        message: "No tag specified"
  RUN:
    paramSyntaxRegex: /.+/
    rules:
      - label: "sudo_usage"
        regex: /sudo/
        level: "warn"
        message: "Avoid using sudo in containers"
      - label: "apt_get_update_without_install"
        regex: /apt-get update(?!.*(&&|;).*apt-get (install|upgrade))/
        level: "error"
        message: "apt-get update should be combined with install"
  WORKDIR:
    paramSyntaxRegex: /^[^\s]+$/
    rules: []
  EXPOSE:
    paramSyntaxRegex: /^[\d\s]+$/
    rules: []
  ENV:
    paramSyntaxRegex: /.+/
    rules: []
  ADD:
    paramSyntaxRegex: /^[\w\s./-]+$/
    rules:
      - label: "prefer_copy"
        regex: /.*/
        level: "warn"
        message: "Prefer COPY over ADD for local files"
  COPY:
    paramSyntaxRegex: /^[\w\s./-]+$/
    rules: []
  USER:
    paramSyntaxRegex: /^[a-z_][a-z0-9_-]*$/
    rules:
      - label: "root_user"
        regex: /^root$/
        level: "warn"
        message: "Running as root is not recommended"
required_instructions:
  - "FROM"
EOF

# Container structure test example
COPY <<'EOF' /config/docker/structure-test.yaml
schemaVersion: 2.0.0
metadataTest:
  exposedPorts: ["3000"]
  workdir: "/workspace"
  
commandTests:
  - name: "tool availability"
    command: ["hadolint", "--version"]
    expectedOutput: ["Haskell Dockerfile Linter"]
  - name: "python availability"  
    command: ["python3", "--version"]
    expectedOutput: ["Python 3\\.\\d+\\.\\d+"]

fileExistenceTests:
  - name: "MCP server exists"
    path: "/app/mcp-tool-server.py"
    shouldExist: true
  - name: "lint CLI exists"
    path: "/usr/local/bin/lint"
    shouldExist: true

fileContentTests:
  - name: "MCP server is executable"
    path: "/app/mcp-tool-server.py"
    expectedContents: ["#!/usr/bin/env python3"]
EOF

WORKDIR /workspace
EXPOSE ${MCP_SERVER_PORT}
ENTRYPOINT ["python3", "/app/mcp-tool-server.py"]
CMD ["--stdin"]