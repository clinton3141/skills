# Persona reviews are one skill, separate from spec review and codebase audit

The four persona reviews (Chad, Clive, Jimmy, Poindexter) live in a single `persona-review` skill, with each persona's criteria, voice and output format in its own reference file, rather than as five skills. The old `review-all` kept a condensed copy of every persona's criteria that drifted from the originals, and five descriptions crowded the agent's context; one skill gives one source of truth per persona at the cost of the short `/review-chad`-style commands. A sweep is deliberately shallow, since depth comes from running a single persona afterwards.

## Considered Options

- **Prefix-namespaced skills** (`persona-review-chad`, …): groups them in listings but keeps five descriptions and the duplicated criteria.
- **Folding personas into `spec-review` or `intensive-full-review`**: rejected because the three serve different readers. A persona review is for a human reviewing their own or someone else's code; a spec review is an agent checking its own implementation; a codebase audit keeps agent-architected code cohesive. Their criteria overlap, but merging them would blur who each one is for.
