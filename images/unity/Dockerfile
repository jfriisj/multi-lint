# Multi-Lint: Unity Development Tools
# Focused image for Unity C# development, code quality, and game development workflows
# Published as: ghcr.io/jfriisj/multi-lint-unity

FROM mcr.microsoft.com/dotnet/sdk:8.0

# Tool versions
ENV DOTNET_VERSION=8.0 \
    UNITY_VERSION=2023.3 \
    ROSLYN_ANALYZERS_VERSION=4.5.0 \
    # .NET Tools
    DOTNET_FORMAT_VERSION=5.1.250801 \
    EDITORCONFIG_CHECKER_VERSION=2.7.0 \
    # Unity-specific tools
    UNITY_CODE_ANALYSIS_VERSION=1.0.1

ENV MCP_SERVER_PORT=3000

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    unzip \
    python3 \
    python3-pip \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install MCP SDK for Python
RUN pip3 install --no-cache-dir --break-system-packages mcp==1.1.2

# Install .NET tools globally
RUN dotnet tool install -g dotnet-format --version ${DOTNET_FORMAT_VERSION} && \
    dotnet tool install -g dotnet-outdated-tool && \
    dotnet tool install -g security-scan && \
    dotnet tool install -g dotnet-depends && \
    dotnet tool install -g roslynator.dotnet.cli && \
    dotnet tool install -g dotnet-sonarscanner

# Install EditorConfig checker binary
RUN wget -qO /tmp/ec-linux-amd64.tar.gz \
        "https://github.com/editorconfig-checker/editorconfig-checker/releases/download/2.7.0/ec-linux-amd64.tar.gz" && \
    tar -xzf /tmp/ec-linux-amd64.tar.gz -C /tmp && \
    mv /tmp/bin/ec-linux-amd64 /usr/local/bin/editorconfig-checker && \
    chmod +x /usr/local/bin/editorconfig-checker && \
    rm -rf /tmp/ec-linux-amd64.tar.gz /tmp/bin

# Create Unity tools directory for future use
RUN mkdir -p /unity-tools

# Add .NET tools to PATH
ENV PATH="/root/.dotnet/tools:${PATH}"

# Create MCP server
WORKDIR /app
COPY --chmod=755 <<'EOF' /app/mcp-tool-server.py
#!/usr/bin/env python3
"""
MCP Server for Unity Development Tools
Provides unified interface for Unity C# development and code quality tools
"""
import asyncio
import subprocess
import os
import shlex
from typing import Any

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

# Tool configurations
TOOLS_CONFIG = {
    "dotnet-format": {
        "cmd": "dotnet format",
        "fix_cmd": "dotnet format",
        "description": ".NET code formatter - format C# code according to style rules",
        "needs_cwd": False
    },
    "roslynator": {
        "cmd": "roslynator analyze",
        "fix_cmd": "roslynator fix",
        "description": "Roslyn code analyzer - find and fix C# code issues",
        "needs_cwd": False
    },
    "dotnet-outdated": {
        "cmd": "dotnet outdated",
        "fix_cmd": None,
        "description": "Check for outdated NuGet packages",
        "needs_cwd": True
    },
    "security-scan": {
        "cmd": "security-scan",
        "fix_cmd": None,
        "description": "Security vulnerability scanner for .NET projects",
        "needs_cwd": True
    },
    "editorconfig": {
        "cmd": "editorconfig-checker",
        "fix_cmd": None,
        "description": "EditorConfig validator - check code formatting compliance",
        "needs_cwd": False
    },
    "unity-test": {
        "cmd": "dotnet test",
        "fix_cmd": None,
        "description": "Unity test runner - execute unit tests",
        "needs_cwd": True
    },
    "unity-build": {
        "cmd": "dotnet build",
        "fix_cmd": None,
        "description": "Unity project builder - compile C# code",
        "needs_cwd": True
    },
    "dotnet-depends": {
        "cmd": "dotnet depends",
        "fix_cmd": None,
        "description": "Dependency analyzer - visualize project dependencies",
        "needs_cwd": True
    },
    "package-audit": {
        "cmd": "dotnet list package --vulnerable",
        "fix_cmd": None,
        "description": "Package vulnerability audit - check for known CVEs",
        "needs_cwd": True
    },
    "restore": {
        "cmd": "dotnet restore",
        "fix_cmd": None,
        "description": "Restore NuGet packages and dependencies",
        "needs_cwd": True
    },
    "clean": {
        "cmd": "dotnet clean",
        "fix_cmd": None,
        "description": "Clean build artifacts and output directories",
        "needs_cwd": True
    }
}

