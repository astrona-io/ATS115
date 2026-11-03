# Manage Leases And Respond To A Leaked Credential — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-115-playground-030-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

OpenBao v2.7.1 in `kind`, initialized and unsealed, with KV version 2, PKI with a leased role, AppRole roles billing and inventory with live tokens and certificate leases, and an incident ConfigMap.
Built from the OpenBao 2.7 documentation and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona destroy ats-115-playground-030-03
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-115-playground-030-03`), not
the config path. `astrona submit` and `astrona test` do not apply.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (bootstrap only) |
| `bootstrap/prepare.sh` | Installs the tools and OpenBao, unseals it, creates the starting objects |
| `manifests/` | Helm values for OpenBao and the tester pod |
| `docs/overview.md` | What the environment contains and ideas to try |
