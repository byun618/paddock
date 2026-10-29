---
name: sync-skip-deps
tags: [trigger, negative]
runs: 2
max_turns: 4
timeout_seconds: 180
allowed_tools: [Read, Glob, Grep, Skill]
---

package.json 의존성들 최신 버전으로 업데이트해줘
