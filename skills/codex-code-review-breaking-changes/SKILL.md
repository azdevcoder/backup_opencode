---
name: codex-code-review-breaking-changes
description: Breaking changes
---

> Port of the Codex built-in skill `code-review-breaking-changes` from openai/codex (.codex/skills) for OpenCode. Directory and `name:` prefixed as `codex-code-review-breaking-changes`; body unchanged.

Search for breaking changes in external integration surfaces:
- app-server APIs
- CLI parameters
- configuration loading
- resuming sessions from existing rollouts

Do not stop after finding one issue; analyze all possible ways breaking changes can happen.
