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
COPY mcp.json /app/mcp.json
COPY --chmod=755 <<'EOF' /app/mcp-tool-server.py
#!/usr/bin/env python3
"""
MCP-Compatible Unity Development Tool Server
Provides unified interface for Unity C# development and code quality tools
"""
import json
import subprocess
import sys
import os
from typing import Dict, Optional

TOOL_REGISTRY = {
    "csharp": {
        "dotnet-format": {"cmd": "dotnet format", "fix": "dotnet format", "config": "--verbosity"},
        "roslynator": {"cmd": "roslynator analyze", "fix": "roslynator fix", "config": "--config"},
        "dotnet-outdated": {"cmd": "dotnet outdated", "fix": None, "config": None},
        "security-scan": {"cmd": "security-scan", "fix": None, "config": None},
        "dotnet-sonarscanner": {"cmd": "dotnet sonarscanner begin", "fix": None, "config": None},
    },
    "unity": {
        "unity-analyzers": {"cmd": "dotnet build", "fix": None, "config": "--configuration"},
        "stylecop": {"cmd": "dotnet build", "fix": None, "config": "--configuration"},
        "editorconfig": {"cmd": "editorconfig-checker", "fix": None, "config": None},
        "unity-test": {"cmd": "dotnet test", "fix": None, "config": "--configuration"},
        "unity-build": {"cmd": "dotnet build", "fix": None, "config": "--configuration"},
    },
    "project": {
        "dotnet-depends": {"cmd": "dotnet depends", "fix": None, "config": None},
        "package-audit": {"cmd": "dotnet list package --vulnerable", "fix": None, "config": None},
        "restore": {"cmd": "dotnet restore", "fix": None, "config": None},
        "clean": {"cmd": "dotnet clean", "fix": None, "config": None},
    }
}

def run_tool(language: str, tool: str, path: str, fix: bool = False, config: Optional[str] = None) -> Dict:
    if language not in TOOL_REGISTRY or tool not in TOOL_REGISTRY[language]:
        return {"success": False, "error": f"Tool '{tool}' not available for '{language}'"}
    
    tool_info = TOOL_REGISTRY[language][tool]
    cmd = tool_info["fix"] if fix and tool_info["fix"] else tool_info["cmd"]
    command = cmd.split()
    
    # Special handling for different tools
    if tool == "dotnet-format":
        if path != ".":
            command.extend(["--include", path])
        if config:
            command.extend(["--verbosity", config])
    elif tool == "editorconfig":
        command.append(path)
    elif tool in ["unity-build", "unity-test", "dotnet-sonarscanner"]:
        # Change to project directory
        original_cwd = os.getcwd()
        try:
            os.chdir(path)
        except:
            pass
    else:
        if config and tool_info["config"]:
            command.extend([tool_info["config"], config])
        if path != "." and not any(x in tool for x in ["dotnet", "unity"]):
            command.append(path)
    
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=600,  # Longer timeout for builds
            cwd=path if tool in ["unity-build", "unity-test", "restore", "clean"] else None
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

def run_unity_workflow(path: str, config: str = "Debug") -> Dict:
    """Run complete Unity development workflow"""
    workflow_steps = [
        ("project", "restore", "Restore packages"),
        ("project", "clean", "Clean project"),
        ("unity", "unity-build", "Build project"),
        ("csharp", "dotnet-format", "Format code"),
        ("unity", "editorconfig", "Check EditorConfig"),
        ("unity", "unity-test", "Run tests"),
        ("project", "package-audit", "Security audit"),
    ]
    
    results = {}
    for category, tool, description in workflow_steps:
        print(f"Running: {description}...", file=sys.stderr)
        results[f"{category}_{tool}"] = run_tool(category, tool, path, config=config)
        if not results[f"{category}_{tool}"]["success"] and tool in ["restore", "unity-build"]:
            # Stop on critical failures
            break
    
    return {"success": True, "workflow_results": results}

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
    elif action == "unity_workflow":
        return run_unity_workflow(
            request.get("path", "."),
            request.get("config", "Debug")
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
        print("Unity Development Multi-Lint Tool")
        print("Usage: python3 mcp-tool-server.py --stdin")
        print("\nSupported languages: csharp, unity, project")
        print("Special action: unity_workflow - runs complete development workflow")
EOF

# Create CLI wrapper
COPY --chmod=755 <<'EOF' /usr/local/bin/lint
#!/bin/bash
ACTION=${1:-list}
LANGUAGE=${2:-unity}
TOOL=${3:-}
PATH_TO_CHECK=${4:-.}

if [ "$ACTION" = "list" ]; then
    echo '{"action": "list"}' | python3 /app/mcp-tool-server.py --stdin
elif [ "$ACTION" = "suite" ]; then
    echo "{\"action\": \"run_suite\", \"language\": \"$LANGUAGE\", \"path\": \"$PATH_TO_CHECK\"}" | python3 /app/mcp-tool-server.py --stdin
elif [ "$ACTION" = "run" ]; then
    echo "{\"action\": \"run\", \"language\": \"$LANGUAGE\", \"tool\": \"$TOOL\", \"path\": \"$PATH_TO_CHECK\"}" | python3 /app/mcp-tool-server.py --stdin
elif [ "$ACTION" = "workflow" ]; then
    echo "{\"action\": \"unity_workflow\", \"path\": \"$PATH_TO_CHECK\", \"config\": \"${TOOL:-Debug}\"}" | python3 /app/mcp-tool-server.py --stdin
else
    echo "Usage: lint [list|run|suite|workflow] [language] [tool] [path]"
    echo "Languages: csharp, unity, project"
    echo "Examples:"
    echo "  lint list"
    echo "  lint run csharp dotnet-format /project"
    echo "  lint suite unity /project"
    echo "  lint workflow /project Debug"
fi
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
CMD ["--stdin"]