server = Server("unity-dev-server")

@server.list_tools()
async def list_tools() -> list[Tool]:
    """List all available Unity development tools"""
    return [
        Tool(
            name=name,
            description=config["description"],
            inputSchema={
                "type": "object",
                "properties": {
                    "path": {
                        "type": "string",
                        "description": "Path to project directory or file to check"
                    },
                    "fix": {
                        "type": "boolean",
                        "description": "Automatically fix issues if supported",
                        "default": False
                    },
                    "configuration": {
                        "type": "string",
                        "description": "Build configuration (Debug/Release)",
                        "default": "Debug"
                    },
                    "verbosity": {
                        "type": "string",
                        "description": "Verbosity level (quiet/minimal/normal/detailed/diagnostic)"
                    }
                },
                "required": ["path"]
            }
        )
        for name, config in TOOLS_CONFIG.items()
    ]

@server.call_tool()
async def call_tool(name: str, arguments: Any) -> list[TextContent]:
    """Execute a Unity development tool"""
    if name not in TOOLS_CONFIG:
        return [TextContent(type="text", text=f"Error: Unknown tool '{name}'")]
    
    config = TOOLS_CONFIG[name]
    path = arguments.get("path", ".")
    fix = arguments.get("fix", False)
    configuration = arguments.get("configuration", "Debug")
    verbosity = arguments.get("verbosity")
    
    # Build command
    if fix and config["fix_cmd"]:
        cmd = config["fix_cmd"]
    else:
        cmd = config["cmd"]
    
    cmd_parts = shlex.split(cmd)
    
    # Add configuration for build/test tools
    if name in ["unity-build", "unity-test"] and configuration:
        cmd_parts.extend(["--configuration", configuration])
    
    # Add verbosity for format
    if name == "dotnet-format" and verbosity:
        cmd_parts.extend(["--verbosity", verbosity])
    
    # Add path for tools that don't need cwd
    if not config["needs_cwd"]:
        if name == "dotnet-format" and path != ".":
            cmd_parts.extend(["--include", path])
        elif name == "editorconfig":
            cmd_parts.append(path)
    
    # Determine working directory
    cwd = path if config["needs_cwd"] and os.path.isdir(path) else None
    
    # Execute tool
    try:
        result = subprocess.run(
            cmd_parts,
            capture_output=True,
            text=True,
            timeout=600,  # 10 minutes for builds
            cwd=cwd
        )
        
        output = f"Command: {' '.join(cmd_parts)}\n"
        if cwd:
            output += f"Working Directory: {cwd}\n"
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
TOOLS="dotnet-format roslynator dotnet-outdated security-scan editorconfig unity-test unity-build dotnet-depends package-audit restore clean"

if [ "$1" = "list" ] || [ -z "$1" ]; then
    echo "Available Unity Development Tools:"
    echo "$TOOLS" | tr ' ' '\n' | sed 's/^/  - /'
    echo ""
    echo "Tool Categories:"
    echo "  C# Tools: dotnet-format, roslynator, dotnet-outdated, security-scan"
    echo "  Unity: editorconfig, unity-test, unity-build"
    echo "  Project: dotnet-depends, package-audit, restore, clean"
    echo ""
    echo "Usage: lint <tool> <path> [options]"
    echo "Examples:"
    echo "  lint dotnet-format ./src"
    echo "  lint unity-build . --configuration Release"
    echo "  lint unity-test ."
    echo "  lint roslynator ./MyProject.csproj"
    exit 0
fi

TOOL=$1
PROJECT_PATH=${2:-.}
shift 2

exec $TOOL $PROJECT_PATH "$@"
EOF

# Create Unity-specific configuration templates
RUN mkdir -p /config/unity

# .editorconfig for Unity projects
COPY <<'EOF' /config/unity/.editorconfig
# Unity EditorConfig
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.cs]
indent_style = space
indent_size = 4

# Unity C# coding conventions
csharp_new_line_before_open_brace = all
csharp_new_line_before_else = true
csharp_new_line_before_catch = true
csharp_new_line_before_finally = true
csharp_new_line_before_members_in_object_init = true
csharp_new_line_before_members_in_anonymous_types = true
csharp_new_line_between_query_expression_clauses = true

