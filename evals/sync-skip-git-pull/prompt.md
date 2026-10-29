---
name: sync-skip-git-pull
tags: [trigger, negative]
runs: 2
max_turns: 4
timeout_seconds: 180
allowed_tools: [Read, Glob, Grep, Skill]
---

origin main 이랑 로컬 main sync 맞춰줘
