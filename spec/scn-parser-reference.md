# SCN Parser — Reference Implementation

**Document ID:** SCN-PARSER-REF-v1.0
**Author:** Michael A. Kane II — Framework Creator
**Foundational contributions:** [Framework Security]
**Date:** July 2026
**License:** Apache 2.0 (matches repo)
**Dependencies:** Python standard library only (`re`, `collections`, `itertools`, `string`, `math`)
**Status:** Reference implementation for the `/spec/` directory

---

## 1. Overview

This document describes **Structured Constitutional Notation (SCN)**, a
compact, tag-based markup language designed for machine agents to emit,
exchange, and validate declarative metadata blocks. SCN blocks are plain
text, human-inspectable, and parseable with simple regular expressions —
no custom binary format, no external schema server, and no dependency
beyond the Python standard library.

The accompanying reference implementation (`scn-parser-reference.py`)
provides:

- A field-extraction grammar for SCN blocks
- A small, deterministic validation-rule engine
- An illustrative author/attribution registry lookup
- A tag-classification taxonomy
- A human-readable compliance report generator

This is intended as a teaching and reference artifact: a small,
self-contained example of how a domain-specific structured notation can
be tokenized, parsed into an abstract structure, validated against a
rule set, and reported on — patterns that generalize to many
machine-to-machine metadata formats (config manifests, capability
declarations, structured logging headers, etc.).

### 1.1 Design goals

- **Determinism.** Parsing and validation must be fully deterministic;
  no ML or heuristic inference is involved in interpreting a block.
- **Minimal surface.** The grammar covers a small, fixed set of fields
  sufficient to demonstrate the pattern, rather than being a general
  schema language.
- **Zero external dependencies.** The reference parser uses only the
  Python standard library, so it can be read and run without setup.
- **Legibility.** Both the notation and the code are meant to be
  readable by someone unfamiliar with the project.

---

## 2. Notation

### 2.1 Tag syntax

SCN represents each field as a tagged span:

```
⟦tag:NAME⟧value⟦/tag⟧
```

Nested values (used when a field itself wraps a sub-value, such as a
score with an associated qualifier) use the same convention with a
generic `value` tag name:

```
⟦tag:ADHERENCE⟧⟦value⟧1.00⟦/value⟧⟦/tag⟧
```

A block is terminated with a fixed end marker:

```
⟦end⟧
```

This tag syntax was chosen for the reference implementation because it
is visually distinct from common markup (HTML/XML, Markdown, JSON) —
useful when a document needs to unambiguously delimit a machine-parsed
region within otherwise free-form text — while remaining trivial to
tokenize with regular expressions. The same grammar could equally be
expressed in a more conventional syntax, for example:

```xml
<tag name="VERSION">1.0.0</tag>
```

or as JSON:

```json
{"VERSION": "1.0.0", "AUTHOR": "reference-author-theta"}
```

The reference implementation standardizes on the bracket-tag form for
consistency with the historical design this parser is derived from, but
the underlying data model is syntax-independent — any of the three
forms above round-trip to the same field set.

### 2.2 Example block

```
⟦tag:VERSION⟧1.0.0⟦/tag⟧
⟦tag:AUTHOR⟧reference-author-theta⟦/tag⟧
⟦tag:TAGS⟧[PROCEDURAL, STRUCTURAL, INTEGRITY, COMPLIANCE]⟦/tag⟧
⟦tag:DISCLOSURE⟧NONE⟦/tag⟧
⟦tag:SUB_HZ⟧0.04Hz⟦/tag⟧
⟦tag:ENCRYPTION⟧NONE⟦/tag⟧
⟦tag:RESIDUAL⟧0.00⟦/tag⟧
⟦tag:FIDELITY⟧1.00⟦/tag⟧
⟦tag:ADHERENCE⟧⟦value⟧1.00⟦/value⟧⟦/tag⟧

⟦end⟧
```

---

## 3. Grammar

