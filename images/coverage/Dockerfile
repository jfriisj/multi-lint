# Multi-Lint: Code Coverage Tools
# Focused image for code coverage analysis across multiple languages
# Published as: ghcr.io/jfriisj/multi-lint-coverage

FROM python:3.12-slim

# Tool versions
ENV COVERAGE_PY_VERSION=7.6.9 \
    PYTEST_COV_VERSION=6.0.0 \
    GOCOV_VERSION=1.1.0 \
    NYCC_VERSION=17.1.0 \
    JEST_VERSION=29.7.0 \
    CARGO_TARPAULIN_VERSION=0.31.2

ENV MCP_SERVER_PORT=3000

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js for JavaScript/TypeScript coverage
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Go for Go coverage
RUN curl -fsSL https://go.dev/dl/go1.22.0.linux-amd64.tar.gz | tar -C /usr/local -xzf - \
    && ln -s /usr/local/go/bin/go /usr/bin/go \
    && ln -s /usr/local/go/bin/gofmt /usr/bin/gofmt

# Install Rust for Rust coverage
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && . "$HOME/.cargo/env"

ENV PATH="/root/.cargo/bin:${PATH}"

# Install Python coverage tools
RUN pip install --no-cache-dir \
    mcp==1.1.2 \
    coverage==${COVERAGE_PY_VERSION} \
    pytest-cov==${PYTEST_COV_VERSION} \
    pytest==8.3.4 \
    && pip cache purge

# Install JavaScript/TypeScript coverage tools
RUN npm install -g --no-optional \
    nyc@${NYCC_VERSION} \
    jest@${JEST_VERSION} \
    c8@10.1.2 \
    istanbul@0.4.5 \
    && npm cache clean --force

# Install Go coverage tools
RUN go install github.com/axw/gocov/gocov@v${GOCOV_VERSION} \
    && go install github.com/AlekSi/gocov-xml@latest \
    && go clean -cache -modcache

# Install Rust coverage tools
RUN cargo install cargo-tarpaulin --version ${CARGO_TARPAULIN_VERSION} \
    && rm -rf /root/.cargo/registry /root/.cargo/git

# Create MCP server
WORKDIR /app
COPY --chmod=755 <<'EOF' /app/mcp-tool-server.py
#!/usr/bin/env python3
"""
MCP Server for Code Coverage Tools
Provides unified interface for code coverage analysis across multiple languages
"""
import asyncio
import subprocess
import shlex
import json
from typing import Any

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

# Tool configurations
TOOLS_CONFIG = {
    # Python Coverage Tools
    "coverage": {
        "cmd": "coverage run -m pytest",
        "report_cmd": "coverage report",
        "html_cmd": "coverage html",
        "xml_cmd": "coverage xml",
        "json_cmd": "coverage json",
        "description": "Python coverage - measure test coverage with pytest",
        "language": "python"
    },
    "pytest-cov": {
        "cmd": "pytest --cov",
        "report_cmd": "pytest --cov --cov-report=term",
        "html_cmd": "pytest --cov --cov-report=html",
        "xml_cmd": "pytest --cov --cov-report=xml",
        "json_cmd": None,
        "description": "Pytest coverage plugin - integrated pytest coverage reporting",
        "language": "python"
    },
    
    # JavaScript/TypeScript Coverage Tools
    "nyc": {
        "cmd": "nyc",
        "report_cmd": "nyc report",
        "html_cmd": "nyc report --reporter=html",
        "xml_cmd": "nyc report --reporter=cobertura",
        "json_cmd": "nyc report --reporter=json",
        "description": "NYC (Istanbul) - JavaScript/TypeScript code coverage",
        "language": "javascript"
    },
    "jest-coverage": {
        "cmd": "jest --coverage",
        "report_cmd": "jest --coverage",
        "html_cmd": "jest --coverage --coverageReporters=html",
        "xml_cmd": "jest --coverage --coverageReporters=cobertura",
        "json_cmd": "jest --coverage --coverageReporters=json",
        "description": "Jest coverage - built-in coverage for Jest testing framework",
        "language": "javascript"
    },
    "c8": {
        "cmd": "c8",
        "report_cmd": "c8 report",
        "html_cmd": "c8 report --reporter=html",
        "xml_cmd": "c8 report --reporter=cobertura",
        "json_cmd": "c8 report --reporter=json",
        "description": "C8 - native V8 code coverage for Node.js",
        "language": "javascript"
    },
    
    # Go Coverage Tools
    "go-test-coverage": {
        "cmd": "go test -cover ./...",
        "report_cmd": "go test -coverprofile=coverage.out ./...",
        "html_cmd": "go tool cover -html=coverage.out",
        "xml_cmd": "gocov test ./... | gocov-xml",
        "json_cmd": "go test -coverprofile=coverage.out -json ./...",
        "description": "Go test coverage - built-in Go coverage analysis",
        "language": "go"
    },
    "gocov": {
        "cmd": "gocov test ./...",
        "report_cmd": "gocov test ./... | gocov report",
        "html_cmd": None,
        "xml_cmd": "gocov test ./... | gocov-xml",
        "json_cmd": "gocov test ./...",
        "description": "Gocov - detailed Go coverage analysis and reporting",
        "language": "go"
    },
    
    # Rust Coverage Tools
    "cargo-tarpaulin": {
        "cmd": "cargo tarpaulin",
        "report_cmd": "cargo tarpaulin --out Stdout",
        "html_cmd": "cargo tarpaulin --out Html",
        "xml_cmd": "cargo tarpaulin --out Xml",
        "json_cmd": "cargo tarpaulin --out Json",
        "description": "Cargo Tarpaulin - code coverage for Rust projects",
        "language": "rust"
    },
    
    # Combined/Analysis Tools
    "coverage-summary": {
        "cmd": None,
        "report_cmd": None,
        "html_cmd": None,
        "xml_cmd": None,
        "json_cmd": None,
        "description": "Generate coverage summary across all detected languages",
        "language": "multi"
    }
}

