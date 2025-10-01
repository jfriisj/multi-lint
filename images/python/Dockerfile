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
    mcp==1.1.2 \
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
COPY --chmod=755 <<'EOF' /app/mcp-tool-server.py
#!/usr/bin/env python3
"""
MCP Server for Python Linting and Testing Tools
Provides unified interface for Python code quality tools via Model Context Protocol
"""
import asyncio
import subprocess
from typing import Any

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

# Tool configurations
TOOLS_CONFIG = {
    "ruff": {"cmd": "ruff check", "fix_cmd": "ruff check --fix", "config_flag": "--config", "description": "Fast Python linter - checks code for errors and style issues"},
    "black": {"cmd": "black --check", "fix_cmd": "black", "config_flag": "--config", "description": "Python code formatter - formats code to consistent style"},
    "mypy": {"cmd": "mypy", "fix_cmd": None, "config_flag": "--config-file", "description": "Static type checker - validates Python type hints"},
    "pylint": {"cmd": "pylint", "fix_cmd": None, "config_flag": "--rcfile", "description": "Code analyzer - checks for errors, style, and code smells"},
    "flake8": {"cmd": "flake8", "fix_cmd": None, "config_flag": "--config", "description": "Style guide enforcer - checks PEP 8 compliance"},
    "bandit": {"cmd": "bandit -r", "fix_cmd": None, "config_flag": "-c", "description": "Security linter - finds common security issues"},
    "pytest": {"cmd": "pytest", "fix_cmd": None, "config_flag": "-c", "description": "Testing framework - runs Python tests"},
    "isort": {"cmd": "isort --check", "fix_cmd": "isort", "config_flag": "--settings-file", "description": "Import sorter - organizes Python imports"},
    "vulture": {"cmd": "vulture", "fix_cmd": None, "config_flag": None, "description": "Dead code finder - detects unused code"},
    "pyflakes": {"cmd": "pyflakes", "fix_cmd": None, "config_flag": None, "description": "Error checker - finds syntax and logic errors"},
    "safety": {"cmd": "safety check", "fix_cmd": None, "config_flag": None, "description": "Dependency scanner - checks for known security vulnerabilities"},
    "coverage": {"cmd": "coverage run -m pytest", "fix_cmd": None, "config_flag": None, "description": "Code coverage - measures test coverage"},
    "autoflake": {"cmd": "autoflake --check", "fix_cmd": "autoflake --in-place", "config_flag": None, "description": "Unused import remover - cleans up unnecessary imports"}
}

# Create MCP server
server = Server("python-lint-server")

@server.list_tools()
async def list_tools() -> list[Tool]:
    """List all available Python linting and testing tools."""
    return [
        Tool(
            name=name,
            description=config["description"],
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {"type": "string", "description": "Path to Python file or directory"},
                    "fix": {"type": "boolean", "description": "Auto-fix issues if supported", "default": False},
                    "config": {"type": "string", "description": "Path to config file"}
                },
                "required": ["path"]
            }
        )
        for name, config in TOOLS_CONFIG.items()
    ]

@server.call_tool()
async def call_tool(name: str, arguments: Any) -> list[TextContent]:
    """Execute a Python linting or testing tool."""
    if name not in TOOLS_CONFIG:
        raise ValueError(f"Unknown tool: {name}")
    
    config = TOOLS_CONFIG[name]
    path = arguments.get("path", ".")
    fix = arguments.get("fix", False)
    config_path = arguments.get("config")
    
    # Build command
    if fix and config["fix_cmd"]:
        cmd = config["fix_cmd"].split()
    else:
        cmd = config["cmd"].split()
    
    # Add config if provided
    if config_path and config["config_flag"]:
        cmd.extend([config["config_flag"], config_path])
    
    # Add path
    cmd.append(path)
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        
        output = f"Tool: {name}\n"
        output += f"Command: {' '.join(cmd)}\n"
        output += f"Exit Code: {result.returncode}\n\n"
        output += f"{'='*60}\nSTDOUT:\n{result.stdout}\n"
        
        if result.stderr:
            output += f"\n{'='*60}\nSTDERR:\n{result.stderr}\n"
        
        output += f"\n{'✅' if result.returncode == 0 else '⚠️'} "
        output += "Success" if result.returncode == 0 else f"Issues detected (exit code: {result.returncode})"
        
        return [TextContent(type="text", text=output)]
        
    except subprocess.TimeoutExpired:
        return [TextContent(type="text", text=f"❌ Error: Tool '{name}' timed out")]
    except Exception as e:
        return [TextContent(type="text", text=f"❌ Error: {str(e)}")]

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await server.run(read_stream, write_stream, server.create_initialization_options())

if __name__ == "__main__":
    asyncio.run(main())
EOF

# Create CLI wrapper
COPY --chmod=755 <<'EOF' /usr/local/bin/lint
#!/bin/bash
# Python Linting Tools CLI
TOOLS="ruff black mypy pylint flake8 bandit pytest isort vulture pyflakes safety coverage autoflake"

if [ "$1" = "list" ] || [ -z "$1" ]; then
    echo "Python Linting Tools:"
    echo "$TOOLS" | tr ' ' '\n' | sed 's/^/  - /'
    echo ""
    echo "Usage: lint <tool> <path> [--fix] [--config <path>]"
    exit 0
fi

TOOL=$1
PATH=${2:-.}
shift 2

if ! echo "$TOOLS" | grep -wq "$TOOL"; then
    echo "❌ Unknown tool: $TOOL"
    exit 1
fi

exec $TOOL $PATH "$@"
EOF

WORKDIR /workspace
EXPOSE ${MCP_SERVER_PORT}
ENTRYPOINT ["python3", "/app/mcp-tool-server.py"]
CMD []