# Skill Registry

This registry tracks all available AI skills and project conventions.
Load a skill by reading its file when its trigger conditions are met.

## Available Skills

| Skill | Description | Path |
|-------|-------------|------|
| `skill-creator` | Creates new AI agent skills following the Agent Skills spec. Trigger: When user asks to create a new skill, add agent instructions, or document patterns for AI. | `/home/sophie/.gemini/skills/skill-creator/SKILL.md` |
| `go-testing` | Go testing patterns for Gentleman.Dots, including Bubbletea TUI testing. Trigger: When writing Go tests, using teatest, or adding test coverage. | `/home/sophie/.gemini/skills/go-testing/SKILL.md` |
| `find-skills` | Helps users discover and install agent skills. | `/home/sophie/.agents/skills/find-skills/SKILL.md` |

## Project Conventions

| Name | Description | Path |
|------|-------------|------|
| `CLAUDE.md` | Project-level instructions and architecture | `/mnt/data/Luminessa/luminessa-infrastructure/CLAUDE.md` |
| `SECURITY.md` | Security considerations and implementation guides | `/mnt/data/Luminessa/luminessa-infrastructure/SECURITY.md` |