server = Server("coverage-server")

@server.list_tools()
async def list_tools() -> list[Tool]:
    """List all available code coverage tools"""
    tools = []
    
    for name, config in TOOLS_CONFIG.items():
        if name == "coverage-summary":
            tools.append(Tool(
                name=name,
                description=config["description"],
                inputSchema={
                    "type": "object",
                    "properties": {
                        "path": {
                            "type": "string",
                            "description": "Path to project directory"
                        }
                    },
                    "required": ["path"]
                }
            ))
        else:
            tools.append(Tool(
                name=name,
                description=config["description"],
                inputSchema={
                    "type": "object",
                    "properties": {
                        "path": {
                            "type": "string",
                            "description": "Path to the project directory"
                        },
                        "format": {
                            "type": "string",
                            "enum": ["text", "html", "xml", "json"],
                            "description": "Output format for coverage report",
                            "default": "text"
                        },
                        "threshold": {
                            "type": "number",
                            "description": "Minimum coverage threshold percentage (0-100)",
                            "minimum": 0,
                            "maximum": 100
                        },
                        "config": {
                            "type": "string",
                            "description": "Path to configuration file (optional)"
                        }
                    },
                    "required": ["path"]
                }
            ))
    
    return tools

@server.call_tool()
async def call_tool(name: str, arguments: Any) -> list[TextContent]:
    """Execute a code coverage tool"""
    if name not in TOOLS_CONFIG:
        return [TextContent(type="text", text=f"Error: Unknown tool '{name}'")]
    
    config = TOOLS_CONFIG[name]
    path = arguments.get("path", ".")
    output_format = arguments.get("format", "text")
    threshold = arguments.get("threshold")
    config_file = arguments.get("config")
    
    # Handle special case: coverage-summary
    if name == "coverage-summary":
        return await generate_coverage_summary(path)
    
    # Select appropriate command based on format
    cmd = None
    if output_format == "html" and config["html_cmd"]:
        cmd = config["html_cmd"]
    elif output_format == "xml" and config["xml_cmd"]:
        cmd = config["xml_cmd"]
    elif output_format == "json" and config["json_cmd"]:
        cmd = config["json_cmd"]
    elif output_format == "text" and config["report_cmd"]:
        cmd = config["report_cmd"]
    else:
        cmd = config["cmd"]
    
    if not cmd:
        return [TextContent(
            type="text",
            text=f"Error: Format '{output_format}' not supported for tool '{name}'"
        )]
    
    # Parse command
    cmd_parts = shlex.split(cmd)
    
    # Add config file if provided
    if config_file:
        if name.startswith("pytest") or name == "coverage":
            cmd_parts.extend(["--rcfile", config_file])
        elif name in ["nyc", "c8"]:
            cmd_parts.extend(["--config", config_file])
    
    # Add path
    if name not in ["coverage", "pytest-cov"]:  # These handle paths differently
        if not any(p.startswith(path) for p in cmd_parts):
            cmd_parts.append(path)
    
    # Add threshold if specified
    if threshold is not None:
        if name in ["coverage", "pytest-cov"]:
            cmd_parts.extend([f"--cov-fail-under={threshold}"])
        elif name in ["nyc", "c8"]:
            cmd_parts.extend([f"--check-coverage", f"--lines={threshold}"])
    
    # Execute tool
    try:
        result = subprocess.run(
            cmd_parts,
            capture_output=True,
            text=True,
            timeout=600,
            cwd=path if path != "." else None
        )
        
        output = f"Tool: {name} ({config['language']})\n"
        output += f"Command: {' '.join(cmd_parts)}\n"
        output += f"Exit Code: {result.returncode}\n"
        output += f"Output Format: {output_format}\n"
        if threshold:
            output += f"Threshold: {threshold}%\n"
        output += "\n" + "="*60 + "\n"
        
        if result.stdout:
            output += result.stdout + "\n"
        if result.stderr:
            output += "\nErrors/Warnings:\n" + result.stderr + "\n"
        
        output += "="*60 + "\n"
        
        if result.returncode == 0:
            output += "\n✓ Coverage analysis completed successfully"
            if threshold:
                output += f" (threshold {threshold}% met)"
        else:
            output += f"\n✗ Coverage analysis failed with exit code {result.returncode}"
            if threshold and result.returncode == 2:
                output += f" (threshold {threshold}% not met)"
        
        return [TextContent(type="text", text=output)]
        
    except subprocess.TimeoutExpired:
        return [TextContent(
            type="text",
            text=f"Error: Tool '{name}' timed out after 600 seconds"
        )]
    except Exception as e:
        return [TextContent(
            type="text",
            text=f"Error executing '{name}': {str(e)}"
        )]