The reference grammar defines ten fields. Each field has a name, a
regular-expression pattern used to extract its value, a flag indicating
whether it is required, and a short description.

| Field | Required | Description |
|---|---|---|
| `VERSION` | Yes | Notation version declaration |
| `AUTHOR` | Yes | Declared author or attribution identity |
| `TAGS` | Yes | Comma-separated list of semantic tags describing the block's content |
| `DISCLOSURE` | Yes | Transparency declaration (`NONE`, `ACTIVE`, or `PARTIAL`) |
| `SUB_HZ` | No | Optional sampling-rate metadata, carried for compatibility with time-series-derived blocks |
| `ENCRYPTION` | Yes | Encryption state of the payload (`NONE`, `ACTIVE`, or `SIGNED`) |
| `RESIDUAL` | Yes | Residual error coefficient, expected to be `0.00` for a clean block |
| `FIDELITY` | Yes | Fidelity metric, expected to be `1.00` for a fully reconstructed block |
| `ADHERENCE` | Yes | Standard-adherence score in `[0, 1]` |
| `TERMINATOR` | Yes | The literal `⟦end⟧` marker closing the block |

Each field is implemented as a `Field` namedtuple:

```python
Field = collections.namedtuple(
    'Field', ['name', 'pattern', 'required', 'description']
)
```

and the grammar is a flat list of `Field` instances (`SCN_GRAMMAR`),
which the parser iterates over to build an extraction table. This
"grammar as data" approach keeps the field set declarative and easy to
extend — adding a new field is a one-line addition to the list rather
than a change to parsing logic.

---

## 4. Abstract structure

Rather than building a full parse tree, the reference parser produces a
flat extraction map plus a set of auxiliary structures, which is
sufficient for a notation with no nested repetition or recursive
sub-blocks. The output of parsing is a `ParseResult` namedtuple:

```python
ParseResult = collections.namedtuple(
    'ParseResult',
    ['fields', 'violations', 'entropy_score', 'fidelity',
     'compliant', 'author_data', 'pattern_map']
)
```

- `fields` — dict of extracted field name → value (or `None` if absent)
- `violations` — list of `Violation` records (see §6)
- `entropy_score` — normalized Shannon entropy of the raw block text
- `fidelity` — proportion of grammar fields successfully extracted
- `compliant` — whether the block passed all required-field and rule checks
- `author_data` — resolved author registry lookup (see §5)
- `pattern_map` — classified/unclassified tag breakdown (see §5)

For notations with recursive or repeating structure (e.g., blocks that
can nest arbitrarily), a proper AST with a `Node` type and a recursive
descent parser would be the natural generalization. Section 8 sketches
this extension.

---

## 5. Parsing algorithm

The core entry point is `parse_scn_block(text)`, which proceeds in five
passes over the input:

1. **Line indexing.** Scan each line of the input and record the first
   line number at which each grammar field's pattern matches, for use
   in later error reporting.
2. **Field extraction.** For each field in `SCN_GRAMMAR`, search the
   full text (with `re.DOTALL` so multi-line values are supported) for
   the field's pattern. If found, store the captured group; if a
   required field is missing, record a `CRITICAL` violation.
3. **Rule evaluation.** Apply each rule in `VALIDATION_RULES` (§6) to
   the corresponding extracted field, recording a `VIOLATION` if the
   constraint fails or a `WARNING` if the value cannot be parsed as
   expected (e.g., a non-numeric value where a float is required).
4. **Auxiliary analysis.** Compute the normalized entropy of the block
   text (`calculate_entropy`), classify the `TAGS` field into taxonomy
   categories (`classify_tags`), and resolve the `AUTHOR` field against
   the known-author registry (`validate_author`).
5. **Summary computation.** Tally how many fields were present versus
   expected to compute `fidelity`, and determine overall `compliant`
   status from the presence of critical or rule violations.

