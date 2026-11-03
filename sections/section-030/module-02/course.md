# Choose Token Types, Lifetimes And Roles

Every request to OpenBao carries a token, and every token has a lifetime. A token that lives too long is a standing risk. A token that lives too short breaks the application that holds it. Choosing the right token type, setting its time limits, and letting applications request tokens only through controlled roles are the daily work of whoever runs an OpenBao server.

This module covers service and batch tokens, root and orphan tokens, periodic tokens, how the time to live (TTL) and the maximum TTL combine, token roles that limit what a client may ask for, and the limits that bound a token's use: use counts, accessors and network ranges.

The module has four parts. **Token Types** compares service, batch, root, orphan and periodic tokens. **TTL, Maximum TTL And Renewal** explains how the lifetime of a token is decided. **Token Roles** shows how to let applications create tokens without letting them choose the rights. **Use Limits, Accessors And Network Binding** covers the controls that bound what a token can do over its life. A graded lab follows the last part.

## Learning objectives

After this module you can:

- Choose between service, batch, periodic and orphan tokens for a given task.
- Read the lifetime fields of a token lookup and predict when the token expires.
- Explain how the system, mount, role and request limits combine into one TTL.
- Create a token role that restricts policies, lifetime and type.
- Create a token with a use limit and revoke a token by its accessor.
- Bind tokens to client network ranges.

## Before you start

You should be able to create a token with `bao token create` and attach policies to it. You should know that every token has a parent, and that revoking a parent revokes its children.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, installed with the `openbao` Helm chart 0.30.4, **initialized and unsealed**. It contains:

| Object | What it is |
| --- | --- |
| KV version 2 at `secret/` | The secret `secret/worker/queue` |
| Policies | `worker-read` (reads `secret/data/worker/*`), `worker-write` (writes it) and `admin-ops` (a broad policy that workers must never get) |
| Token role `worker` | A role with deliberately loose settings, to read and change |

The playground puts the `bao` command-line tool 2.7.1 on your machine. OpenBao answers at `http://openbao.localtest.me:8200`. Keep this port-forward running in a second terminal, and start it again if the OpenBao pod restarts:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

In the terminal where you work, point `bao` at the server and log in with the lab-only root token. A real installation revokes its root token after setup.

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

If your network blocks the name `openbao.localtest.me`, add `127.0.0.1 openbao.localtest.me` to `/etc/hosts`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
