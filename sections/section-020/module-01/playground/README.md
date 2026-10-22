# Write Identity-Aware Policies And Control Groups — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-115-playground-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

OpenBao v2.7.1 in `kind`, initialized and unsealed, with KV version 2, the userpass users alice, bob, carol and dave with entities, and the group staff.
Built from the OpenBao 2.7 documentation and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona destroy ats-115-playground-020-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-115-playground-020-01`), not
the config path. `astrona submit` and `astrona test` do not apply.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (bootstrap only) |
| `bootstrap/prepare.sh` | Installs the tools and OpenBao, unseals it, creates the starting objects |
| `manifests/` | Helm values for OpenBao and the tester pod |
| `docs/overview.md` | What the environment contains and ideas to try |
