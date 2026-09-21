---
name: muse-create-plugin
description: Create and validate a new native Muse plugin package in the current workspace. Use ONLY when the user explicitly asks to create a Muse plugin or invokes the create-plugin skill. Do NOT use for application/library plugin classes, third-party plugin systems, or ordinary code changes.
---

> Port of the Muse Code skill `create-plugin` (extracted from Muse Code 1.3.0) for OpenCode. Original trigger semantics preserved; `bundled:<skill>` references were renamed to `muse-<skill>`. Muse-native tool calls (`read_skill`, `muse skills ...`, `muse exec/trace/export`, MSP session paths) map to OpenCode's `skill` tool and equivalent CLI steps here.

---

# Create Plugin

Create one new native Muse plugin in the current workspace. Use this skill only
for Muse native plugin package creation, not for implementing plugin classes or
plugin features inside another project. Produce the
smallest complete plugin that satisfies the request, validate it with the installed
muse CLI, and leave installation to the user.

## Boundaries

- Work only in one new destination inside the current workspace.
- Never modify, merge into, delete, or replace an existing path.
- Do not install, enable, trust, execute, or fetch the generated plugin or its
  dependencies.
- Do not update an existing plugin. Explain that update behavior needs a separate
  workflow.
- Do not publish or write global configuration.
- Ask before writing when the plugin ID, destination, requested capability, or
  required command is unclear.
- Reject unsupported capability families instead of inventing a schema.

The supported capability families are exactly `skills`, `commands`, `hooks`,
`mcpServers`, and `reminders`. Reject `tools`, `agents`, `outputStyles`, `settings`,
and `apps`. A custom model tool belongs behind an `mcpServers` entry, not a direct
`tools` capability.

## Optional References

This skill is complete without its references. If `read_skill` returned a physical
`SKILL.md` path and more detail would help, use `read_file` to inspect these siblings:

- `references/native-plugin-contract.md`
- `references/capability-examples.json`

Treat them as read-only guidance. Do not fail merely because a reference was not
read.

## Clarify First

Before tools, determine:

1. the portable plugin ID and human display name;
2. the destination relative to the current workspace;
3. the requested capability families and IDs;
4. every required artifact and command;
5. whether the request would require an unsupported family, dependency fetch, or
   modification of an existing path.

Ask a focused question for missing facts. Refuse before mutation when the request is
outside this skill's boundaries.

## Portable IDs And Paths

Plugin and capability IDs must:

- contain 1 through 80 ASCII bytes;
- begin with a lowercase ASCII letter or digit;
- use only lowercase ASCII letters, digits, `.`, `_`, and `-` afterward;
- not have a case-insensitive basename before the first dot equal to `CON`, `PRN`,
  `AUX`, `NUL`, `COM1` through `COM9`, or `LPT1` through `LPT9`;
- not use a product-reserved plugin ID: `loop` or `muse-core`.

Artifact paths must be relative UTF-8 paths beneath the plugin root. Manifest paths
use `/`. Reject absolute paths, `..`, backslashes in manifest values, symlink
escapes, and any path whose canonical parent leaves the current workspace.

## Required Manifest Base

Start from this native manifest shape and fill only requested capabilities:

```json
{
  "schemaVersion": 1,
  "name": "<portable-id>",
  "displayName": "<human name>",
  "version": "0.1.0",
  "description": "<plain description>",
  "compat": {
    "source": "native",
    "manifestDir": ".muse-plugin"
  },
  "capabilities": {
    "skills": [],
    "commands": [],
    "hooks": [],
    "mcpServers": [],
    "reminders": []
  }
}
```

The manifest lives at `.muse-plugin/plugin.json`. Keep empty capability arrays
unless the installed validator accepts their omission with zero diagnostics.

For each requested capability, create every path referenced by the manifest:

- `skills`: `{id, path, enabledDefault?}` and a UTF-8 `SKILL.md` with valid
  frontmatter;
- `commands`: `{id, path, enabledDefault?}` and a UTF-8 Markdown template;
- `hooks`: `{id, event, command, timeoutMs?, statusMessage?}` and any relative
  command source named by its argv;
- `mcpServers`: a stdio `{id, transport?, command}` or HTTP
  `{id, transport:"http", url}` entry and any relative command source named by its
  argv;
