---
name: codex-code-review-testing
description: Test authoring guidance
---

> Port of the Codex built-in skill `code-review-testing` from openai/codex (.codex/skills) for OpenCode. Directory and `name:` prefixed as `codex-code-review-testing`; body unchanged.

For agent changes prefer integration tests over unit tests. Integration tests are under `core/suite` and use `test_codex` to set up a test instance of codex.

Features that change the agent logic MUST add an integration test:
- Provide a list of major logic changes and user-facing behaviors that need to be tested.

If unit tests are needed, put them in a dedicated test file (*_tests.rs).
Avoid test-only functions in the main implementation.

Check whether there are existing helpers to make tests more streamlined and readable.
