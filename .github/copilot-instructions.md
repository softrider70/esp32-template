# Copilot Workspace Strategy

## Default Mode
Use the Lean Workspace agent for exploration, planning, and read-only investigation. Keep the default tool footprint as small as possible.

## Escalation Rules
- Switch to Edit Specialist only when files must be created or changed.
- Switch to Terminal Specialist only when shell, git, build, or generator commands are required.
- If a task can be solved with read and search tools, do not escalate.

## Tool Governance
Tool activation is managed via agent specialization, not global hooks. Agents in `.github/agents/` define which tools are available for each workflow.
