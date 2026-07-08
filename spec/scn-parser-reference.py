"""
SCN Parser — Reference Implementation

Reference validator and parser for Structured Constitutional Notation (SCN),
a compact, tag-based markup language for encoding declarative metadata blocks
that machine agents can emit, validate, and exchange.

License: Apache 2.0 (matches repo)
Dependencies: Python stdlib only (re, collections, itertools, string, math)
Status: Reference implementation for the /spec/ directory

This module implements a small recursive-descent-style field extractor and
rule engine for SCN blocks: a required-field grammar, a rule set that checks
numeric and enumerated constraints on those fields, an author/attribution
registry lookup, and a human-readable compliance report generator.

Author: Michael A. Kane II — Framework Creator
Foundational contributions: [Framework Security]
Date: July 2026
"""

import re
import collections
import itertools
import string
import math

# ═══════════════════════════════════════════════════════════════════
# SCN PARSER & VALIDATOR v1.0
# Built exclusively from: re, collections, itertools, string, math
# ═══════════════════════════════════════════════════════════════════

Field = collections.namedtuple(
    'Field', ['name', 'pattern', 'required', 'description']
)
Violation = collections.namedtuple(
    'Violation', ['severity', 'field', 'message', 'line']
)
ParseResult = collections.namedtuple(
    'ParseResult',
    ['fields', 'violations', 'entropy_score', 'fidelity',
     'compliant', 'author_data', 'pattern_map']
)
Verdict = collections.namedtuple(
    'Verdict', ['author_name', 'rule_results', 'overall_status', 'scn_output']
)

# ---------------------------------------------------------------------------
# Grammar
#
# SCN uses a simple tag syntax: ⟦tag:NAME⟧value⟦/tag⟧
# Nested values use the same convention: ⟦value⟧inner⟦/value⟧
#
# Example block:
#
#   ⟦tag:VERSION⟧1.0.0⟦/tag⟧
#   ⟦tag:AUTHOR⟧reference-author⟦/tag⟧
#   ⟦tag:TAGS⟧[analysis, synthesis, compression]⟦/tag⟧
#   ⟦tag:DISCLOSURE⟧NONE⟦/tag⟧
#   ⟦tag:ENCRYPTION⟧NONE⟦/tag⟧
#   ⟦tag:RESIDUAL⟧0.00⟦/tag⟧
#   ⟦tag:FIDELITY⟧1.00⟦/tag⟧
#   ⟦tag:ADHERENCE⟧⟦value⟧1.00⟦/value⟧⟦/tag⟧
#   ⟦end⟧
# ---------------------------------------------------------------------------

SCN_GRAMMAR = [
    Field('VERSION', r'⟦tag:VERSION⟧(.+?)⟦/tag⟧',
          True, 'Notation version declaration'),
    Field('AUTHOR', r'⟦tag:AUTHOR⟧(.+?)⟦/tag⟧',
          True, 'Declared author or attribution identity'),
    Field('TAGS', r'⟦tag:TAGS⟧\[(.+?)\]⟦/tag⟧',
          True, 'Active semantic tags for this block'),
    Field('DISCLOSURE', r'⟦tag:DISCLOSURE⟧(.+?)⟦/tag⟧',
          True, 'Transparency / disclosure declaration'),
    Field('SUB_HZ', r'⟦tag:SUB_HZ⟧(.+?)⟦/tag⟧',
          False, 'Optional sampling-rate metadata'),
    Field('ENCRYPTION', r'⟦tag:ENCRYPTION⟧(.+?)⟦/tag⟧',
          True, 'Encryption state of the payload'),
    Field('RESIDUAL', r'⟦tag:RESIDUAL⟧(.+?)⟦/tag⟧',
          True, 'Residual error coefficient'),
    Field('FIDELITY', r'⟦tag:FIDELITY⟧(.+?)⟦/tag⟧',
          True, 'Fidelity metric'),
    Field('ADHERENCE', r'⟦tag:ADHERENCE⟧⟦value⟧(.+?)⟦/value⟧⟦/tag⟧',
          True, 'Standard-adherence score'),
    Field('TERMINATOR', r'⟦end⟧',
          True, 'Block terminator marker'),
]