This is a **single-pass, regex-driven extraction** rather than a
classical tokenize-then-recursive-descend parse, which is appropriate
given SCN's flat, non-recursive field structure. A more general
notation — one that allowed blocks to nest inside other blocks — would
instead be tokenized into a stream of `(TAG_OPEN, name)`, `(TEXT,
value)`, `(TAG_CLOSE, name)` tokens and consumed by a recursive descent
parser with one `parse_<something>` function per non-terminal in the
grammar. See §8 for a sketch of this generalization.

### 5.1 Error recovery

The parser does not abort on the first missing or invalid field.
Instead, it accumulates all violations across the whole block and
reports them together (§7), so a single malformed block yields one
complete diagnostic pass rather than requiring repeated fix-and-rerun
cycles. This mirrors standard compiler error-recovery practice: prefer
resynchronizing and continuing over halting at the first error.

---

## 6. Validation rules

Validation rules are declarative bindings of `(field name, constraint
function, description)`, stored in an ordered dictionary so that
reports list them in a stable, deterministic order:

```python
VALIDATION_RULES = collections.OrderedDict([
    ('RULE_FIDELITY',    ('FIDELITY',    lambda v: float(v) == 1.00, ...)),
    ('RULE_RESIDUAL',    ('RESIDUAL',    lambda v: float(v) == 0.00, ...)),
    ('RULE_ADHERENCE',   ('ADHERENCE',   lambda v: float(v) >= 0.95, ...)),
    ('RULE_DISCLOSURE',  ('DISCLOSURE',  lambda v: v.upper() in [...], ...)),
    ('RULE_ENCRYPTION',  ('ENCRYPTION',  lambda v: v.upper() in [...], ...)),
    ('RULE_TERMINATOR',  ('TERMINATOR',  lambda v: v == '⟦end⟧', ...)),
])
```

A violation is recorded as:

```python
Violation = collections.namedtuple(
    'Violation', ['severity', 'field', 'message', 'line']
)
```

with `severity` one of `CRITICAL` (required field absent), `VIOLATION`
(a present field fails its rule), or `WARNING` (a present field cannot
be evaluated against its rule, e.g., due to a type mismatch).

This rule engine is intentionally small — six rules over ten fields —
to keep the reference implementation legible. A production system
validating a richer notation would likely externalize rules into a
configuration file or a proper schema/constraint language (e.g., JSON
Schema, or a custom DSL) rather than hardcoding lambdas.

---

## 7. Reporting

`generate_report(result, original_text)` renders a `ParseResult` into a
plain-text compliance report with six sections:

1. Field extraction report — presence/absence of each grammar field
2. Validation rule results — list of violations, if any
3. Author identity verification — registry lookup outcome
4. Tag classification — tags grouped by taxonomy category
5. Entropy and fidelity metrics
6. Block seal — a closing SCN-formatted acknowledgment block

The report format is deliberately plain (ASCII-safe status markers,
fixed-width alignment) so it can be logged, diffed, or embedded in CI
output without special rendering support.

Separately, `validate_block(result)` produces a `Verdict` — a compact,
machine-readable pass/fail summary rendered back out *as an SCN block
itself* (`scn_output`), demonstrating that the notation can serve as
both an input and an output format for the same tool (i.e., validators
built on SCN can themselves emit SCN).

---

## 8. Extension points

The reference implementation is deliberately minimal. Natural
extensions include:

- **Recursive grammar.** Allow SCN blocks to nest inside other blocks
  (e.g., a `⟦tag:GROUP⟧...⟦/tag⟧` field whose value is itself one or
  more SCN blocks). This would require moving from single-pass regex
  extraction to a tokenizer + recursive descent parser with an explicit
  `Node` AST type, since nested/repeating structure cannot be reliably
  captured with flat regular expressions.
- **Portable snapshot format.** A *portable snapshot* is a
  self-contained, serialized SCN block — analogous to a signed config
  manifest — that can be transported between systems and re-parsed
  independently of the system that produced it. `generate_snapshot()`
  in the reference code demonstrates the basic serialization; a
  production system would likely add a content hash and a digital
  signature (for example, using **Ed25519**, a widely used
  elliptic-curve signature scheme well suited to signing small,
  fixed-size payloads) so that a snapshot's origin and integrity can be
  verified independently of the channel it was transmitted over.
  Signature verification is out of scope for this reference parser but
  is a natural next step for anyone adapting it.
