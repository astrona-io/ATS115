---
estimated_duration: 15m
---

# Fix The Inventory Application Policy

- **ID:** LAB
- **Slug:** ats-115-lab-010-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for OpenBao in the namespace `openbao`. Read `question.md` for the task; `solution.md` is the walkthrough.
Built from the OpenBao 2.7 documentation and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-115-lab-010-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-115-lab-010-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/01-install-openbao.sh` | Helm, bao, the CoreDNS rewrite, the tester pod and OpenBao, unsealed |
| `bootstrap/02-seed-state.sh` | The starting state of the task: The example secrets and a policy inventory-app with KV version 1 paths and too many capabilities |
| `manifests/` | Helm values for OpenBao and the tester pod |
| `solution/apply.sh` | Reference solution used by `astrona test` |
| `testing/wait-for-openbao.sh` | Waits until OpenBao answers unsealed |
| `validation/` | Grading scripts, one per check |
