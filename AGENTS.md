# Project Structure

The project is structured as a monorepo with separate directories for each library. Similar to monorepos in node.js `packages` directory we have `libs` directory with separate subdirectories for each library.

### Lunart

code: `libs/lunart`;

An ergonomic HTTP client for Dart. The goal of the project is to be very lean (no unnecessary dependencies, minimal overhead) but extensible.

### Artiform

code: `libs/artiform`

An expressive orm for dart. Same as lunart but with a more expressive API meaning support for code generation for more extensive ORM features.

---

Each project will have a directory structure like the following:

```
lib/       // Source code of the library
tests/     // Unit tests for the library
examples/  // Example usage of the library
```

# Commands

- `mise run test`: Run the test suite for the project
- `mise run test_lunart`: Run the test suite for lunart project

# Dart Coding Guidelines

- Prioritize code correctness and clarity. Speed and efficiency are secondary priorities unless otherwise specified.
- Do not write organizational or comments that summarize the code. Comments should only be written in order to explain "why" the code is written in some way in the case there is a reason that is tricky / non-obvious.
- Prefer implementing functionality in existing files unless it is a new logical component. Avoid creating many small files.
- Use full words for variable names (no abbreviations like "q" for "queue")
- Avoid creative additions unless explicitly requested
- Never disregard null-safety. Always use null-safe operators and null checks when appropriate.
- Prefer using the new dart Primary Constructor over the old-style constructor syntax. Here's the doc if you're not familiar with it: https://dart.dev/language/primary-constructors
- Prefer using newer dart language features.
- Always respect the existing codebase and conventions. Always follow them to the tee.
- Do not install any dependencies yourself. Just tell the user which dependencies are required and let them install them themselves if they want.

# Test Guidelines

- Strictly follow the dart coding guidelines mentioned above.
- Write unit tests for all non-trivial logic, including success paths, edge cases, and failure scenarios.
- Keep tests deterministic and isolated: avoid real network, file system, database, time, or randomness dependencies unless explicitly required.
- Structure tests using Arrange / Act / Assert, with clear separation of setup, execution, and verification.
- Use descriptive test names that state behavior and expected outcome (for example: `returnsEmptyListWhenNoItemsExist`).
- Assert observable behavior, not internal implementation details, so refactors do not break valid tests.
- Use fixtures, fakes, and mocks sparingly and intentionally; prefer simple fakes over complex mock setups when possible.
- Keep each test focused on one behavior and avoid large multi-purpose tests.
- Include null-safety scenarios where relevant (for example, null inputs, optional values, and fallback behavior).
- Prefer readability over cleverness in test code; tests are documentation for future maintainers.
- Ensure tests are reliable and fast enough to run frequently in local development and CI.
- If the request is for a new feature or change, Always ask if the test is required before implementing and always show what the unit tests will cover.
- When asked to write test please always present all the test cases to the user and confirm with them before writing the test.
- Do not write comments. Unless it's absolutely necessary to explain the test logic.
- When the user asks for you to write test. Don't overwrite the existing test file append to it.

# Additional Notes

- The user will always specify the project they are working on. If they don't specify just ask them about it.
- Do not read the whole codebase just focus on the project specified by the user.
- Don't spit out random md files unless explicitly requested.