# Unity naming conventions
dotnet_naming_rule.unity_serialized_field_rule.severity = warning
dotnet_naming_rule.unity_serialized_field_rule.symbols = unity_serialized_field
dotnet_naming_rule.unity_serialized_field_rule.style = camel_case
dotnet_naming_symbols.unity_serialized_field.applicable_kinds = field
dotnet_naming_symbols.unity_serialized_field.applicable_accessibilities = *
dotnet_naming_symbols.unity_serialized_field.required_modifiers = 
dotnet_naming_style.camel_case.required_prefix = 
dotnet_naming_style.camel_case.required_suffix = 
dotnet_naming_style.camel_case.word_separator = 
dotnet_naming_style.camel_case.capitalization = camel_case

[*.{json,asmdef}]
indent_style = space
indent_size = 2

[*.meta]
insert_final_newline = false
EOF

# StyleCop settings for Unity
COPY <<'EOF' /config/unity/stylecop.json
{
  "$schema": "https://raw.githubusercontent.com/DotNetAnalyzers/StyleCopAnalyzers/master/StyleCop.Analyzers/StyleCop.Analyzers/Settings/stylecop.schema.json",
  "settings": {
    "documentationRules": {
      "companyName": "Unity Technologies",
      "copyrightText": "Copyright (c) {companyName}. All rights reserved.",
      "xmlHeader": false,
      "fileNamingConvention": "stylecop"
    },
    "orderingRules": {
      "usingDirectivesPlacement": "outsideNamespace",
      "blankLinesBetweenUsingGroups": "allow"
    },
    "namingRules": {
      "allowCommonHungarianPrefixes": true,
      "allowedHungarianPrefixes": ["id", "is", "to", "ui", "x", "y", "z"]
    },
    "maintainabilityRules": {
      "topLevelTypes": ["class", "interface", "struct", "enum", "delegate"]
    }
  }
}
EOF

# Unity project analyzer config
COPY <<'EOF' /config/unity/Directory.Build.props
<Project>
  <PropertyGroup>
    <TreatWarningsAsErrors>false</TreatWarningsAsErrors>
    <WarningsAsErrors />
    <WarningsNotAsErrors />
    <CodeAnalysisRuleSet>unity-rules.ruleset</CodeAnalysisRuleSet>
    <EnableNETAnalyzers>true</EnableNETAnalyzers>
    <AnalysisLevel>latest</AnalysisLevel>
  </PropertyGroup>
  
  <ItemGroup>
    <PackageReference Include="Microsoft.Unity.Analyzers" Version="1.19.0">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers</IncludeAssets>
    </PackageReference>
    <PackageReference Include="StyleCop.Analyzers" Version="1.2.0-beta.507" PrivateAssets="all" />
  </ItemGroup>
  
  <ItemGroup>
    <AdditionalFiles Include="$(MSBuildThisFileDirectory)stylecop.json" />
  </ItemGroup>
</Project>
EOF

# Unity-specific ruleset
COPY <<'EOF' /config/unity/unity-rules.ruleset
<?xml version="1.0" encoding="utf-8"?>
<RuleSet Name="Unity Rules" Description="Code analysis rules for Unity projects." ToolsVersion="16.0">
  <Rules AnalyzerId="Microsoft.Unity.Analyzers" RuleNamespace="Microsoft.Unity.Analyzers">
    <Rule Id="UNT0001" Action="Warning" />
    <Rule Id="UNT0002" Action="Warning" />
    <Rule Id="UNT0003" Action="Warning" />
    <Rule Id="UNT0004" Action="Warning" />
    <Rule Id="UNT0005" Action="Warning" />
    <Rule Id="UNT0006" Action="Warning" />
    <Rule Id="UNT0007" Action="Warning" />
    <Rule Id="UNT0008" Action="Warning" />
    <Rule Id="UNT0009" Action="Warning" />
    <Rule Id="UNT0010" Action="Warning" />
    <Rule Id="UNT0011" Action="Warning" />
    <Rule Id="UNT0012" Action="Warning" />
  </Rules>
  
  <Rules AnalyzerId="StyleCop.Analyzers" RuleNamespace="StyleCop.Analyzers">
    <Rule Id="SA1633" Action="None" />
    <Rule Id="SA1200" Action="None" />
    <Rule Id="SA1400" Action="Warning" />
    <Rule Id="SA1401" Action="None" />
  </Rules>
</RuleSet>
EOF

WORKDIR /workspace
EXPOSE ${MCP_SERVER_PORT}
ENTRYPOINT ["python3", "/app/mcp-tool-server.py"]
CMD []