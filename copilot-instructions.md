# Copilot Instructions

Purpose: Define the mandatory engineering, architecture, documentation, and testing rules for all AI-assisted changes in this repository.

## Scope

- Applies to all code, scripts, YAML data, templates, docs, and generated-output workflows in this repository.
- Applies to all contributors: human developers, VS Code agents, and GitHub Copilot.

## Core Engineering Principles

- Follow The Pragmatic Programmer mindset in all changes.
- Enforce DRY: remove duplication by extracting reusable helpers or shared content.
- Prefer simple, deterministic, linear logic over clever abstractions.
- Avoid deep nesting; extract helper functions when branching grows.
- Keep state minimal and explicit.
- Prefer immutable update patterns where practical.
- Optimize for readability and maintainability first.

## Naming and Structure Standards

- Use explicit, descriptive names for files, functions, variables, and symbols.
- Prefer clarity over brevity; avoid ambiguous abbreviations.
- One file should have one clear responsibility.
- One module should represent one conceptual domain.
- Keep public interfaces small, stable, and obvious.

## Repository Architecture Rules

- Use feature-based organization for new architecture work.
- A feature should own its own:
  - UI (if applicable)
  - logic
  - data access
  - tests
- Put shared cross-feature logic only in shared or core locations.
- Do not hide shared behavior inside feature-local files.

## Command Service Layer (Critical)

- Do not create new CLI commands or API endpoints directly in feature modules.
- Route command creation through a Command Service Layer.
- The Command Service Layer is responsible for:
  - defining CLI/API entry points
  - validating inputs
  - enforcing architecture boundaries
  - dispatching to feature modules
  - handling consistent error mapping
- Copilot must never bypass this layer.

### Current Repository Mapping

- For this repository today, treat [scripts/render-syllabi.ps1](scripts/render-syllabi.ps1) as the command orchestration boundary for syllabus rendering.
- Use [package.json](package.json) scripts and [.vscode/tasks.json](.vscode/tasks.json) tasks as user-facing command surfaces.
- Do not duplicate render command behavior in ad hoc scripts unless explicitly requested.

## Error Handling Requirements

- Handle errors explicitly and predictably.
- Never swallow exceptions silently.
- Return or log meaningful error messages with actionable context.
- Document assumptions, invariants, and constraints where failures may occur.
- Fail fast on invalid input.

## Documentation Requirements

- Every source file should begin with a short purpose statement when possible for that file type.
- Comments should explain why, not what.
- Document edge cases, invariants, and constraints.
- Keep comments concise, precise, and relevant.
- Keep operational docs current when behavior changes.

## Testing Expectations

- Tests must be deterministic, isolated, and readable.
- Cover normal paths and edge cases.
- Prefer explicit setup over implicit fixtures.
- Use mocks only when necessary and keep them minimal.
- Do not add test-only production hooks unless explicitly approved.

## Copilot Behavior Rules

- Apply all rules in this file before generating code.
- Ask for clarification when requirements are ambiguous.
- Match existing project patterns before introducing new structure.
- Do not hallucinate APIs, modules, or commands.
- Do not rewrite existing code unless explicitly requested.
- Prefer append-only changes when expanding architecture or codex docs.
- Keep edits minimal and scoped to the request.

## Codex and Pattern Consistency

- Follow existing project conventions from:
  - [README.md](README.md)
  - [docs/NEW-COMPUTER-SETUP.md](docs/NEW-COMPUTER-SETUP.md)
  - [docs/WORKFLOW-GUIDE.md](docs/WORKFLOW-GUIDE.md)
- Preserve established naming, module boundaries, and renderer workflow.
- Do not introduce new architectural patterns without explicit approval.

## Change Control Guidance

- Before modifying shared behavior, identify all affected classes and outputs.
- Regenerate and validate outputs after renderer or template changes.
- Keep generated-output edits traceable to source/template changes.
- Record policy/process changes in repository docs when applicable.
