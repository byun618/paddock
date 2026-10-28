---
name: adopt-skip-claude-md-line
tags: [trigger, negative]
runs: 2
max_turns: 4
timeout_seconds: 180
allowed_tools: [Read, Glob, Grep, Skill]
---

CLAUDE.md 에 빌드 명령 한 줄만 추가해줘: `pnpm build`
