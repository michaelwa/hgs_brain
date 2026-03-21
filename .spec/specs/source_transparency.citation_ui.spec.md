# Source Transparency — Citation UI

Render supporting citations beneath each answer in ask mode.

```spec-meta
id: hgs_brain.source_transparency.citation_ui
kind: feature
status: active
summary: The chat UI displays a Sources list beneath each AI-generated answer, showing file path, segment, and excerpt for each supporting passage.
surface:
  - lib/hgs_brain_web/live/chat_live.ex
```

## Requirements

```spec-requirements
- id: hgs_brain.source_transparency.answer_citations
  statement: The system shall display supporting citations alongside each AI-generated answer.
  priority: must
  stability: stable

- id: hgs_brain.source_transparency.segment_visibility
  statement: Citations shall make the active segment visible so users can confirm the answer was drawn from the intended knowledge scope.
  priority: should
  stability: stable
```

## Scenarios

```spec-scenarios
- id: hgs_brain.source_transparency.ask_with_sources
  covers:
    - hgs_brain.source_transparency.answer_citations
    - hgs_brain.source_transparency.segment_visibility
  given:
    - The user asks a question in ask mode and relevant passages are retrieved
  when:
    - The answer is rendered
  then:
    - The UI shows the synthesized answer and a Sources section listing each citation with file path, segment, and excerpt
```

## UX Notes

- Place a `Sources` section directly below the answer text.
- Each source item shows: file path or title, segment, excerpt text.
- Keep the list readable without collapsing by default; add collapsing later if clutter becomes an issue.

## Verification

```spec-verification
- kind: source_file
  target: lib/hgs_brain_web/live/chat_live.ex
  covers:
    - hgs_brain.source_transparency.answer_citations
    - hgs_brain.source_transparency.segment_visibility
```
