# Repository Guidelines

## Project Structure & Module Organization
`.claude/` hosts the agent runtime: `helpers/` ships Node utilities such as `github-safe.js`, and `agents/` stores prompt templates. `coordination/` keeps orchestration stubs, while `memory/` holds run artefacts—treat `memory/sessions/` as disposable and secret-free. Infrastructure code resides in `terraform/`, local automation in `scripts/`, reference material in `docs/`, and validation records in `tests/`.

## Build, Test, and Development Commands
Run `npm install` once per workspace. Format files with `npm run format`; use `npm run format:check` in CI. Lint `.claude/**/*.js` through `npm run lint:js`, enforce the security rules with `npm run lint:security`, or run both plus an `npm audit` via `npm run security:check`. `npm test` exercises the harness, and `npm run test:security` verifies the GitHub helper. Terraform updates require `terraform fmt -check -recursive` and `terraform validate` from inside `terraform/`. When touching dependencies or secret handling, run `scripts/audit-dependencies.sh` and `scripts/check-secrets-patterns.sh` before opening a pull request.

## Coding Style & Naming Conventions
Prettier enforces two-space indentation, LF line endings, single quotes, and no semicolons for JavaScript; keep filenames kebab-case and exports camelCase. Shell scripts begin with `#!/bin/bash` and `set -euo pipefail`, using snake_case helpers that remain idempotent. Terraform follows the layout in `CONTRIBUTING.md`, with snake_case identifiers and descriptive variable names. Branch names comply with the documented prefixes (`feature/`, `fix/`, `docs/`, `security/`).

## Testing Guidelines
Co-locate executable tests with the code they cover (for example `.claude/helpers/github-safe.test.js`) and capture additional evidence in `tests/`. Run `npm test`, `npm run test:security`, and the relevant Terraform commands for every change set; include noteworthy outputs in the pull request when a tool reports a waiver. Expand coverage alongside new automation by adding a happy-path and failure-path check for each helper or module.

## Commit & Pull Request Guidelines
Use Conventional Commits (`feat:`, `fix:`, `chore:`, `security:`) as shown in `git log`, keeping each commit focused. Pull requests should summarise intent, link issues, list the commands you ran, and include screenshots or logs for workflow changes. Ensure MegaLinter and security checks pass, request security review for IAM or secret changes, and paste `terraform plan` excerpts whenever infrastructure code is modified.

## Security & Configuration Tips
Review `SECURITY.md` before editing policies and run `scripts/validate-github-workflows.sh` after touching CI definitions. Never commit secrets; rely on ignored variables files or environment injection. Document any accepted risk in the pull request so reviewers can trace the decision.
