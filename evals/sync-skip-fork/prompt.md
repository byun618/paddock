---
name: sync-skip-fork
tags: [trigger, negative]
runs: 2
max_turns: 4
timeout_seconds: 180
allowed_tools: [Read, Glob, Grep, Skill]
---

fork 한 레포를 upstream 이랑 sync 해줘
