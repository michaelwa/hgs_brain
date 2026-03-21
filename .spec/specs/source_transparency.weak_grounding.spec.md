# Source Transparency — Weak Grounding State

Clearly communicate when an answer has little or no supporting evidence.

```spec-meta
id: hgs_brain.source_transparency.weak_grounding
kind: feature
status: proposed
summary: When retrieval returns weak or no supporting passages, the UI presents a clear grounding-unavailable state instead of implying a well-supported answer.
surface:
  - lib/hgs_brain_web/live/chat_live.ex
```

## Requirements

```spec-requirements
- id: hgs_brain.source_transparency.empty_citations
  statement: If the system cannot provide supporting sources for an answer, it shall clearly indicate that the answer is weakly grounded or unavailable.
  priority: must
  stability: evolving
```

## Scenarios

```spec-scenarios
- id: hgs_brain.source_transparency.no_grounding
  covers:
    - hgs_brain.source_transparency.empty_citations
  given:
    - The user asks a question but retrieval returns weak or no supporting passages
  when:
    - The response is rendered
  then:
    - The UI displays a clear "No supporting sources available" state rather than an empty Sources section or an unsupported answer
```

## UX Notes

- Show an explicit message such as "No supporting sources available" in the Sources section.
- Do not suppress the answer entirely — label it as weakly grounded and let the user decide.

## Exceptions

```spec-exceptions
- id: hgs_brain.source_transparency.weak_grounding.unimplemented
  covers:
    - hgs_brain.source_transparency.empty_citations
  reason: Feature not yet implemented. Verification targets will carry covers markers once the UI is built.
```

## Open Questions

- What threshold defines "weak grounding" — zero passages, or passages below a score cutoff?
- Should answer generation be blocked when no support is found, or merely labelled as weak?
