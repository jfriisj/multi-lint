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

# Install MCP SDK for Python
RUN pip3 install --no-cache-dir --break-system-packages mcp==1.1.2

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
COPY --chmod=755 <<'EOF' /app/mcp-tool-server.py
#!/usr/bin/env python3
"""
MCP Server for Docker Tools
Provides unified interface for Dockerfile linting, image analysis, and security scanning
"""
import asyncio
import subprocess
import os
import shlex
from typing import Any

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

# Tool configurations with detailed descriptions
TOOLS_CONFIG = {
    "hadolint": {
        "cmd": "hadolint",
        "description": "Dockerfile linter - enforce best practices and detect issues",
        "requires_dockerfile": True,
        "accepts_config": True
    },
    "hadolint-json": {
        "cmd": "hadolint --format json",
        "description": "Dockerfile linter with JSON output for parsing",
        "requires_dockerfile": True,
        "accepts_config": True
    },
    "dive": {
        "cmd": "dive --ci",
        "description": "Docker image layer analyzer - inspect image efficiency",
        "requires_image": True,
        "accepts_config": False
    },
    "trivy-image": {
        "cmd": "trivy image",
        "description": "Container image vulnerability scanner",
        "requires_image": True,
        "accepts_config": False
    },
    "trivy-fs": {
        "cmd": "trivy fs",
        "description": "Filesystem vulnerability scanner for Docker contexts",
        "requires_dockerfile": False,
        "accepts_config": False
    },
    "trivy-config": {
        "cmd": "trivy config",
        "description": "Configuration file scanner for IaC misconfigurations",
        "requires_dockerfile": False,
        "accepts_config": False
    },
    "trivy-secrets": {
        "cmd": "trivy fs --scanners secret",
        "description": "Secret scanner for Docker contexts and files",
        "requires_dockerfile": False,
        "accepts_config": False
    },
    "structure-test": {
        "cmd": "container-structure-test test",
        "description": "Google's container structure testing framework",
        "requires_image": True,
        "accepts_config": True
    },
    "docker-bench": {
        "cmd": "docker-bench-security",
        "description": "Docker security benchmark - CIS Docker Benchmark",
        "requires_dockerfile": False,
        "accepts_config": False
    },
    "layer-analysis": {
        "cmd": "dive --ci --lowestEfficiency=0.99",
        "description": "Analyze Docker image layer efficiency",
        "requires_image": True,
        "accepts_config": False
    },
    "size-analysis": {
        "cmd": "dive --ci --highestWastedBytes=0",
        "description": "Analyze Docker image wasted space",
        "requires_image": True,
        "accepts_config": False
    }
}

server = Server("docker-tools-server")

@server.list_tools()
async def list_tools() -> list[Tool]:
    """List all available Docker tools"""
    return [
        Tool(
            name=name,
            description=config["description"],
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path to Dockerfile, directory, or image name (depending on tool)"
                    },
                    "config": {
                        "type": "string",
                        "description": "Path to configuration file (if supported)"
                    },
                    "format": {
                        "type": "string",
                        "description": "Output format for trivy (json, table, sarif)"
                    }
                },
                "required": ["path"]
            }
        )
        for name, config in TOOLS_CONFIG.items()
    ]

@server.call_tool()
async def call_tool(name: str, arguments: Any) -> list[TextContent]:
    """Execute a Docker tool"""
    if name not in TOOLS_CONFIG:
        return [TextContent(type="text", text=f"Error: Unknown tool '{name}'")]
    
    config = TOOLS_CONFIG[name]
    path = arguments.get("path", ".")
    config_file = arguments.get("config")
    output_format = arguments.get("format")
    
    # Build command
    cmd = config["cmd"]
    cmd_parts = shlex.split(cmd)
    
    # Handle Dockerfile tools
    if config.get("requires_dockerfile"):
        if path.endswith("Dockerfile") or os.path.basename(path) == "Dockerfile":
            dockerfile_path = path
        else:
            dockerfile_path = os.path.join(path, "Dockerfile")
            if not os.path.exists(dockerfile_path):
                return [TextContent(type="text", text=f"Error: No Dockerfile found in {path}")]
        
        if config_file and config.get("accepts_config"):
            cmd_parts.extend(["--config", config_file])
        
        cmd_parts.append(dockerfile_path)
    
    # Handle image tools (dive, trivy-image, structure-test)
    elif config.get("requires_image"):
        if name == "structure-test":
            if config_file:
                cmd_parts.extend(["--config", config_file])
            cmd_parts.extend(["--image", path])
        else:
            cmd_parts.append(path)
    
    # Handle trivy filesystem/config tools
    elif name.startswith("trivy"):
        if output_format:
            cmd_parts.extend(["--format", output_format])
        cmd_parts.append(path)
    
    # docker-bench runs without arguments
    elif name == "docker-bench":
        pass
    
    # Default: append path
    else:
        cmd_parts.append(path)
    
    # Execute tool
    try:
        result = subprocess.run(
            cmd_parts,
            capture_output=True,
            text=True,
            timeout=600  # Longer timeout for image analysis
        )
        
        output = f"Command: {' '.join(cmd_parts)}\n"
        output += f"Exit Code: {result.returncode}\n\n"
        
        if result.stdout:
            output += "Output:\n" + result.stdout + "\n"
        if result.stderr:
            output += "Errors:\n" + result.stderr + "\n"
        
        if result.returncode == 0:
            output += "\n✓ Check completed successfully"
        else:
            output += f"\n✗ Check failed with exit code {result.returncode}"
        
        return [TextContent(type="text", text=output)]
        
    except subprocess.TimeoutExpired:
        return [TextContent(type="text", text=f"Error: Tool '{name}' timed out after 600 seconds")]
    except Exception as e:
        return [TextContent(type="text", text=f"Error executing '{name}': {str(e)}")]

async def main():
    """Run the MCP server"""
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            server.create_initialization_options()
        )

if __name__ == "__main__":
    asyncio.run(main())
EOF

# Create CLI wrapper
COPY --chmod=755 <<'EOF' /usr/local/bin/lint
#!/bin/bash
TOOLS="hadolint hadolint-json dive trivy-image trivy-fs trivy-config trivy-secrets structure-test docker-bench layer-analysis size-analysis"

if [ "$1" = "list" ] || [ -z "$1" ]; then
    echo "Available Docker Tools:"
    echo "$TOOLS" | tr ' ' '\n' | sed 's/^/  - /'
    echo ""
    echo "Tool Categories:"
    echo "  Dockerfile: hadolint, hadolint-json"
    echo "  Image: dive, trivy-image, trivy-fs, structure-test"
    echo "  Security: trivy-config, trivy-secrets, docker-bench"
    echo "  Analysis: layer-analysis, size-analysis"
    echo ""
    echo "Usage: lint <tool> <path|image> [options]"
    echo "Examples:"
    echo "  lint hadolint ./Dockerfile"
    echo "  lint dive myimage:latest"
    echo "  lint trivy-image nginx:latest"
    echo "  lint trivy-secrets ./"
    echo ""
    echo "Note: Image tools require Docker socket: -v /var/run/docker.sock:/var/run/docker.sock"
    exit 0
fi

TOOL=$1
TARGET=${2:-.}
shift 2

exec $TOOL $TARGET "$@"
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
CMD []