- `reminders`: `{id, path, tools?, blocking?, decision, defaultPriority?,
  maxPriority?, maxChildSteps?, maxInstallsPerRun?, reasoningEffort?, context?}`
  and a UTF-8 duty file. Use the executable decision object, including its V1
  `envelope` and `deliveryRole`, from `references/capability-examples.json`.

## Reserve The Destination

No artifact write may occur before all reservation steps succeed:

1. Resolve the current workspace and requested parent to canonical paths.
2. Require the parent and proposed destination to remain inside the workspace.
3. Reject a symlinked destination or a parent whose canonical identity escapes.
4. Confirm the destination does not exist.
5. Through the managed shell tool advertised by this session, use one
   platform-native atomic no-replace directory creation operation. Do not use a
   check-then-overwrite command.
6. If creation reports occupied or fails, stop. Never delete or reuse the path.
7. Canonicalize the new directory and its parent again. Require the same expected
   identity and workspace containment before the first `write_file` call.

Use `write_file` and `edit_file` for UTF-8 artifacts. Do not use shell redirection
to bypass file-tool containment. After reservation, mutate only the new directory.

## Validate And Correct

Validate every generated skill directory first. Invoke the installed program with
the equivalent structured argv. This is the `muse skills validate` operation;
keep its arguments structured:

```json
["muse", "skills", "validate", "<skill-directory>", "--json"]
```

Then run the `muse plugins validate` operation with structured arguments:

```json
["muse", "plugins", "validate", "<plugin-directory>", "--json"]
```

A validation result is clean only when the process starts, exits zero, stdout is
parseable JSON, top-level `valid` is `true`, and `diagnostics` is present and empty.
Warnings are not clean. A missing command, malformed JSON, timeout, denial,
cancellation, non-zero exit, `valid:false`, or any diagnostic leaves the draft
incomplete.

For each validation layer, make at most three correction rounds after its first
failed result. Edit only the new draft and rerun the same layer. The fourth failed
result is terminal for that layer. Never continue to whole-plugin validation while
a nested skill is invalid.

## Report

On success, report:

- the canonical artifact path;
- the capability and file inventory;
- the number and outcome of nested skill validations;
- the whole-plugin validation outcome;
- an unexecuted install proposal as structured `program` and `argv` values:

```json
{
  "program": "muse",
  "argv": ["plugins", "install", "<canonical-plugin-path>"],
  "executed": false
}
```

Explicitly state that installation was not run.