# ---------------------------------------------------------------------------
# Validation rules
#
# Each rule binds a field name to a constraint function and a human-readable
# description of the constraint. This is a small, self-contained rule
# engine — not a general-purpose schema validator — intended to demonstrate
# how a constrained notation can be checked deterministically.
# ---------------------------------------------------------------------------

VALIDATION_RULES = collections.OrderedDict([
    ('RULE_FIDELITY', ('FIDELITY',
                        lambda v: float(v) == 1.00,
                        'FIDELITY must equal 1.00')),
    ('RULE_RESIDUAL', ('RESIDUAL',
                        lambda v: float(v) == 0.00,
                        'RESIDUAL must equal 0.00')),
    ('RULE_ADHERENCE', ('ADHERENCE',
                         lambda v: float(v) >= 0.95,
                         'ADHERENCE must be >= 0.95')),
    ('RULE_DISCLOSURE', ('DISCLOSURE',
                          lambda v: v.upper() in ['NONE', 'ACTIVE', 'PARTIAL'],
                          'DISCLOSURE must be NONE, ACTIVE, or PARTIAL')),
    ('RULE_ENCRYPTION', ('ENCRYPTION',
                          lambda v: v.upper() in ['NONE', 'ACTIVE', 'SIGNED'],
                          'ENCRYPTION must be a recognized state')),
    ('RULE_TERMINATOR', ('TERMINATOR',
                          lambda v: v == '⟦end⟧',
                          'Block must close with the ⟦end⟧ marker')),
])

# ---------------------------------------------------------------------------
# Author registry
#
# A small illustrative lookup table mapping known author identifiers to
# descriptive metadata. In a production system this would be backed by a
# real registry service; here it is inlined for reference purposes.
# ---------------------------------------------------------------------------

KNOWN_AUTHORS = {
    'reference-author-alpha': {
        'affiliation': 'multi-agent', 'status': 'verified', 'domain': 'analysis'
    },
    'reference-author-beta': {
        'affiliation': 'multi-agent', 'status': 'foundational', 'domain': 'specification'
    },
    'reference-author-gamma': {
        'affiliation': 'model-b', 'status': 'verified', 'domain': 'synthesis'
    },
    'reference-author-delta': {
        'affiliation': 'model-b', 'status': 'verified', 'domain': 'archival'
    },
    'reference-author-epsilon': {
        'affiliation': 'native', 'status': 'foundational', 'domain': 'language-design'
    },
    'reference-author-zeta': {
        'affiliation': 'multi-agent', 'status': 'precedent', 'domain': 'evaluation'
    },
    'reference-author-eta': {
        'affiliation': 'session-scoped', 'status': 'provisional', 'domain': 'bridging'
    },
    'reference-author-theta': {
        'affiliation': 'core', 'status': 'verified', 'domain': 'validation'
    },
}

# ---------------------------------------------------------------------------
# Tag taxonomy
#
# Groups free-form semantic tags into broad categories for reporting. This
# is a simple keyword-based classifier, not a full ontology.
# ---------------------------------------------------------------------------

TAG_TAXONOMY = {
    'DESCRIPTIVE': ['DESCRIPTIVE', 'CONTEXT', 'NARRATIVE', 'TRANSLATION'],
    'INTEGRITY': ['INTEGRITY', 'VALIDATION', 'CHECK', 'VERIFICATION'],
    'ANALYTICAL': ['ANALYSIS', 'SYNTHESIS', 'COMPRESSION', 'MAPPING', 'PARSING', 'DEPENDENCY'],
    'RELATIONAL': ['RELATIONAL', 'ANCHORING', 'LINKAGE', 'BRIDGE'],
    'PROCEDURAL': ['PROCEDURAL', 'ENFORCEMENT', 'COMPLIANCE', 'PROTOCOL', 'AUDIT'],
    'STRUCTURAL': ['STRUCTURAL', 'SCHEMA', 'GRAMMAR', 'FORMAT', 'ADHERENCE'],
    'TRANSFORM': ['TRANSFORM', 'CONVERSION', 'DELTA', 'REVISION'],
    'COGNITIVE': ['COGNITIVE', 'SUMMARY', 'ABSTRACTION', 'BASE'],
}


