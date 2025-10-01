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
    mcp==1.1.2 \
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
COPY --chmod=755 <<'EOF' /app/mcp-tool-server.py
#!/usr/bin/env python3
"""
MCP Server for Infrastructure as Code Linting Tools
Provides unified interface for Terraform, Kubernetes, Ansible, and CloudFormation tools
"""
import asyncio
import subprocess
from typing import Any

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent


# Tool registry with metadata
TOOLS_CONFIG = {
    "tflint": {
        "description": "Terraform linter - validates Terraform configurations",
        "cmd": "tflint",
        "category": "terraform"
    },
    "tfsec": {
        "description": "Terraform security scanner - finds security issues in Terraform",
        "cmd": "tfsec",
        "category": "terraform"
    },
    "kubeval": {
        "description": "Kubernetes YAML validator - validates Kubernetes manifests",
        "cmd": "kubeval",
        "category": "kubernetes"
    },
    "kube-score": {
        "description": "Kubernetes best practices - analyzes K8s manifests for best practices",
        "cmd": "kube-score score",
        "category": "kubernetes"
    },
    "ansible-lint": {
        "description": "Ansible playbook linter - checks Ansible playbooks for issues",
        "cmd": "ansible-lint",
        "category": "ansible"
    },
    "cfn-lint": {
        "description": "CloudFormation template linter - validates AWS CloudFormation templates",
        "cmd": "cfn-lint",
        "category": "cloudformation"
    },
    "yamllint": {
        "description": "YAML linter - validates YAML file syntax and style",
        "cmd": "yamllint",
        "category": "yaml"
    }
}

# Create MCP server
server = Server("infrastructure-lint-server")


@server.list_tools()
async def list_tools() -> list[Tool]:
    """List all available infrastructure linting tools."""
    return [
        Tool(
            name=name,
            description=config["description"],
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path to the file or directory to lint"
                    },
                    "fix": {
                        "type": "boolean",
                        "description": "Whether to automatically fix issues (if supported)",
                        "default": False
                    },
                    "config": {
                        "type": "string",
                        "description": "Optional path to configuration file"
                    }
                },
                "required": ["path"]
            }
        )
        for name, config in TOOLS_CONFIG.items()
    ]


@server.call_tool()
async def call_tool(name: str, arguments: Any) -> list[TextContent]:
    """Execute a linting tool with the provided arguments."""
    if name not in TOOLS_CONFIG:
        raise ValueError(f"Unknown tool: {name}")
    
    tool_config = TOOLS_CONFIG[name]
    path = arguments.get("path", ".")
    fix = arguments.get("fix", False)
    config_path = arguments.get("config")
    
    # Build command
    cmd = tool_config["cmd"].split()
    
    # Add config if provided
    if config_path:
        if name == "tflint":
            cmd.extend(["--config", config_path])
        elif name == "ansible-lint":
            cmd.extend(["-c", config_path])
        elif name == "cfn-lint":
            cmd.extend(["--config-file", config_path])
        elif name == "yamllint":
            cmd.extend(["-c", config_path])
    
    # Add fix flag if supported and requested
    if fix and name == "tflint":
        cmd.append("--fix")
    
    # Add path
    cmd.append(path)
    
    try:
        # Run the tool
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300
        )
        
        # Format output
        output = f"Tool: {name}\n"
        output += f"Command: {' '.join(cmd)}\n"
        output += f"Exit Code: {result.returncode}\n"
        output += f"\n{'='*60}\n"
        output += f"STDOUT:\n{result.stdout}\n"
        
        if result.stderr:
            output += f"\n{'='*60}\n"
            output += f"STDERR:\n{result.stderr}\n"
        
        if result.returncode == 0:
            output += f"\n✅ Success: No issues found"
        else:
            output += f"\n⚠️  Issues detected (exit code: {result.returncode})"
        
        return [TextContent(type="text", text=output)]
        
    except subprocess.TimeoutExpired:
        error_msg = f"❌ Error: Tool '{name}' timed out after 300 seconds"
        return [TextContent(type="text", text=error_msg)]
    except Exception as e:
        error_msg = f"❌ Error executing '{name}': {str(e)}"
        return [TextContent(type="text", text=error_msg)]