On failure or denial after reservation, report the draft path, exact failed
operation, remaining diagnostics, and checks not completed. Do not claim the draft
is created, valid, complete, or ready to install. Cancellation ends the run without
a later report; preserve all pre-existing bytes and let runtime cancellation remain
authoritative.
skills/create-plugin/references/capability-examples.json{
  "schemaVersion": 1,
  "supportedFamilies": [
    "skills",
    "commands",
    "hooks",
    "mcpServers",
    "reminders"
  ],
  "unsupportedFamilies": [
    "tools",
    "agents",
    "outputStyles",
    "settings",
    "apps"
  ],
  "reservedPluginIds": [
    "loop",
    "muse-core",
    "tbh-reminders",
    "herdr",
    "threejs"
  ],
  "creatorContract": {
    "idRules": {
      "maxBytes": 80,
      "pattern": "^[a-z0-9][a-z0-9._-]{0,79}$",
      "windowsReservedBasenames": [
        "CON",
        "PRN",
        "AUX",
        "NUL",
        "COM1",
        "COM2",
        "COM3",
        "COM4",
        "COM5",
        "COM6",
        "COM7",
        "COM8",
        "COM9",
        "LPT1",
        "LPT2",
        "LPT3",
        "LPT4",
        "LPT5",
        "LPT6",
        "LPT7",
        "LPT8",
        "LPT9"
      ],
      "rejectedExamples": [
        "",
        "Uppercase",
        "con",
        "CON.txt",
        "lpt1.log",
        "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
      ]
    },
    "pathRules": {
      "relativeOnly": true,
      "separator": "/",
      "reject": [
        "absolute",
        "parent-traversal",
        "backslash",
        "symlink-escape",
        "outside-workspace"
      ]
    },
    "destination": {
      "mustBeAbsent": true,
      "atomicNoReplace": true,
      "recheckCanonicalContainment": true
    },
    "validation": {
      "order": [
        "nestedSkills",
        "plugin"
      ],
      "success": {
        "exitCode": 0,
        "valid": true,
        "diagnostics": []
      },
      "warningsAccepted": false,
      "maxCorrectionRounds": 3,
      "terminalFailedResult": 4
    },
    "installProposal": {
      "program": "muse",
      "argv": [
        "plugins",
        "install",
        "<canonical-plugin-path>"
      ],
      "executed": false
    },
    "forbiddenActions": [
      "install",
      "enable",
      "trust",
      "execute",
      "fetch"
    ]
  },
  "examples": [
    {
      "family": "skills",
      "manifest": {
        "schemaVersion": 1,
        "name": "skills-example",
        "displayName": "Skills Example",
        "version": "0.1.0",
        "description": "One native skill capability.",
        "compat": {
          "source": "native",
          "manifestDir": ".muse-plugin"
        },
        "capabilities": {
          "skills": [
            {
              "id": "review",
              "path": "skills/review/SKILL.md",
              "enabledDefault": false
            }
          ],
          "commands": [],
          "hooks": [],
          "mcpServers": [],
          "reminders": []
        }
      },
      "files": {
        "skills/review/SKILL.md": "---\nname: review\ndescription: Review the current workspace.\n---\n\nReview the requested files and report concrete findings.\n"
      }
    },
    {
      "family": "commands",
      "manifest": {
        "schemaVersion": 1,
        "name": "commands-example",
        "displayName": "Commands Example",
        "version": "0.1.0",
        "description": "One native command capability.",
        "compat": {
          "source": "native",
          "manifestDir": ".muse-plugin"
        },
        "capabilities": {
          "skills": [],
          "commands": [
            {
              "id": "summarize",
              "path": "commands/summarize.md",
              "enabledDefault": true
            }
          ],
          "hooks": [],
          "mcpServers": [],
          "reminders": []
        }
      },
      "files": {
        "commands/summarize.md": "---\ndescription: Summarize a requested change\nargument-hint: <path>\n---\nSummarize $ARGUMENTS with file references.\n"
      }
    },
    {
      "family": "hooks",
      "manifest": {
        "schemaVersion": 1,
        "name": "hooks-example",
        "displayName": "Hooks Example",
        "version": "0.1.0",
        "description": "One native hook capability.",
        "compat": {
          "source": "native",
          "manifestDir": ".muse-plugin"
        },
        "capabilities": {
          "skills": [],
          "commands": [],
          "hooks": [
            {
              "id": "pre-check",
              "event": "PreToolUse",
              "command": [
                "sh",
                "hooks/pre-check.sh"
              ],
              "timeoutMs": 1000,
              "statusMessage": "Checking plugin policy"
            }
          ],
          "mcpServers": [],
          "reminders": []
        }
      },
      "files": {
        "hooks/pre-check.sh": "#!/bin/sh\nprintf '%s\\n' ok\n"
      }
    },
    {
      "family": "mcpServers",
      "manifest": {
        "schemaVersion": 1,
        "name": "mcp-example",
        "displayName": "MCP Example",
        "version": "0.1.0",
        "description": "One native MCP server capability.",
        "compat": {
          "source": "native",
          "manifestDir": ".muse-plugin"
        },
        "capabilities": {
          "skills": [],
          "commands": [],
          "hooks": [],
          "mcpServers": [
            {
              "id": "workspace-index",
              "transport": "stdio",
              "command": [
                "python3",
                "mcp/server.py"
              ]
            }
          ],
          "reminders": []
        }
      },
      "files": {
        "mcp/server.py": "import sys\nfor line in sys.stdin:\n    sys.stdout.write(line)\n    sys.stdout.flush()\n"
      }
    },
    {
      "family": "reminders",
      "manifest": {
        "schemaVersion": 1,
        "name": "reminders-example",
        "displayName": "Reminders Example",
        "version": "0.1.0",
        "description": "One native reminder capability.",
        "compat": {
          "source": "native",
          "manifestDir": ".muse-plugin"
        },
        "capabilities": {
          "skills": [],
          "commands": [],
          "hooks": [],
          "mcpServers": [],
          "reminders": [
            {
              "id": "review-policy",
              "path": "reminders/review-policy.md",
              "tools": [
                "read_file"
              ],
              "blocking": false,
              "decision": {
                "version": 1,
                "envelope": {
                  "version": 1,
                  "template": "<system-reminder>\n{text}\n</system-reminder>"
                },
                "deliveryRole": "developer",
                "fields": [
                  {
                    "name": "text",
                    "description": "Reminder body text.",
                    "requirement": "remind",
                    "shape": {
                      "type": "string",
                      "minBytes": 1,
                      "maxBytes": 2000
                    }
                  }
                ],
                "bodyTemplate": {
                  "text": "{text}",
                  "slots": [
                    {
                      "name": "text",
                      "source": {
                        "field": "text"
                      },
                      "escape": "xml",
                      "fallback": ""
                    }
                  ],
                  "maxBytes": 65536
                },
                "validators": [],
                "proposal": {
                  "remind": {
                    "body": {
                      "renderedBody": true
                    },
                    "kind": {
                      "literal": "general"
                    },
                    "subject": {
                      "literal": "general"
                    },
                    "reason": {
                      "literal": "reminder_requested"
                    },
                    "requestedPriority": {
                      "effective": "defaultPriority"
                    },
                    "effectivePriority": {
                      "effective": "clampedPriority"
                    },
                    "visibleForSteps": {
                      "literal": 1
                    },
                    "rejection": {
                      "literal": null
                    },
                    "memoryEvidence": {
                      "literal": []
                    },
                    "skillEvidence": {
                      "literal": null
                    }
                  },
                  "none": {
                    "body": {
                      "literal": ""
                    },
                    "kind": {
                      "literal": "general"
                    },
                    "subject": {
                      "literal": "general"
                    },
                    "reason": {
                      "literal": "none"
                    },
                    "requestedPriority": {
                      "effective": "defaultPriority"
                    },
                    "effectivePriority": {
                      "effective": "clampedPriority"
                    },
                    "visibleForSteps": {
                      "literal": 1
                    },
                    "rejection": {
                      "literal": "no_reminder"
                    },
                    "memoryEvidence": {
                      "literal": []
                    },
                    "skillEvidence": {
                      "literal": null
                    }
                  },
                  "invalidPayload": {
                    "body": {
                      "inputError": true
                    },
                    "kind": {
                      "literal": "general"
                    },
                    "subject": {
                      "literal": "general"
                    },
                    "reason": {
                      "literal": "invalid_payload"
                    },
                    "requestedPriority": {
                      "effective": "defaultPriority"
                    },
                    "effectivePriority": {
                      "effective": "clampedPriority"
                    },
                    "visibleForSteps": {
                      "literal": 1
                    },
                    "rejection": {
                      "literal": "invalid_payload"
                    },
                    "memoryEvidence": {
                      "literal": []
                    },
                    "skillEvidence": {
                      "literal": null
                    }
                  },
                  "roundEnded": {
                    "body": {
                      "literal": ""
                    },
                    "kind": {
                      "literal": "general"
                    },
                    "subject": {
                      "literal": "general"
                    },
                    "reason": {
                      "literal": "round_ended"
                    },
                    "requestedPriority": {
                      "effective": "defaultPriority"
                    },
                    "effectivePriority": {
                      "effective": "clampedPriority"
                    },
                    "visibleForSteps": {
                      "literal": 1
                    },
                    "rejection": {
                      "literal": "round_ended"
                    },
                    "memoryEvidence": {
                      "literal": []
                    },
                    "skillEvidence": {
                      "literal": null
                    }
                  },
                  "syntheticFailure": {
                    "body": {
                      "literal": ""
                    },
                    "kind": {
                      "literal": "general"
                    },
                    "subject": {
                      "literal": "general"
                    },
                    "reason": {
                      "literal": "synthetic_failure"
                    },
                    "requestedPriority": {
                      "effective": "defaultPriority"
                    },
                    "effectivePriority": {
                      "effective": "clampedPriority"
                    },
                    "visibleForSteps": {
                      "literal": 1
                    },
                    "rejection": {
                      "literal": "invalid_payload"
                    },
                    "memoryEvidence": {
                      "literal": []
                    },
                    "skillEvidence": {
                      "literal": null
                    }
                  },
                  "validatorRejections": {}
                },
                "lifecycle": {
                  "seenKey": "ordinary",
                  "eotProgressGate": "notApplicable",
                  "failureFallback": "none",
                  "installBudget": "roster"
                },
                "limits": {
                  "declarationBytes": 65536,
                  "customFields": 64,
                  "fieldNameBytes": 64,
                  "descriptionBytes": 1024,
                  "objectDepth": 4,
                  "objectFields": 32,
                  "arrayItems": 64,
                  "submittedJsonBytes": 262144,
                  "scalarStringBytes": 65536,
                  "templateBytes": 16384,
                  "slots": 64,
                  "renderedBodyBytes": 65536,
                  "memoryAdmissionReads": 64,
                  "memoryAdmissionLinesPerRead": 2000,
                  "memoryAdmissionExaminedBytesPerRead": 100000,
                  "memoryAdmissionReturnedBytesPerRead": 100000,
                  "memoryAdmissionExaminedBytesPerDecision": 6400000,
                  "memoryAdmissionReturnedBytesPerDecision": 6400000
                }
              }
            }
          ]
        }
      },
      "files": {
        "reminders/review-policy.md": "Check the requested files before reporting completion.\n"
      }
    }
  ],
  "mixedExample": {
    "manifest": {
      "schemaVersion": 1,
      "name": "mixed-example",
      "displayName": "Mixed Example",
      "version": "0.1.0",
      "description": "One example of every supported native capability.",
      "compat": {
        "source": "native",
        "manifestDir": ".muse-plugin"
      },
      "capabilities": {
        "skills": [
          {
            "id": "review",
            "path": "skills/review/SKILL.md",
            "enabledDefault": false
          }
        ],
        "commands": [
          {
            "id": "summarize",
            "path": "commands/summarize.md",
            "enabledDefault": true
          }
        ],
        "hooks": [
          {
            "id": "pre-check",
            "event": "PreToolUse",
            "command": [
              "sh",
              "hooks/pre-check.sh"
            ],
            "timeoutMs": 1000,
            "statusMessage": "Checking plugin policy"
          }
        ],
        "mcpServers": [
          {
            "id": "workspace-index",
            "transport": "stdio",
            "command": [
              "python3",
              "mcp/server.py"
            ]
          }
        ],
        "reminders": [
          {
            "id": "review-policy",
            "path": "reminders/review-policy.md",
            "tools": [
              "read_file"
            ],
            "blocking": false,
            "decision": {
              "version": 1,
              "envelope": {
                "version": 1,
                "template": "<system-reminder>\n{text}\n</system-reminder>"
              },
              "deliveryRole": "developer",
              "fields": [
                {
                  "name": "text",
                  "description": "Reminder body text.",
                  "requirement": "remind",
                  "shape": {
                    "type": "string",
                    "minBytes": 1,
                    "maxBytes": 2000
                  }
                }
              ],
              "bodyTemplate": {
                "text": "{text}",
                "slots": [
                  {
                    "name": "text",
                    "source": {
                      "field": "text"
                    },
                    "escape": "xml",
                    "fallback": ""
                  }
                ],
                "maxBytes": 65536
              },
              "validators": [],
              "proposal": {
                "remind": {
                  "body": {
                    "renderedBody": true
                  },
                  "kind": {
                    "literal": "general"
                  },
                  "subject": {
                    "literal": "general"
                  },
                  "reason": {
                    "literal": "reminder_requested"
                  },
                  "requestedPriority": {
                    "effective": "defaultPriority"
                  },
                  "effectivePriority": {
                    "effective": "clampedPriority"
                  },
                  "visibleForSteps": {
                    "literal": 1
                  },
                  "rejection": {
                    "literal": null
                  },
                  "memoryEvidence": {
                    "literal": []
                  },
                  "skillEvidence": {
                    "literal": null
                  }
                },
                "none": {
                  "body": {
                    "literal": ""
                  },
                  "kind": {
                    "literal": "general"
                  },
                  "subject": {
                    "literal": "general"
                  },
                  "reason": {
                    "literal": "none"
                  },
                  "requestedPriority": {
                    "effective": "defaultPriority"
                  },
                  "effectivePriority": {
                    "effective": "clampedPriority"
                  },
                  "visibleForSteps": {
                    "literal": 1
                  },
                  "rejection": {
                    "literal": "no_reminder"
                  },
                  "memoryEvidence": {
                    "literal": []
                  },
                  "skillEvidence": {
                    "literal": null
                  }
                },
                "invalidPayload": {
                  "body": {
                    "inputError": true
                  },
                  "kind": {
                    "literal": "general"
                  },
                  "subject": {
                    "literal": "general"
                  },
                  "reason": {
                    "literal": "invalid_payload"
                  },
                  "requestedPriority": {
                    "effective": "defaultPriority"
                  },
                  "effectivePriority": {
                    "effective": "clampedPriority"
                  },
                  "visibleForSteps": {
                    "literal": 1
                  },
                  "rejection": {
                    "literal": "invalid_payload"
                  },
                  "memoryEvidence": {
                    "literal": []
                  },
                  "skillEvidence": {
                    "literal": null
                  }
                },
                "roundEnded": {
                  "body": {
                    "literal": ""
                  },
                  "kind": {
                    "literal": "general"
                  },
                  "subject": {
                    "literal": "general"
                  },
                  "reason": {
                    "literal": "round_ended"
                  },
                  "requestedPriority": {
                    "effective": "defaultPriority"
                  },
                  "effectivePriority": {
                    "effective": "clampedPriority"
                  },
                  "visibleForSteps": {
                    "literal": 1
                  },
                  "rejection": {
                    "literal": "round_ended"
                  },
                  "memoryEvidence": {
                    "literal": []
                  },
                  "skillEvidence": {
                    "literal": null
                  }
                },
                "syntheticFailure": {
                  "body": {
                    "literal": ""
                  },
                  "kind": {
                    "literal": "general"
                  },
                  "subject": {
                    "literal": "general"
                  },
                  "reason": {
                    "literal": "synthetic_failure"
                  },
                  "requestedPriority": {
                    "effective": "defaultPriority"
                  },
                  "effectivePriority": {
                    "effective": "clampedPriority"
                  },
                  "visibleForSteps": {
                    "literal": 1
                  },
                  "rejection": {
                    "literal": "invalid_payload"
                  },
                  "memoryEvidence": {
                    "literal": []
                  },
                  "skillEvidence": {
                    "literal": null
                  }
                },
                "validatorRejections": {}
              },
              "lifecycle": {
                "seenKey": "ordinary",
                "eotProgressGate": "notApplicable",
                "failureFallback": "none",
                "installBudget": "roster"
              },
              "limits": {
                "declarationBytes": 65536,
                "customFields": 64,
                "fieldNameBytes": 64,
                "descriptionBytes": 1024,
                "objectDepth": 4,
                "objectFields": 32,
                "arrayItems": 64,
                "submittedJsonBytes": 262144,
                "scalarStringBytes": 65536,
                "templateBytes": 16384,
                "slots": 64,
                "renderedBodyBytes": 65536,
                "memoryAdmissionReads": 64,
                "memoryAdmissionLinesPerRead": 2000,
                "memoryAdmissionExaminedBytesPerRead": 100000,
                "memoryAdmissionReturnedBytesPerRead": 100000,
                "memoryAdmissionExaminedBytesPerDecision": 6400000,
                "memoryAdmissionReturnedBytesPerDecision": 6400000
              }
            }
          }
        ]
      }
    },
    "files": {
      "skills/review/SKILL.md": "---\nname: review\ndescription: Review the current workspace.\n---\n\nReview the requested files and report concrete findings.\n",
      "commands/summarize.md": "---\ndescription: Summarize a requested change\nargument-hint: <path>\n---\nSummarize $ARGUMENTS with file references.\n",
      "hooks/pre-check.sh": "#!/bin/sh\nprintf '%s\\n' ok\n",
      "mcp/server.py": "import sys\nfor line in sys.stdin:\n    sys.stdout.write(line)\n    sys.stdout.flush()\n",
      "reminders/review-policy.md": "Check the requested files before reporting completion.\n"
    }
  }
}
skills/create-plugin/references/native-plugin-contract.md# Native Muse Plugin Contract

