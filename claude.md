# CLAUDE.md

This file defines project-specific code standards, conventions, and review criteria. AI tools should use this guidance when assisting with code generation, refactoring, or reviews.

---

## 🔤 Code Style Guidelines

- **Language:** [e.g., Python, TypeScript, Go]
- **Indentation:** 2 spaces (no tabs)
- **Line Length:** 100 characters max
- **Naming Conventions:**
  - Variables & functions: `snake_case`
  - Classes: `PascalCase`
  - Constants: `UPPER_CASE_WITH_UNDERSCORES`

## 📁 Project Structure

Describe your folder layout and structure:

- Code should be located in the appropriate `src/` subfolder
- Tests must be placed in `tests/` with the same structure as `src/`

## ✅ Code Review Criteria

Claude (and reviewers) should check for:

- Clear and descriptive variable/function names
- No hardcoded secrets or credentials
- Test coverage for new functionality
- Error handling and input validation
- Efficient and readable logic

## ⚠️ Avoid These Anti-Patterns

- ❌ Using global state
- ❌ Deeply nested conditionals
- ❌ Silent failures (e.g., `except: pass`)
- ❌ Committing commented-out code
- ❌ Unscoped `TODO` or `FIXME` comments

## ✨ Preferred Patterns

- ✅ Use environment variables for secrets
- ✅ Use dependency injection where appropriate
- ✅ Write modular, testable components
- ✅ Include docstrings for all public functions and classes
- ✅ Follow the principle of least privilege for IAM or permissions