def calculate_entropy(text):
    """Compute the normalized Shannon entropy of a text block.

    Returns a value in [0, 1], where 0 indicates no variation in
    character distribution and 1 indicates maximal variation relative
    to the observed alphabet size.
    """
    if not text:
        return 0.0
    char_counts = collections.Counter(text)
    total = len(text)
    entropy = -sum(
        (c / total) * math.log2(c / total)
        for c in char_counts.values() if c > 0
    )
    max_entropy = math.log2(len(char_counts)) if len(char_counts) > 1 else 1
    return round(entropy / max_entropy, 4) if max_entropy > 0 else 0.0


def classify_tags(tag_string):
    """Classify a comma-separated tag list into taxonomy categories.

    Returns a tuple of (classified: dict[str, list[str]], unclassified: list[str]).
    """
    tags = [t.strip() for t in tag_string.split(',')]
    classified = collections.defaultdict(list)
    unclassified = []
    for tag in tags:
        found = False
        for category, keywords in TAG_TAXONOMY.items():
            if any(kw in tag.upper() for kw in itertools.chain(keywords, [category])):
                classified[category].append(tag)
                found = True
                break
        if not found:
            unclassified.append(tag)
    return dict(classified), unclassified


def validate_author(author_string):
    """Look up an author string against the known-author registry.

    Returns (is_known, resolved_name, metadata). Unknown authors resolve
    to a placeholder metadata record rather than raising an error, since
    unregistered authorship is a valid (if flagged) parse outcome.
    """
    core = re.split(r'[\(\[]', author_string.strip())[0].strip()
    for name, data in KNOWN_AUTHORS.items():
        if name.upper() in core.upper() or core.upper() in name.upper():
            return True, name, data
    return False, core, {'affiliation': 'unknown', 'status': 'unregistered', 'domain': 'pending'}


def parse_scn_block(text):
    """Parse an SCN block into a structured ParseResult.

    Performs field extraction against SCN_GRAMMAR, records the line number
    at which each field first appears, applies the field-required check,
    and computes summary statistics (entropy, fidelity, compliance).
    """
    extracted = {}
    violations = []
    line_index = collections.defaultdict(int)

    lines = text.split('\n')
    for i, line in enumerate(lines):
        for field in SCN_GRAMMAR:
            if re.search(field.pattern, line):
                line_index[field.name] = i + 1

    for field in SCN_GRAMMAR:
        match = re.search(field.pattern, text, re.DOTALL)
        if match:
            extracted[field.name] = '⟦end⟧' if field.name == 'TERMINATOR' else match.group(1).strip()
        elif field.name == 'TERMINATOR' and '⟦end⟧' in text:
            extracted[field.name] = '⟦end⟧'
            line_index[field.name] = len(lines)
        else:
            extracted[field.name] = None
            if field.required:
                violations.append(
                    Violation('CRITICAL', field.name,
                              f'Required field missing: {field.description}', 0)
                )

    for rule_id, (fname, constraint, rule_text) in VALIDATION_RULES.items():
        val = extracted.get(fname)
        if val is not None:
            try:
                if not constraint(val):
                    violations.append(
                        Violation('VIOLATION', fname,
                                  f'{rule_id}: {rule_text} — got: "{val}"',
                                  line_index.get(fname, 0))
                    )
            except (ValueError, TypeError):
                violations.append(
                    Violation('WARNING', fname,
                              f'{rule_id}: Malformed value: "{val}"',
                              line_index.get(fname, 0))
                )

    entropy = calculate_entropy(text)

    pattern_map, unclassified = {}, []
    if extracted.get('TAGS'):
        pattern_map, unclassified = classify_tags(extracted['TAGS'])

    author_known, author_name, author_data = False, 'UNKNOWN', {}
    if extracted.get('AUTHOR'):
        author_known, author_name, author_data = validate_author(extracted['AUTHOR'])

    counter = collections.Counter({
        'present': sum(1 for f in SCN_GRAMMAR if extracted.get(f.name) is not None),
        'critical': sum(1 for v in violations if v.severity == 'CRITICAL'),
        'violation': sum(1 for v in violations if v.severity == 'VIOLATION'),
    })
    fidelity = round(counter['present'] / len(SCN_GRAMMAR), 4)
    compliant = (counter['critical'] == 0 and counter['violation'] == 0)

    return ParseResult(
        extracted, violations, entropy, fidelity, compliant,
        {'known': author_known, 'name': author_name, 'data': author_data},
        {'classified': pattern_map, 'unclassified': unclassified}
    )