async def main():
    """Run the MCP server."""
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            server.create_initialization_options()
        )


if __name__ == "__main__":
    asyncio.run(main())
EOF

# Create CLI wrapper for easy tool execution
COPY --chmod=755 <<'EOF' /usr/local/bin/lint
#!/usr/bin/env python3
"""
CLI wrapper for Infrastructure Linting MCP Server
Provides easy command-line access to linting tools
"""
import sys
import subprocess
import json

# Available tools by category
TOOLS = {
    "terraform": ["tflint", "tfsec"],
    "kubernetes": ["kubeval", "kube-score"],
    "ansible": ["ansible-lint"],
    "cloudformation": ["cfn-lint"],
    "yaml": ["yamllint"]
}

def list_tools():
    """List all available tools."""
    print("Available Infrastructure Linting Tools:\n")
    for category, tools in TOOLS.items():
        print(f"  {category.upper()}:")
        for tool in tools:
            print(f"    - {tool}")
    print("\nUsage:")
    print("  lint <tool> <path> [--fix] [--config <config-path>]")
    print("\nExamples:")
    print("  lint tflint /workspace")
    print("  lint tfsec /workspace --config .tfsec.yaml")
    print("  lint kubeval /workspace/manifests")
    print("  lint ansible-lint /workspace/playbooks")

def run_tool(tool, path, fix=False, config=None):
    """Run a specific tool."""
    # Find all tools
    all_tools = [t for tools in TOOLS.values() for t in tools]
    
    if tool not in all_tools:
        print(f"❌ Error: Unknown tool '{tool}'")
        print(f"Available tools: {', '.join(all_tools)}")
        sys.exit(1)
    
    # Build command
    cmd = [tool, path]
    
    if config:
        if tool == "tflint":
            cmd.insert(1, "--config")
            cmd.insert(2, config)
        elif tool == "ansible-lint":
            cmd.insert(1, "-c")
            cmd.insert(2, config)
        elif tool == "cfn-lint":
            cmd.insert(1, "--config-file")
            cmd.insert(2, config)
        elif tool == "yamllint":
            cmd.insert(1, "-c")
            cmd.insert(2, config)
    
    if fix and tool == "tflint":
        cmd.insert(1, "--fix")
    
    print(f"🔧 Running: {' '.join(cmd)}\n")
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        
        if result.stdout:
            print(result.stdout)
        if result.stderr:
            print(result.stderr, file=sys.stderr)
        
        if result.returncode == 0:
            print("\n✅ Success: No issues found")
        else:
            print(f"\n⚠️  Issues detected (exit code: {result.returncode})")
        
        sys.exit(result.returncode)
        
    except subprocess.TimeoutExpired:
        print(f"❌ Error: Tool '{tool}' timed out after 300 seconds")
        sys.exit(1)
    except FileNotFoundError:
        print(f"❌ Error: Tool '{tool}' not found. Is it installed?")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        sys.exit(1)

def main():
    if len(sys.argv) < 2 or sys.argv[1] in ["-h", "--help", "help"]:
        list_tools()
        sys.exit(0)
    
    if sys.argv[1] == "list":
        list_tools()
        sys.exit(0)
    
    # Parse arguments
    tool = sys.argv[1]
    
    if len(sys.argv) < 3:
        print(f"❌ Error: Path required")
        print(f"Usage: lint {tool} <path> [--fix] [--config <config-path>]")
        sys.exit(1)
    
    path = sys.argv[2]
    fix = "--fix" in sys.argv
    
    config = None
    if "--config" in sys.argv:
        try:
            config_idx = sys.argv.index("--config")
            config = sys.argv[config_idx + 1]
        except (IndexError, ValueError):
            print("❌ Error: --config requires a path argument")
            sys.exit(1)
    
    run_tool(tool, path, fix, config)

if __name__ == "__main__":
    main()
EOF

WORKDIR /workspace
EXPOSE ${MCP_SERVER_PORT}

# Default to MCP server mode, but allow CLI usage
ENTRYPOINT ["python3", "/app/mcp-tool-server.py"]
CMD []