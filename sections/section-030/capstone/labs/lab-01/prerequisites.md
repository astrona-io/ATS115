# Prerequisites

Before starting this lab you should be able to:

- Use `-wrap-ttl` and `bao unwrap`, and look up a wrapping token.
- Log in with AppRole using a role ID and a secret ID.
- Look up, renew and revoke a lease, and explain parent and orphan tokens.

## What the environment gives you

The environment builds itself before the task begins. It takes a few minutes:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao` (pod `openbao-0`), installed
  with the `openbao` Helm chart 0.30.4, **initialized and unsealed**. The
  lab-only unseal key and root token are in the Secret `openbao-init`; a real
  installation never keeps them in a Kubernetes Secret.
- **Helm 3.22.1** and the **`bao` CLI 2.7.1** in `/usr/local/bin` or
  `~/.local/bin` on your machine.
- OpenBao answers at `http://openbao.localtest.me:8200`. Run
  `kubectl -n openbao port-forward svc/openbao 8200:8200` in a second terminal
  and `export BAO_ADDR=http://openbao.localtest.me:8200`. If the name does not
  resolve, add `127.0.0.1 openbao.localtest.me` to `/etc/hosts`. Log in with
  `export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)`.
- The token ci-parent with a child token build-1 and its certificates, an orphan release-bot, and a policy secret-id-issuer without wrapping rules.

## Working rules

- Everything is graded on the **final state**, so check your result at the end
  and leave the fix in place.
- Change one thing at a time and check again.
- If `openbao-0` restarts, OpenBao is sealed again. Unseal it with the key in
  `openbao-init` before you continue.
