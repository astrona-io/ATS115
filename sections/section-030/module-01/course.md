# Hand Over Secrets Safely And Control Their Lifetime

A deployment pipeline fetches a secret ID for an application and passes it on. Every system in between, the pipeline log, the chat message, the environment variable, now holds a working credential. And once a certificate or token is issued, it stays valid until it expires, even when you know it has leaked. This module covers the two OpenBao features that close those gaps: response wrapping for the handover, and leases for the lifetime.

**Response wrapping** puts a response into a single-use token instead of returning it. A **lease** is the time a dynamic secret or token is valid; OpenBao can renew it, and it can revoke it early.

The module has three parts. **Response Wrapping** wraps a response and unwraps it. **Checking And Unwrapping A Wrapping Token** shows how the receiver checks a token before using it, and why a failed check is a security event. **Leases, Renewal And Revocation Trees** works with certificate leases and token trees; a graded lab follows it.

## Learning objectives

After this module you can:

- Wrap a response with `-wrap-ttl` or the `X-Vault-Wrap-TTL` header, and unwrap it with `bao unwrap`.
- Look up a wrapping token and check its creation path and time to live before unwrapping it.
- Hand an AppRole secret ID to an application in a wrapping token.
- Look up, renew and revoke a lease, and find the leases under a path.
- Explain child and orphan tokens, and predict what `bao token revoke` takes with it.
- Require wrapped responses on a path with `min_wrapping_ttl` and `max_wrapping_ttl`.

## Before you start

You need to read and write secrets with `bao`, write a policy, and log in with AppRole using a role ID and a secret ID. You should know that a token carries policies and that some secrets engines issue secrets with a lease.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, **initialized and unsealed**. It contains:

| Object | What it is |
| --- | --- |
| KV version 2 at `secret/` | Holds `secret/inventory/db` |
| AppRole at `approle/` | The role `inventory`, whose tokens get the policy `inventory-app` (read `secret/inventory/`) |
| PKI at `pki/` | A root certificate authority (CA) and the role `web`, which issues certificates for `*.inventory.local` with a lease (`generate_lease=true`) |

Keep the port-forward running in a second terminal:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

In the terminal where you work, point `bao` at the server and log in with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

If your network blocks the name `openbao.localtest.me`, add `127.0.0.1 openbao.localtest.me` to `/etc/hosts`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
