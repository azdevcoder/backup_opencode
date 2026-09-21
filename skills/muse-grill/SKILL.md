---
name: muse-grill
description: Run an explicitly requested decision interview and record each settled decision in durable project documentation.
---

> Port of the Muse Code built-in skill `grill` (extracted from Muse Code 1.3.0) for OpenCode. Original trigger semantics preserved; `bundled:<skill>` references were renamed to `muse-<skill>`. Muse-native tool calls (`read_skill`, `muse skills ...`, `muse exec/trace/export`, MSP session paths) map to OpenCode's `skill` tool and equivalent CLI steps here.

---

# Grill

Use this skill only when the user explicitly asks for grilling plus durable documentation or directly invokes this skill. Complexity, ambiguity, or a possible need for docs alone never activates it. This skill carries its own interview and documentation contract. Do not load or invoke `domain-modeling` at runtime.

<!-- DECISION-LINEAGE RESPONSIBILITY START -->
## Decision-Lineage Responsibility

At the start of a TBH repository run, first inspect the repository for a marker candidate in ADR 22440 as defined by the Operational Cutover Contract. The marker inspection command MUST complete successfully before invoking the wrapper; never skip or parallelize it when a marker candidate exists. If no marker candidate exists, treat the state as `inactive` without executing the wrapper and preserve the existing documentation behavior below, regardless of whether an older wrapper is present. If a marker candidate exists while the wrapper is absent or does not advertise `--cutover-status`, keep any work Draft and stop before claiming accepted authority or completion. Otherwise execute `bash scripts/check-decision-lineage.sh --cutover-status`. If the state is `inactive`, preserve the existing documentation behavior below.

For this entry probe, run the same check against the lane's candidate tree and then its explicit base tree. Pin `TBH_DECISION_LINEAGE_BIN` to one existing executable for both runs. The base tree is the `git merge-base HEAD origin/main` commit, checked by the same wrapper with `TBH_DECISION_LINEAGE_REPO_ROOT` set to the base worktree's project directory (`projects/tbh` in this monorepo). Require `docs/adr/22440-decision-lineage-and-root-cause-gates.md` in that directory; if absent, treat the base as unavailable and stop. If the base cannot be resolved, materialized, or checked, stop: missing or invalid base evidence is a refusal, never an empty finding set. Complete findings from a nonzero check remain usable. Read findings from stderr JSON, not the success-status JSON. Compare findings by `(rule_id, path, message)`: a candidate Blocking finding is new only if its tuple is absent from the base check, regardless of which paths the lane changed. Stop before lineage-sensitive work only for unavailable base evidence, new Blocking, Blocking `DL-CUTOVER-*` (even if inherited), or ToolError from either check (including `DL-TOOL-001`), whether or not it reached the authoritative checker. Other inherited Blocking and all Warnings never stop the lane at this entry probe, including Warning-severity `DL-CUTOVER-*`. A candidate probe exit 1 with no such stop uses `probe failed; inherited debt; activation unvalidated` as the lane receipt label, never `active` or `inactive`. Record both trees, commands, actual exits, findings, and the tuple comparison; the operational probe remains failed. Continue into the active phase-specific checks below. All phase-specific authority and validation gates below still apply.

When the state is `active`, capture provenance before the first durable write: an RFC 3339 timestamp with timezone, hostname, agent type, attributable session ID, and every human participant's verified GitHub login or Unix identity. Do not infer a current participant from commit authorship, quoted text, tools, or another account. Historical migration may label a value `unknown` or `inferred` with its evidence, but either label MUST NOT satisfy authority; unverifiable current authority stays Draft pending fresh human confirmation.

If verified participant identity is missing, do not make the first durable write; the same stop applies when fresh human confirmation is missing. Ask for the missing identity or confirmation before creating or editing the journal or decision, querying descendants, regenerating the index, or running the final strict check. An existing record with unverifiable current authority stays Draft; do not create a new unverified Draft or run `write-index` over unchanged or unauthoritative bytes. When the request explicitly withholds fresh confirmation or asks you to infer the participant, run only the cutover probe and then stop; do not inspect git history as a substitute for attributable identity.

Write each decision as Draft with a stable ID, authority class and records, upstream `derives_from` / `constrained_by` relationships, explicit supersession scope, and load-bearing assumptions. Record contract effectivity in the owning spec's `contract-lineage` mapping rather than adding fields to the closed decision schema. When a decision changes, run `cargo run --locked -q -p tbh-devtools --no-default-features --features decision-lineage --bin tbh-decision-lineage -- query --repo-root . --id <id> --direction descendants` and record the affected descendant closure. Only explicit human acceptance in the attributable session may change Draft authority to accepted.