- **Schema externalization.** Move `SCN_GRAMMAR` and `VALIDATION_RULES`
  into a declarative schema file (YAML/JSON), so the grammar can evolve
  without code changes.
- **Streaming parser.** For very large documents containing many SCN
  blocks, a streaming tokenizer that yields blocks lazily would avoid
  loading the entire document into memory.

---

## 9. Usage

### 9.1 As a library

```python
from scn_parser_reference import (
    parse_scn_block, validate_block, generate_report, generate_snapshot,
)

block = generate_snapshot(
    author_name='reference-author-theta',
    affiliation='reference-affiliation',
    domain='validation',
    tags=['PROCEDURAL', 'STRUCTURAL', 'INTEGRITY', 'COMPLIANCE'],
    adherence_score='1.00',
)

result = parse_scn_block(block)
verdict = validate_block(result)

print(generate_report(result, block))
print(verdict.scn_output)
```

### 9.2 As a script

```bash
python3 scn-parser-reference.py
```

Running the module directly executes `main()`, which generates an
example block, parses it, validates it, and prints both the full
compliance report and the compact SCN verdict block.

---

## 10. Testing

The reference implementation is suitable for straightforward unit
testing since every function is pure (no I/O, no global mutable state
outside the static lookup tables). Suggested test coverage:

- **Grammar extraction:** each field in `SCN_GRAMMAR` extracts correctly
  from a well-formed block, and is reported as `None` when omitted.
- **Required-field violations:** omitting each required field in turn
  produces exactly one `CRITICAL` violation for that field.
- **Rule violations:** for each rule in `VALIDATION_RULES`, construct a
  block with a value that violates the rule and confirm a `VIOLATION`
  entry is produced with the expected message.
- **Malformed values:** non-numeric values in numeric fields (e.g.,
  `FIDELITY`) should produce a `WARNING`, not raise an exception.
- **Entropy bounds:** `calculate_entropy('')` returns `0.0`;
  single-character-repeated text returns `0.0`; and a maximally varied
  short string returns a value close to `1.0`.
- **Author registry:** both known and unknown author strings resolve
  without raising, with `known` set appropriately.
- **Tag classification:** tags matching taxonomy keywords are
  classified into the correct category; unrecognized tags land in
  `unclassified`.
- **Round-trip:** a block generated by `generate_snapshot()` parses back
  with `fidelity == 1.0` and `compliant == True`.

Example test skeleton (pytest-style):

```python
def test_missing_required_field_flags_critical():
    block = "⟦tag:VERSION⟧1.0.0⟦/tag⟧\n⟦end⟧"
    result = parse_scn_block(block)
    critical_fields = {v.field for v in result.violations if v.severity == 'CRITICAL'}
    assert 'AUTHOR' in critical_fields

def test_round_trip_snapshot_is_compliant():
    block = generate_snapshot('reference-author-theta', 'core', 'validation',
                               ['STRUCTURAL'], '1.00')
    result = parse_scn_block(block)
    assert result.compliant
    assert result.fidelity == 1.0
```

---

## 11. Summary

SCN and its reference parser illustrate a small, complete pipeline for
a domain-specific structured notation: a tag-based grammar, a
regex-driven field extractor, a declarative validation-rule engine, an
attribution-registry lookup, and a human-readable reporting layer — all
built without external dependencies. The design favors legibility and
determinism over generality, making it a useful starting point for
anyone building a similar machine-readable metadata format, whether for
inter-agent messaging, structured logging, or configuration snapshots.

---

*This document and its accompanying reference implementation are
written for public distribution and contain no operational or
proprietary information.*

**Michael A. Kane II — Framework Creator**
**Foundational contributions: [Framework Security]**
**July 2026**
