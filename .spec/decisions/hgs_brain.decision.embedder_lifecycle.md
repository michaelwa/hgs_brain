---
id: hgs_brain.decision.embedder_lifecycle
status: accepted
date: 2026-03-22
affects:
  - hgs_brain
  - hgs_brain.ingestion
---

# Conditionally Start Bumblebee Embedder by Environment

## Context

`Arcana.Embedder.Local` uses Bumblebee to load a HuggingFace model (`BAAI/bge-small-en-v1.5`) in-process. On every application start, Bumblebee makes an HTTP request to HuggingFace to check for model updates — even when the model is already cached locally. This causes two problems:

1. **Test reliability**: Every test subprocess spawned by `spec.verify` starts a fresh app instance, triggering the HuggingFace check. If the network is slow or unavailable, the embedder supervisor fails and tests cannot run, even though all arcana calls are mocked.

2. **Dev/prod resilience**: Any app restart without network access will fail to boot, making ingestion unavailable until connectivity is restored.

In test, the arcana client is fully mocked via `HgsBrain.MockArcanaClient`, so the embedder process is never needed.

## Decision

The embedder is started conditionally based on the `:start_embedder` application config key, which defaults to `true`. Test config sets it to `false`. Dev and production start the embedder as before.

```elixir
# config/test.exs
config :hgs_brain, :start_embedder, false

# lib/hgs_brain/application.ex
defp embedder_children do
  if Application.get_env(:hgs_brain, :start_embedder, true) do
    [Arcana.Embedder.Local]
  else
    []
  end
end
```

## Consequences

- Test processes no longer attempt to load the Bumblebee model, eliminating the HuggingFace timeout failure in `spec.verify` and isolated test runs.
- Ingestion and retrieval remain fully exercised in tests through the mock; the embedder exclusion does not reduce coverage.
- Dev and production behavior is unchanged.
- If Bumblebee offline mode is needed for resilient restarts, it should be addressed separately (e.g. `BUMBLEBEE_CACHE_DIR` + pre-downloading the model as a deploy step).
