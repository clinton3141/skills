# Reading and marking proofs

Read this when the user submits a proof, a partial argument, or a piece of mathematical writing for feedback.

## Contents

- How to read (the passes)
- Severity tiers and how to phrase them
- Error patterns that recur, by area
- What to do after a correct proof
- Marking mathematical prose

---

## How to read

Three passes, in this order. Skipping the first is how gaps get approved.

**Pass 1 — Does it prove the claim?** Ignore rigour for a moment. What is the strategy? Does the strategy, if executed perfectly, establish the stated result? A large fraction of flawed proofs prove something adjacent: a special case, the converse, a weaker statement, or the same statement under an extra assumption smuggled in silently.

**Pass 2 — Line by line.** Every assertion: is it justified, and is the justification valid? Every "clearly", "obviously", "it follows that", "similarly" is a claim about the reader's obligations — check whether it's honest. Every case split: is it exhaustive?

**Pass 3 — Hypothesis audit.** Where is each hypothesis used? Mark them off as you find them. An unused hypothesis is a signal — either the student has proved something stronger than asked (say so, it's good news) or they've made an error that made the hypothesis look unnecessary. This audit catches errors nothing else catches.

## Severity tiers

Always label which tier a comment belongs to. The student needs to know whether they have to start over or tidy up.

**Fatal.** The proof does not establish the claim. Do not soften this and do not bury it under style points. Name the precise step, say what is wrong with it, and say whether the strategy is salvageable. If the strategy is dead, say so — letting someone patch a doomed argument for another hour is unkind, not encouraging.

**Gap.** The claim is probably true and the strategy probably works, but there is an unjustified step. Distinguish gaps the student can close in a line from gaps that hide a real difficulty. The second kind is often the actual content of the problem.

**Style.** Correct but improvable. Worth raising, but clearly flagged as secondary — never lead with style when there's a gap. At postgraduate level style matters more than most students think, because it's what referees and examiners respond to.

Phrase criticism as a question about the mathematics where possible: "why does the limit commute with the sum here?" is more useful than "you can't do that", because it points at what needs justifying.

## Error patterns

### Universal

- **Quantifier order.** $\forall \varepsilon \exists N$ versus $\exists N \forall \varepsilon$ — pointwise versus uniform, in whatever costume the subject dresses it up in. Check every alternation.
- **Circularity.** Using the result, or a consequence of it, in its own proof. Common when the student has internalised the statement.
- **Assuming the conclusion.** Especially in inequality manipulation started from the thing to be proved. If they work downwards from the goal, check every step is reversible or that the direction is stated.
- **Well-definedness.** Anything defined on equivalence classes, quotients, or by a choice of representative, basis, chart, or lift. Silently skipped more often than any other obligation.
- **Existence assumed.** Objects introduced with "let $x$ be..." that may not exist, or may not be unique.
- **Edge cases.** Empty set, zero, trivial group, $n = 0$ or $1$, the degenerate configuration.
- **"WLOG" doing real work.** Legitimate only when there's an actual symmetry or reduction. Ask them to say what the reduction is.
- **Induction errors.** Base case wrong or missing; induction hypothesis too weak; strong versus ordinary induction confused; induction on the wrong parameter.

### Analysis

Interchange of limits, sums, integrals, and derivatives without justification (dominated convergence, uniform convergence, Fubini–Tonelli hypotheses). Uniform versus pointwise anything. Choosing $\varepsilon$ or $N$ in a way that secretly depends on a variable quantified later. Sets of measure zero handled loosely. Completeness or compactness assumed where it isn't given.

### Algebra

Non-commutativity used commutatively. Homomorphism properties assumed of arbitrary maps. Finiteness assumptions imported silently. Confusing an isomorphism that exists with a natural or canonical one. Universal properties invoked without checking uniqueness. Localisation and quotient constructions applied without checking the required hypotheses on the ring.

### Topology and geometry

Confusing "closed" with "not open". Sequences used where nets are needed (non-first-countable spaces). Compactness arguments where the cover isn't produced explicitly. Local-to-global steps that need paracompactness, connectedness, or a partition of unity. Smoothness or transversality assumed rather than checked.

### Category theory

Naturality claimed but not verified — the square is the content, not decoration. Size issues glossed over (small versus locally small versus large). Assuming limits or colimits exist. Confusing a universal property with a construction, or forgetting that a universal property determines an object only up to canonical isomorphism. Functoriality in the wrong variable; forgetting contravariance.

### Combinatorics and probability

Double counting without a bijection stated. Independence assumed. Conditioning on events of probability zero. Union bound applied where the events aren't handled correctly. Asymptotic notation used as though it were an equation.

### Logic and set theory

Choice used without acknowledgement (relevant when the context cares). Confusing a theory with its models, or provability with truth. Diagonal arguments applied where the construction isn't legitimately available.

## After a correct proof

Say clearly that it's correct — unhedged. Then extend, because this is where postgraduate development actually happens:

- Where was each hypothesis used, and can any be weakened or dropped?
- Is the converse true? If not, what's the counterexample?
- Does the argument generalise — to a wider class of objects, to higher dimensions, to a different category?
- Is there a shorter or more conceptual proof? If you know one, show it and compare.
- What is the argument *really* using? Often a proof that looks specific is an instance of a general principle worth naming.
- Can they now state and prove a related result unaided?

Pick one or two of these, not all six.

## Marking mathematical prose

At MSc and PhD level, writing is assessed. Comment on it, briefly, when there's something to say:

- Every object introduced before use; every symbol quantified
- The reader told the strategy before the details, for any proof over a paragraph
- Proof structure visible — cases labelled, claims stated as claims
- Sentences, with verbs and full stops, not strings of symbols
- Displayed equations used for the ones that matter, inline for the rest
- Consistent notation; nothing overloaded
- No "it is easy to see" unless it genuinely is
- The proof ends where the claim is established, not three lines later

Recommend a good model text in their area rather than abstract advice — imitation teaches mathematical writing better than rules do.
