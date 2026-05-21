# Catlab Webapp MVP

This is an additive web layer for Catlab that lives in its own Julia project.
It does not replace or modify the existing Catlab package APIs.

## What "webapp" means in this MVP

- **API service**: a Julia HTTP service exposing stable parse/compute/render endpoints.
- **Browser UI**: a single-page frontend for one focused flow: submit a graph JSON payload and inspect API results.

## API endpoints

- `GET /api/health`
- `POST /api/parse`
- `POST /api/compute`
- `POST /api/render`

Payload shape for `POST` endpoints:

```json
{
  "vertices": 4,
  "edges": [
    { "src": 1, "tgt": 2 },
    { "src": 2, "tgt": 3 }
  ]
}
```

## Local development

From repository root:

```bash
julia --project=webapp -e 'using Pkg; Pkg.instantiate()'
julia --project=webapp -e 'using CatlabWebApp; serve(port=8080)'
```

Then open `http://127.0.0.1:8080`.

You can also start with the script:

```bash
julia --project=webapp webapp/server.jl
```

## Run tests

```bash
julia --project=webapp -e 'using Pkg; Pkg.test()'
```

## Deployment notes (production)

- Run behind a reverse proxy (Nginx/Caddy/Ingress) for TLS termination.
- Set host/port via environment variables:
  - `CATLAB_WEBAPP_HOST`
  - `CATLAB_WEBAPP_PORT`
- Use process supervision (systemd, Docker/Kubernetes, or equivalent) and health checks against `GET /api/health`.

## Incremental rollout path

1. **Current MVP**: directed graph parse/compute/render flow.
2. **Next**: richer rendering and interactive editing UX.
3. **Later**: broader Catlab domain workflows (e.g. wiring diagram-specific operations).