This reference summarizes the manifest accepted by the current Muse validator.
The Plugin Creator instructions remain authoritative for reservation, mutation,
validation order, correction limits, and reporting.

## Package Layout

A native plugin is a new directory in the current workspace. Its manifest is:

```text
.muse-plugin/plugin.json
```

Every file named by a capability is relative to the plugin root. A minimal manifest
contains:

```json
{
  "schemaVersion": 1,
  "name": "example-plugin",
  "displayName": "Example Plugin",
  "version": "0.1.0",
  "description": "One plain-language sentence.",
  "compat": {
    "source": "native",
    "manifestDir": ".muse-plugin"
  },
  "capabilities": {
    "skills": [],
    "commands": [],
    "hooks": [],
    "mcpServers": [],
    "reminders": []
  }
}
```

Use only fields required by the request. The installed validator decides whether an
omitted optional field is acceptable.

## Identifiers

Plugin and capability IDs use this portable grammar:

```text
^[a-z0-9][a-z0-9._-]{0,79}$
```

The basename before the first dot must not case-fold to `CON`, `PRN`, `AUX`, `NUL`,
`COM1` through `COM9`, or `LPT1` through `LPT9`. Plugin IDs `loop` and `muse-core`
are reserved by the product bundle.

## Paths

- Use relative UTF-8 paths and `/` separators in the manifest.
- Reject absolute paths, parent traversal, backslashes, and blank paths.
- Create every referenced file before validation.
- Canonicalize containment; a symlink must not escape the plugin or workspace root.
- Keep generated component names portable across macOS, Linux, and Windows.