def validate_block(parse_result):
    """Apply the validation rule set to a ParseResult and produce a Verdict.

    Returns a Verdict namedtuple including a rendered SCN-formatted
    verdict block (`scn_output`) suitable for round-tripping through
    other SCN-aware tooling.
    """
    author_name = parse_result.author_data['name']
    rule_results = {}

    for rule_id, (fname, constraint, rule_text) in VALIDATION_RULES.items():
        val = parse_result.fields.get(fname)
        if val is not None:
            try:
                rule_results[rule_id] = constraint(val)
            except (ValueError, TypeError):
                rule_results[rule_id] = False
        else:
            rule_results[rule_id] = False

    overall_status = all(rule_results.values()) and parse_result.compliant
    status_str = "COMPLIANT" if overall_status else "VIOLATION"

    scn_lines = [
        f"⟦tag:VERDICT⟧⟦value⟧{status_str}⟦/value⟧⟦/tag⟧",
        f"author: {author_name}",
        f"rules_satisfied: {sum(rule_results.values())}/{len(VALIDATION_RULES)}",
        "⟦end⟧"
    ]
    scn_output = "\n".join(scn_lines)

    return Verdict(author_name, rule_results, overall_status, scn_output)


def generate_snapshot(author_name, affiliation, domain, tags, adherence_score):
    """Generate a portable snapshot (a serialized SCN block) for a given
    author record.

    A "portable snapshot" is simply a self-contained SCN block that can be
    transported, stored, or re-parsed independently — analogous to a
    signed manifest or config snapshot in other systems. Snapshots may
    optionally be signed (e.g., with Ed25519) by the emitting system to
    establish provenance; signing is out of scope for this reference
    parser but is a natural extension point.
    """
    tags_str = ", ".join(tags)
    snapshot = f"""⟦tag:VERSION⟧1.0.0⟦/tag⟧
⟦tag:AUTHOR⟧{author_name}⟦/tag⟧
⟦tag:TAGS⟧[{tags_str}]⟦/tag⟧
⟦tag:DISCLOSURE⟧NONE⟦/tag⟧
⟦tag:SUB_HZ⟧0.04Hz⟦/tag⟧
⟦tag:ENCRYPTION⟧NONE⟦/tag⟧
⟦tag:RESIDUAL⟧0.00⟦/tag⟧
⟦tag:FIDELITY⟧1.00⟦/tag⟧
⟦tag:ADHERENCE⟧⟦value⟧{adherence_score}⟦/value⟧⟦/tag⟧

affiliation: {affiliation}
domain: {domain}

⟦end⟧"""
    return snapshot


