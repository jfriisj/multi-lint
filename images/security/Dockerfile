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
    mcp==1.1.2 \
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
COPY --chmod=755 <<'EOF' /app/mcp-tool-server.py
#!/usr/bin/env python3
"""
MCP Server for Security Scanning Tools
Provides unified interface for security and vulnerability scanning
"""
import asyncio
import subprocess
import shlex
from typing import Any

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

# Tool configurations
TOOLS_CONFIG = {
    "semgrep": {
        "cmd": "semgrep --config=auto",
        "fix_cmd": None,
        "config_flag": "--config",
        "description": "Static analysis for security - find bugs and vulnerabilities"
    },
    "trivy": {
        "cmd": "trivy fs",
        "fix_cmd": None,
        "config_flag": None,
        "description": "Vulnerability scanner for filesystems and repositories"
    },
    "bandit": {
        "cmd": "bandit -r",
        "fix_cmd": None,
        "config_flag": "-c",
        "description": "Python security linter - find common security issues"
    },
    "safety": {
        "cmd": "safety check",
        "fix_cmd": None,
        "config_flag": None,
        "description": "Python dependency security checker - check for known vulnerabilities"
    },
    "trivy-image": {
        "cmd": "trivy image",
        "fix_cmd": None,
        "config_flag": None,
        "description": "Container image vulnerability scanner (requires Docker socket)"
    },
    "trivy-config": {
        "cmd": "trivy config",
        "fix_cmd": None,
        "config_flag": None,
        "description": "Configuration file scanner for IaC misconfigurations"
    }
}

server = Server("security-scan-server")

@server.list_tools()
async def list_tools() -> list[Tool]:
    """List all available security scanning tools"""
    return [
        Tool(
            name=name,
            description=config["description"],
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path to scan (file/directory) or image name for trivy-image"
                    },
                    "config": {
                        "type": "string",
                        "description": "Path to configuration file (optional)"
                    },
                    "format": {
                        "type": "string",
                        "description": "Output format (for trivy: json, table, sarif)"
                    }
                },
                "required": ["path"]
            }
        )
        for name, config in TOOLS_CONFIG.items()
    ]

@server.call_tool()
async def call_tool(name: str, arguments: Any) -> list[TextContent]:
    """Execute a security scanning tool"""
    if name not in TOOLS_CONFIG:
        return [TextContent(type="text", text=f"Error: Unknown tool '{name}'")]
    
    config = TOOLS_CONFIG[name]
    path = arguments.get("path", ".")
    config_file = arguments.get("config")
    output_format = arguments.get("format")
    
    # Build command
    cmd = config["cmd"]
    cmd_parts = shlex.split(cmd)
    
    # Add config file if provided and supported
    if config_file and config["config_flag"]:
        cmd_parts.extend([config["config_flag"], config_file])
    
    # Add format flag for trivy tools
    if output_format and name.startswith("trivy"):
        cmd_parts.extend(["--format", output_format])
    
    # Add path/target
    cmd_parts.append(path)
    
    # Execute tool with extended timeout for security scans
    try:
        result = subprocess.run(
            cmd_parts,
            capture_output=True,
            text=True,
            timeout=600  # 10 minutes for thorough scans
        )
        
        output = f"Command: {' '.join(cmd_parts)}\n"
        output += f"Exit Code: {result.returncode}\n\n"
        
        if result.stdout:
            output += "Output:\n" + result.stdout + "\n"
        if result.stderr:
            output += "Errors:\n" + result.stderr + "\n"
        
        if result.returncode == 0:
            output += "\n✓ Scan completed - no issues found"
        else:
            output += f"\n⚠ Scan completed with findings (exit code {result.returncode})"
        
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
TOOLS="semgrep trivy bandit safety trivy-image trivy-config"

if [ "$1" = "list" ] || [ -z "$1" ]; then
    echo "Available Security Tools:"
    echo "$TOOLS" | tr ' ' '\n' | sed 's/^/  - /'
    echo ""
    echo "Usage: lint <tool> <path|image> [options]"
    echo "Examples:"
    echo "  lint semgrep ./src"
    echo "  lint trivy ./"
    echo "  lint bandit ./python-code"
    echo "  lint trivy-image nginx:latest"
    echo ""
    echo "Note: trivy-image requires Docker socket mount: -v /var/run/docker.sock:/var/run/docker.sock"
    exit 0
fi

TOOL=$1
TARGET=${2:-.}
shift 2

exec $TOOL $TARGET "$@"
EOF

WORKDIR /workspace
EXPOSE ${MCP_SERVER_PORT}
ENTRYPOINT ["python3", "/app/mcp-tool-server.py"]
CMD []