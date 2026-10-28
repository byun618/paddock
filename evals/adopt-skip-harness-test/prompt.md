---
name: adopt-skip-harness-test
tags: [trigger, negative]
runs: 2
max_turns: 4
timeout_seconds: 180
allowed_tools: [Read, Glob, Grep, Skill]
---

harness.ts 에 vitest 단위 테스트 짜줘