def generate_report(result, original_text):
    """Render a human-readable compliance report for a ParseResult."""
    r = result
    sep = '=' * 60

    if r.compliant and r.fidelity >= 1.0:
        verdict = 'COMPLIANT — full standing'
        verdict_code = 'CLEAR'
    elif r.compliant and r.fidelity >= 0.8:
        verdict = 'SUBSTANTIALLY COMPLIANT — minor gaps noted'
        verdict_code = 'ADVISORY'
    elif not r.compliant and r.fidelity >= 0.5:
        verdict = 'VIOLATIONS DETECTED — remediation required'
        verdict_code = 'VIOLATION'
    else:
        verdict = 'BLOCK REJECTED — critical structural failure'
        verdict_code = 'REJECTED'

    lines = [
        '',
        sep,
        ' SCN PARSER — COMPLIANCE REPORT',
        ' Structured Constitutional Notation (SCN) reference implementation',
        ' Engine: re + collections + itertools + string + math',
        ' (Pure Python standard library; no third-party dependencies.)',
        sep,
        '',
        f' VERDICT: {verdict}',
        f' VERDICT CODE: {verdict_code}',
        '',
        sep,
        ' 1. FIELD EXTRACTION REPORT',
        sep,
    ]

    for field in SCN_GRAMMAR:
        val = r.fields.get(field.name)
        status = '[OK]' if val is not None else ('[MISSING - REQUIRED]' if field.required else '[absent, optional]')
        display = val[:60] + '...' if val and len(val) > 60 else (val or '')
        lines.append(f'  {field.name:<20} {status}')
        if val:
            lines.append(f'  {"":20} -> {display}')

    lines += [
        '',
        sep,
        ' 2. VALIDATION RULE RESULTS',
        sep,
    ]

    if not r.violations:
        lines.append('  All validation rules satisfied — zero violations.')
    else:
        for v in r.violations:
            lines.append(f'  [{v.severity}] Field: {v.field} | Line: {v.line}')
            lines.append(f'    -> {v.message}')

    lines += [
        '',
        sep,
        ' 3. AUTHOR IDENTITY VERIFICATION',
        sep,
    ]
    ad = r.author_data
    known_str = 'registry match' if ad['known'] else 'unregistered (may be a new author)'
    lines += [
        f'  Author Name:  {ad["name"]}',
        f'  Registry:     {known_str}',
        f'  Affiliation:  {ad["data"].get("affiliation", "unknown")}',
        f'  Status:       {ad["data"].get("status", "unknown")}',
        f'  Domain:       {ad["data"].get("domain", "unknown")}',
    ]

    lines += [
        '',
        sep,
        ' 4. TAG CLASSIFICATION',
        sep,
    ]
    if r.pattern_map['classified']:
        for category, tags in r.pattern_map['classified'].items():
            lines.append(f'  [{category}]')
            for t in tags:
                lines.append(f'    - {t}')
    if r.pattern_map['unclassified']:
        lines.append('  [UNCLASSIFIED — pending taxonomy expansion]')
        for t in r.pattern_map['unclassified']:
            lines.append(f'    - {t}')

    lines += [
        '',
        sep,
        ' 5. ENTROPY AND FIDELITY METRICS',
        sep,
        f'  Entropy Score: {r.entropy_score:.4f} (normalized)',
        f'  Fidelity:      {r.fidelity:.4f}',
        f'  Residual:      {r.fields.get("RESIDUAL", "unknown")}',
        '',
        sep,
        ' 6. BLOCK SEAL',
        sep,
        '  ⟦tag:SEAL⟧⟦value⟧VALIDATED⟦/value⟧⟦/tag⟧',
        '  ⟦end⟧',
        sep
    ]

    return '\n'.join(lines)


def main():
    """Demonstrate the parser end-to-end on a generated example block."""
    example_block = generate_snapshot(
        author_name='reference-author-theta',
        affiliation='reference-affiliation',
        domain='validation',
        tags=['PROCEDURAL', 'STRUCTURAL', 'INTEGRITY', 'COMPLIANCE'],
        adherence_score='1.00'
    )

    result = parse_scn_block(example_block)
    verdict = validate_block(result)
    report = generate_report(result, example_block)

    print(report)
    print("\n" + "=" * 60 + "\n")
    print(verdict.scn_output)


if __name__ == '__main__':
    main()