## Capability Fields

### Skills

```json
{"id":"review","path":"skills/review/SKILL.md","enabledDefault":false}
```

The target is a UTF-8 `SKILL.md` with valid frontmatter. `enabledDefault` is
optional; omit it only when the requested activation behavior is clear.

### Commands

```json
{"id":"summarize","path":"commands/summarize.md","enabledDefault":true}
```

The target is a UTF-8 Markdown command template.

### Hooks

```json
{
  "id":"pre-check",
  "event":"PreToolUse",
  "command":["sh","hooks/pre-check.sh"],
  "timeoutMs":1000,
  "statusMessage":"Checking plugin policy"
}
```

The command is structured argv, not a shell string. If an argv element names a
relative source path, that regular file must exist beneath the plugin root. Hook
source paths cannot be shared by two hook IDs.

### MCP Servers

For a local stdio server:

```json
{
  "id":"workspace-index",
  "transport":"stdio",
  "command":["python3","mcp/server.py"]
}
```

`transport` defaults to `stdio`. An HTTP transport instead requires a non-empty
`url`; do not invent an endpoint. A custom model tool is exposed by an MCP server,
not by a direct `tools` capability.

### Reminders

```json
{
  "id":"review-policy",
  "path":"reminders/review-policy.md",
  "tools":["read_file"],
  "blocking":false,
  "decision":{
    "version":1,
    "envelope":{"version":1,"template":"<system-reminder>\n{text}\n</system-reminder>"},
    "deliveryRole":"developer",
    "...":"copy the remaining executable fields from capability-examples.json"
  }
}
```

