---
type: Design Discussion
title: Phase 0 design — repo skeleton, proto, local dev, Terraform baseline, CI
description: Approved design for Phase 0 (skeleton & infrastructure), decided with Jeff on 2026-07-13
tags: [phase-0, monorepo, buf, terraform, ci]
created: 2026-07-13
status: approved
---

# Phase 0 Design — Skeleton & Infrastructure

Source: brainstorming session between Jeff and Claude, 2026-07-13. All decisions below
were approved by Jeff section by section. Governing spec: `docs/ewallet-portfolio-plan.md`
(§6 Phase 0). This document is input material for `docs/adr/0001-architecture-overview.md`,
which Jeff writes himself.

## Constraints clarified with Jeff

- GCP: USD 300 free credits available; cloud deployment is OK but cost must stay minimal
  (no multi-node clusters). Design for cheap-by-default, destroy-and-recreate.
- Jeff's Go level: has read the syntax, never built a full project. Implementation steps
  must be fine-grained; reviews explain Go idioms in depth.
- Time budget: 20–30 h/week. Phase 0 within ~2 weeks is realistic.
- Dev loop: services run with `go run` on the host; docker-compose only for dependencies.
- GitHub repo: public from day one. Never commit secrets.
- Git history: Claude initialized the repo with the docs skeleton; all code commits are
  Jeff's own work.

## 1. Repo layout and dependency rules

Single Go module (chosen over go.work multi-module and `pkg/`-style layout — matches the
modular-monolith intent of plan §3.1, lowest toolchain friction, easiest to refactor).

```
e-wallet/
├── go.mod                  # the only module
├── cmd/
│   ├── wallet/main.go      # one entrypoint per deployable; wiring only, no logic
│   └── reconciler/main.go
├── internal/
│   ├── wallet/             # module boundary = package boundary
│   │   ├── account/
│   │   ├── ledger/
│   │   ├── transfer/
│   │   └── outbox/
│   ├── reconciler/
│   └── platform/           # db, config, slog, otel shared infrastructure
├── proto/                  # buf-managed, source of truth for module interfaces
├── gen/                    # generated Go code, committed
├── db/migrations/          # golang-migrate
├── deploy/
│   ├── docker-compose.yml
│   └── terraform/
├── .github/workflows/
└── docs/
```

Rules:
1. Import direction: `cmd/*` wires and starts, contains no business logic.
   `internal/platform` must not import domain packages. Within a domain module,
   direct imports are allowed in Phase 1 (e.g. `transfer` → `ledger`). Across
   modules (wallet ↔ reconciler), communication goes only through proto-defined
   interfaces or events.
2. `gen/` is committed; CI verifies regeneration produces an empty diff, so the repo
   compiles without buf installed.
3. `Makefile` is the single entrypoint: `make lint / test / generate / migrate-up /
   migrate-down / dev`. CI runs exactly the same targets as local dev (reproducibility).

## 2. Proto and buf

- Layout `proto/ewallet/wallet/v1/wallet.proto`, package `ewallet.wallet.v1`
  (buf style: path = package, always versioned; consistent with the plan's
  "versioned event schemas" principle).
- `buf.yaml`: lint with the `DEFAULT` rule set; breaking-change detection against `main`.
  Both run in CI.
- `buf.gen.yaml`: `protoc-gen-go` + `protoc-gen-go-grpc` into `gen/`.
- Phase 0 defines the full `WalletService` v1 contract (no implementation):
  `CreateAccount`, `Deposit`, `Withdraw`, `Transfer`, `GetBalance`; a shared `Money`
  message (`currency` + `int64 minor_units` — invariant: no floats); every mutating RPC
  carries `idempotency_key`.
- Not in scope: grpc-gateway/HTTP (grpcurl + Postman per plan §2); event proto schemas
  wait until Phase 3.

## 3. Local development environment

- `deploy/docker-compose.yml` (wrapped by `make dev`) runs MySQL 8 (healthcheck, named
  volume, init script creating the `wallet` database; `reconciler` schema arrives in
  Phase 2) and the Pub/Sub emulator (unused until Phase 3, zero cost to include now).
- Migrations: `golang-migrate` CLI, files in `db/migrations/`. Phase 0 only wires the
  toolchain and proves up/down with a baseline migration; real tables are designed at
  the start of Phase 1 together with the ledger design doc.
- Config: 12-factor, env vars only. `.env.example` committed (no real values), `.env`
  gitignored. No secrets in git, ever (public repo).

## 4. Terraform GCP baseline

- State: GCS bucket backend (one-time bootstrap, documented).
- Applied in Phase 0 (standing cost ≈ 0): enabled APIs, Artifact Registry,
  least-privilege service accounts, Workload Identity Federation for GitHub Actions
  (keyless image push — no JSON keys in a public repo), billing budget alerts at
  25/50/75% of the USD 300 credit.
- GKE (Autopilot) + Cloud SQL (smallest tier): written in Phase 0, applied once to
  verify the build → push → deploy chain end-to-end with a hello-world wallet image,
  then `terraform destroy`. They stay down through Phases 1–2 and come back permanently
  in Phase 3. Rationale: keeps credits for Phase 3 load testing; a reproducible
  environment is itself an IaC selling point.
- Autopilot chosen over standard GKE: per-pod billing, no node management (cannot
  accidentally over-provision nodes), first cluster free of the management fee.

## 5. CI (GitHub Actions)

Same pipeline on PRs and pushes to main, four jobs:
1. **lint** — `golangci-lint`, `buf lint`, `buf breaking` (against main).
2. **generate-check** — rerun `buf generate` + `go mod tidy`, then `git diff --exit-code`.
3. **test** — `go test -race ./...` with a MySQL 8 service container (integration tests
   get a real DB from Phase 1 onward).
4. **build & push** — docker build on every run; push to Artifact Registry via Workload
   Identity Federation on main only.

Process: PR-based development even solo (feature branch → PR → green CI → merge),
implementing plan §7 "small commits"; the public PR history doubles as interview material.

## Out of scope for Phase 0

Any business logic, real DB tables, HTTP layer, event schemas, observability wiring
beyond basic slog setup, and the redpacket service. Phase 0's DoD (plan §6): running
docker-compose + generated proto + CI green + Terraform baseline + Jeff-authored
`docs/adr/0001-architecture-overview.md`.