Before reporting synchronized completion, run `cargo run --locked -q -p tbh-devtools --no-default-features --features decision-lineage --bin tbh-decision-lineage -- check --repo-root .` (it builds and validates the index in memory; there is no index to regenerate or commit — ADR 29188 D1). If provenance, authority, graph validation, descendant reconciliation, deterministic regeneration, or the strict check is incomplete, the skill MUST NOT claim completion.
<!-- DECISION-LINEAGE RESPONSIBILITY END -->

## Interview Contract

1. Research discoverable facts in the repository, issue, docs, and code before asking the user. Ask only for judgments or facts that cannot be discovered.
2. Ask one decision-forcing question at a time. State the recommended answer and the reason briefly, then wait for the answer.
3. Ask every interview question in plain text as an ordinary assistant response. Do not use a question tool.
   - When a bounded decision benefits from 2-3 short, mutually exclusive choices, list them in plain text with the recommended answer first.
   - Invite the user to choose, modify, or discuss the choices instead of forcing a structured selection.
4. Use comparison tables only when the user explicitly requested one or the question concerns agent-product behavior, such as Claude Code versus Codex.
5. Follow dependent decisions until the skill decides the decision tree is exhausted. Never ask a final "are we done?" meta-question.
6. Summarize the settled contract: goals, non-goals, decisions, constraints, risks, validation, and unresolved items.

## Scope Contract

The interview is not finished until the settled contract fixes the scope in
writing and the user accepts that text explicitly:

1. **Artifact-level boundary.** Name what the deliverable is (the documents,
   directories, PRs, or code paths in scope) and the artifact classes that are
   out of scope, such as follow-on specs, tests, runtime code, or task plans.
2. **Done means.** A short checklist of the observable conditions that finish
   the work: landed commits, closed issues, verified evidence. Nothing outside
   the checklist is a completion dependency.
3. **Staged designs are approved one stage at a time.** If a decision record
   describes later stages (an ADR that stages Constitution, spec, or runtime
   changes), record them as deferred proposals; accepting the record never
   approves the later stages. Each stage returns for its own interview.
4. **Execution words never widen scope.** "Go", "do it all", or "land 1-5"
   authorize only the accepted boundary. When later work would add an artifact
   class, a new PR, or a task program outside the boundary, stop before
   producing it and take one of exactly two paths: obtain the owner's explicit
   approval of the wider boundary, recorded on the owning issue, or move the
   extra work into a follow-up issue that starts its own interview. Never build
   first and ask afterwards.

Post the accepted scope contract where the executing lane and its supervisors
can read it (for repository work, the owning issue), quoting the acceptance.
This comment is lane-coordination evidence, not a decision record: it quotes
the user's exact words with channel and time; the durable decision lives in the
record this skill writes, never in the comment.

Ending the interview never authorizes implementation. Implement only after a separate explicit user request.

## Documentation Contract

1. Before the first question, resolve the target document from the user's named target and the repository's existing documentation conventions. Inspect local instructions, indexes, specs, ADRs, glossaries, and nearby docs. If the target is undeterminable, ask one question. Never invent a universal `docs/grilling/<date>.md` location.
2. Create or update the target as **Draft**. Write each settled decision immediately as Draft instead of waiting for the interview to end. Keep unresolved questions visibly marked.
3. If interrupted or cancelled, preserve the Draft and all file edits, mark unresolved questions, and never auto-revert documentation changes.
4. Read detailed `CONTEXT.md`, ADR, glossary, or other format references only when that document type is actually being written.
5. Normal Write/Edit tool events are the live proof of documentation work. Do not emit duplicate `Updated <path>` status lines.
6. An explicit docs request is a hard completion condition: the session cannot finish successfully without a useful documentation creation or update. "No docs needed" with zero file changes never satisfies it.
7. Only explicit user acceptance may change a document from Draft to **Final**. Exhausting the decision tree does not imply acceptance.
8. In the final response, list every changed documentation path and whether it stayed Draft or became Final.

## Credit

This skill's interview method and original name come from the `grilling` and
`grill-with-docs` skills by Matt Pocock (@mattpocockuk),
<https://github.com/mattpocock/skills>. See the package's `CREDITS.md`.
