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
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install MCP SDK for Python
RUN pip3 install --no-cache-dir --break-system-packages mcp==1.1.2

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
COPY --chmod=755 <<'EOF' /app/mcp-tool-server.py
#!/usr/bin/env python3
"""
MCP Server for JavaScript/TypeScript Linting Tools
Provides unified interface for JavaScript, TypeScript, and web framework tools
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
    "eslint": {
        "cmd": "eslint",
        "fix_cmd": "eslint --fix",
        "config_flag": "-c",
        "description": "JavaScript/TypeScript linter - find and fix problems in your code"
    },
    "prettier": {
        "cmd": "prettier --check",
        "fix_cmd": "prettier --write",
        "config_flag": "--config",
        "description": "Code formatter - enforce consistent code style"
    },
    "jshint": {
        "cmd": "jshint",
        "fix_cmd": None,
        "config_flag": "--config",
        "description": "JavaScript linter - detect errors and potential problems"
    },
    "jest": {
        "cmd": "jest",
        "fix_cmd": None,
        "config_flag": "--config",
        "description": "Testing framework - run JavaScript/TypeScript tests"
    },
    "stylelint": {
        "cmd": "stylelint",
        "fix_cmd": "stylelint --fix",
        "config_flag": "--config",
        "description": "CSS/SCSS linter - enforce consistent conventions"
    },
    "standard": {
        "cmd": "standard",
        "fix_cmd": "standard --fix",
        "config_flag": None,
        "description": "JavaScript Standard Style - no configuration needed"
    },
    "tsc": {
        "cmd": "tsc --noEmit",
        "fix_cmd": None,
        "config_flag": "-p",
        "description": "TypeScript compiler - check TypeScript code for type errors"
    },
    "eslint-react": {
        "cmd": "eslint --ext .jsx,.tsx",
        "fix_cmd": "eslint --ext .jsx,.tsx --fix",
        "config_flag": "-c",
        "description": "React linter - lint React/JSX code"
    },
    "eslint-vue": {
        "cmd": "eslint --ext .vue",
        "fix_cmd": "eslint --ext .vue --fix",
        "config_flag": "-c",
        "description": "Vue.js linter - lint Vue.js single file components"
    },
    "eslint-angular": {
        "cmd": "eslint --ext .ts,.html",
        "fix_cmd": "eslint --ext .ts,.html --fix",
        "config_flag": "-c",
        "description": "Angular linter - lint Angular TypeScript and templates"
    },
    "sass": {
        "cmd": "sass --check",
        "fix_cmd": None,
        "config_flag": None,
        "description": "Sass compiler - check Sass/SCSS syntax"
    },
    "stylelint-scss": {
        "cmd": "stylelint '**/*.scss'",
        "fix_cmd": "stylelint '**/*.scss' --fix",
        "config_flag": "--config",
        "description": "SCSS linter - lint SCSS files with stylelint"
    }
}

server = Server("javascript-lint-server")

@server.list_tools()
async def list_tools() -> list[Tool]:
    """List all available JavaScript/TypeScript linting tools"""
    return [
        Tool(
            name=name,
            description=config["description"],
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path to the file or directory to check"
                    },
                    "fix": {
                        "type": "boolean",
                        "description": "Automatically fix problems if supported",
                        "default": False
                    },
                    "config": {
                        "type": "string",
                        "description": "Path to configuration file (optional)"
                    }
                },
                "required": ["path"]
            }
        )
        for name, config in TOOLS_CONFIG.items()
    ]

@server.call_tool()
async def call_tool(name: str, arguments: Any) -> list[TextContent]:
    """Execute a JavaScript/TypeScript linting tool"""
    if name not in TOOLS_CONFIG:
        return [TextContent(type="text", text=f"Error: Unknown tool '{name}'")]
    
    config = TOOLS_CONFIG[name]
    path = arguments.get("path", ".")
    fix = arguments.get("fix", False)
    config_file = arguments.get("config")
    
    # Build command
    if fix and config["fix_cmd"]:
        cmd = config["fix_cmd"]
    else:
        cmd = config["cmd"]
    
    # Parse command and add path
    cmd_parts = shlex.split(cmd)
    
    # Add config file if provided and supported
    if config_file and config["config_flag"]:
        cmd_parts.extend([config["config_flag"], config_file])
    
    # Add path to check
    cmd_parts.append(path)
    
    # Execute tool
    try:
        result = subprocess.run(
            cmd_parts,
            capture_output=True,
            text=True,
            timeout=300
        )
        
        output = f"Command: {' '.join(cmd_parts)}\n"
        output += f"Exit Code: {result.returncode}\n\n"
        
        if result.stdout:
            output += "Output:\n" + result.stdout + "\n"
        if result.stderr:
            output += "Errors:\n" + result.stderr + "\n"
        
        if result.returncode == 0:
            output += "\n✓ Check passed successfully"
        else:
            output += f"\n✗ Check failed with exit code {result.returncode}"
        
        return [TextContent(type="text", text=output)]
        
    except subprocess.TimeoutExpired:
        return [TextContent(type="text", text=f"Error: Tool '{name}' timed out after 300 seconds")]
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
TOOLS="eslint prettier jshint jest stylelint standard tsc eslint-react eslint-vue eslint-angular sass stylelint-scss"

if [ "$1" = "list" ] || [ -z "$1" ]; then
    echo "Available JavaScript/TypeScript Tools:"
    echo "$TOOLS" | tr ' ' '\n' | sed 's/^/  - /'
    echo ""
    echo "Usage: lint <tool> <path> [options]"
    echo "Examples:"
    echo "  lint eslint ./src"
    echo "  lint prettier ./src --fix"
    echo "  lint tsc ./tsconfig.json"
    exit 0
fi

TOOL=$1
PATH_TO_CHECK=${2:-.}
shift 2

exec $TOOL $PATH_TO_CHECK "$@"
EOF

WORKDIR /workspace
EXPOSE ${MCP_SERVER_PORT}
ENTRYPOINT ["python3", "/app/mcp-tool-server.py"]
CMD []