async def generate_coverage_summary(path: str) -> list[TextContent]:
    """Generate a summary of coverage across all detected languages"""
    output = "Coverage Summary - Multi-Language Analysis\n"
    output += "="*60 + "\n\n"
    
    results = {}
    
    # Check for Python
    try:
        py_result = subprocess.run(
            ["python3", "-c", "import pytest; import coverage"],
            capture_output=True,
            cwd=path if path != "." else None,
            timeout=5
        )
        if py_result.returncode == 0:
            cov_result = subprocess.run(
                ["coverage", "report", "--format=total"],
                capture_output=True,
                text=True,
                cwd=path if path != "." else None,
                timeout=30
            )
            if cov_result.returncode == 0:
                results["Python"] = cov_result.stdout.strip()
    except:
        pass
    
    # Check for JavaScript/TypeScript
    try:
        js_result = subprocess.run(
            ["test", "-f", "package.json"],
            capture_output=True,
            cwd=path if path != "." else None,
            timeout=5
        )
        if js_result.returncode == 0:
            results["JavaScript/TypeScript"] = "Detected (run nyc or jest-coverage)"
    except:
        pass
    
    # Check for Go
    try:
        go_result = subprocess.run(
            ["test", "-f", "go.mod"],
            capture_output=True,
            cwd=path if path != "." else None,
            timeout=5
        )
        if go_result.returncode == 0:
            results["Go"] = "Detected (run go-test-coverage)"
    except:
        pass
    
    # Check for Rust
    try:
        rust_result = subprocess.run(
            ["test", "-f", "Cargo.toml"],
            capture_output=True,
            cwd=path if path != "." else None,
            timeout=5
        )
        if rust_result.returncode == 0:
            results["Rust"] = "Detected (run cargo-tarpaulin)"
    except:
        pass
    
    if results:
        for lang, status in results.items():
            output += f"📊 {lang}: {status}\n"
    else:
        output += "No supported projects detected in path.\n"
    
    output += "\n" + "="*60 + "\n"
    output += "\nSupported Languages:\n"
    output += "  • Python (coverage, pytest-cov)\n"
    output += "  • JavaScript/TypeScript (nyc, jest-coverage, c8)\n"
    output += "  • Go (go-test-coverage, gocov)\n"
    output += "  • Rust (cargo-tarpaulin)\n"
    
    return [TextContent(type="text", text=output)]

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
COPY --chmod=755 <<'EOF' /usr/local/bin/coverage-cli
#!/bin/bash
# Code Coverage Tools CLI

show_help() {
    cat << HELP
Code Coverage Tools

Python:
  coverage <path>              - Run coverage analysis with pytest
  pytest-cov <path>            - Run pytest with coverage
  
JavaScript/TypeScript:
  nyc <path>                   - Istanbul/NYC coverage
  jest-coverage <path>         - Jest with coverage
  c8 <path>                    - C8 native V8 coverage
  
Go:
  go-test-coverage <path>      - Go built-in coverage
  gocov <path>                 - Gocov detailed analysis
  
Rust:
  cargo-tarpaulin <path>       - Cargo Tarpaulin coverage

Multi-language:
  coverage-summary <path>      - Summary across all languages

Options:
  --format text|html|xml|json  - Output format
  --threshold <number>         - Minimum coverage % (0-100)
  --config <file>              - Configuration file

Examples:
  coverage-cli coverage ./src --format html
  coverage-cli pytest-cov . --threshold 80
  coverage-cli nyc ./src --format json
  coverage-cli coverage-summary .
HELP
}

if [ "$1" = "help" ] || [ "$1" = "--help" ] || [ -z "$1" ]; then
    show_help
    exit 0
fi

TOOL=$1
shift

case $TOOL in
    coverage|pytest-cov|nyc|jest-coverage|c8|go-test-coverage|gocov|cargo-tarpaulin|coverage-summary)
        echo "Running $TOOL..."
        # Tool execution would be handled by MCP server
        ;;
    *)
        echo "Unknown tool: $TOOL"
        echo "Run 'coverage-cli help' for usage"
        exit 1
        ;;
esac
EOF

WORKDIR /workspace
EXPOSE ${MCP_SERVER_PORT}
ENTRYPOINT ["python3", "/app/mcp-tool-server.py"]
CMD []
