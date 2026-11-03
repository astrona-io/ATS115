---
estimated_duration: 20m
---

# Delegate Policy Administration Without The Root Token

- **ID:** LAB
- **Slug:** ats-115-lab-010-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for OpenBao in the namespace `openbao`. Read `question.md` for the task; `solution.md` is the walkthrough.
Built from the OpenBao 2.7 documentation and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-115-lab-010-02
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-115-lab-010-02`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/01-install-openbao.sh` | Helm, bao, the CoreDNS rewrite, the tester pod and OpenBao, unsealed |
| `bootstrap/02-seed-state.sh` | The starting state of the task: KV version 2 with two secrets, a PKI mount with the role web, the policies team-app and app-legacy, and a recorded checksum of the default policy |
| `manifests/` | Helm values for OpenBao and the tester pod |
| `solution/apply.sh` | Reference solution used by `astrona test` |
| `testing/wait-for-openbao.sh` | Waits until OpenBao answers unsealed |
| `validation/` | Grading scripts, one per check |
