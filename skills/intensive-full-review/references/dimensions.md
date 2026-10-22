# Review dimensions

Each section below is pasted whole into one sub-agent's brief. Every dimension is a lens on the same code; a finding belongs to the dimension whose fix it needs, not every dimension it touches.

## Severity rubric

Shared by every dimension; paste it with each section.

- **critical**: data loss, security breach, or a crash on a common path. Fix before the next release.
- **high**: wrong behaviour a user can reach, or a defect that blocks safe change to a core module.
- **medium**: wrong behaviour on an edge path, or friction that slows every change in its area.
- **low**: local clarity or tidiness; worth fixing when passing through.

## Correctness

Code that does the wrong thing. Hunt: off-by-one and boundary errors; unhandled `null`/`undefined`/empty cases; wrong operator or inverted condition; state mutated where callers assume it is not; race conditions and unawaited promises; resource leaks; time zone, locale, float and integer-overflow traps; error paths that swallow, mis-report or leave state half-written; logic that contradicts its own name, comment, test or the domain rules in `GLOSSARY.md`.

Every finding needs a concrete triggering input or sequence and the wrong result it yields. Without one it is a suspicion, not a finding.

## Complexity

Code harder to understand or change than its job requires. Hunt: long functions and deep nesting; high branch counts; boolean-flag parameters that switch a function between jobs; cleverness where a plain form exists; **shallow modules** whose interface is nearly as complex as their implementation, and the reverse, one module doing several unrelated jobs. Call the Skill tool with `codebase-design` for the vocabulary (**module**, **interface**, **depth**, **seam**, **locality**) and use its terms in findings.

Cite the measure (line count, nesting depth, number of branches or parameters) and name the simpler shape.

## Code smells

The Fowler baseline (_Refactoring_, ch. 3): paste the smell baseline from step 3 of `../spec-review/SKILL.md` (relative to this skill's folder) here when briefing, since that is its single source of truth. Each smell is a judgement call, labelled as "possible <smell>", and a house rule that endorses the pattern suppresses it.

Add the whole-codebase smells a diff review cannot see: **Dead Code** (unexported and uncalled, or behind a flag that is always one value), **Lazy Element**, **Global Data**, **Mutable Data** shared across modules, **Large Class / Module**, **Loops** that a pipeline would state more plainly.

## Architecture and consistency

The codebase disagreeing with itself. Hunt: two or more ways of doing the same thing (state management, data fetching, error reporting, configuration, logging, validation) with no reason recorded for the split; dependencies that point the wrong way across layers or leak a module's internals past its **seam**; a concept named differently in different modules, or differently from `GLOSSARY.md`; code that contradicts an ADR; directory layout that disagrees with the module boundaries the code actually has.

For each inconsistency, name the dominant convention (count the sites on each side) and treat the minority as the finding, unless the minority is the newer, deliberate direction, in which case the finding is the unfinished migration.

## Idiom

Code that fights its language or framework instead of using its canonical paradigm. Judge against the versions pinned in the manifest, not the latest. Hunt: hand-rolled versions of standard-library or framework features; framework lifecycle or data-flow rules worked around (effects for derived state in React, manual DOM in a component framework, blocking calls in async code); deprecated APIs with a supported replacement; type-system escape hatches (`any`, casts, `!`, `# type: ignore`) where a sound type exists; error handling against the language's grain (exceptions for control flow, ignored `Result`s); naming and layout against the ecosystem's convention.

Cite the canonical form, with a link to the official docs for that version where one exists.

## Error handling and resilience

Failure paths. Hunt: errors caught and dropped; generic catch-alls that hide the cause; missing timeouts and retries on network or IO calls, or retries without backoff; partial writes with no rollback; user-facing errors that leak internals or say nothing actionable; process-level crashes from one bad request; missing validation at trust boundaries (user input, network, files, env).

## Security

Hunt: injection (SQL, shell, path, HTML/XSS, template); secrets in source, logs or client bundles; missing authentication or authorisation checks on a route or handler; unsafe deserialisation; permissive CORS, cookies without `Secure`/`HttpOnly`/`SameSite`; weak or hand-rolled crypto; dependencies with known advisories (run the ecosystem's audit command). Describe the class of flaw and its location; leave out working exploit payloads, since the issue may be public.

## Performance

Only where the cost is real at the project's scale. Hunt: work repeated in a loop or render that could be hoisted or memoised; N+1 queries; unbounded growth (caches, listeners, arrays); synchronous IO on a hot path; oversized client bundles or eager loading of rarely used code; algorithmic complexity worse than the data size allows.

State the path and the input size at which it bites; a micro-optimisation on a cold path is not a finding.

## Tests

The test suite as a safety net. Hunt: core behaviour with no test; tests that assert on implementation details and break on any refactor; tests that cannot fail (no assertion, assertion on a mock's own return); flaky patterns (sleeps, real clocks, order dependence, shared state); slow tests that belong at a cheaper level; test code duplicating production logic to compute the expected value. Respect the project's documented test strategy (ADRs, `CLAUDE.md`).

## Dependencies and build

Hunt: unused dependencies; dependencies duplicated in different versions or overlapping in purpose; packages pinned far behind with breaking-change or security consequences; dev dependencies shipped to production; build, lint or type-check warnings left standing; scripts that no longer run.

## Documentation drift

Prose that no longer matches the code. Hunt: README setup or commands that fail; comments that describe what the code used to do; `GLOSSARY.md` terms the code no longer uses, or concepts the code uses that it lacks; ADRs whose decision the code has since reversed without a superseding ADR; public API docs that disagree with signatures.