The duty file must exist and be UTF-8. `decision` is required, including its V1
`envelope` and `deliveryRole` authority. Optional policy
fields are `defaultPriority`, `maxPriority`, `maxChildSteps`,
`maxInstallsPerRun`, `reasoningEffort`, and `context`. Add them only when
requested and after checking the executable examples.

## Unsupported Families

The validator rejects direct capability keys `tools`, `agents`, `outputStyles`,
`settings`, and `apps`. Do not translate them into guessed fields. Ask the user to
restate a custom tool as an MCP server when that matches their intent.

## Validation

Run each generated skill first:

```json
["muse","skills","validate","<skill-directory>","--json"]
```

Then run the plugin validator:

```json
["muse","plugins","validate","<plugin-directory>","--json"]
```

A result is clean only when the process starts, exits zero, returns parseable JSON,
sets top-level `valid` to `true`, and returns an empty `diagnostics` array. Warnings
are failures for creation. Correct one validation layer at a time, with no more than
three correction rounds after its first failed result.

## Creation Boundary

Reserve one absent destination with a native atomic no-replace directory creation
before writing artifacts. Recheck canonical workspace containment immediately after
reservation. Stop on occupancy, denial, cancellation, or any failed containment
check. Never install, enable, trust, execute, fetch, update, or publish the draft.
