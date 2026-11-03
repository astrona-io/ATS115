# Manage Policies In Production — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-115-playground-010-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

OpenBao v2.7.1 in `kind`, initialized and unsealed, with KV version 2, a PKI mount with the role web, and the policies team-app and app-legacy.
Built from the OpenBao 2.7 documentation and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona destroy ats-115-playground-010-02
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-115-playground-010-02`), not
the config path. `astrona submit` and `astrona test` do not apply.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (bootstrap only) |
| `bootstrap/prepare.sh` | Installs the tools and OpenBao, unseals it, creates the starting objects |
| `manifests/` | Helm values for OpenBao and the tester pod |
| `docs/overview.md` | What the environment contains and ideas to try |
