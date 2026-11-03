# Manage Leases And Respond To A Leaked Credential

A credential leaks. It can be an AppRole secret ID in a build log, a token pasted into a chat, or a certificate private key on a disk that was copied. The first minutes decide how much damage follows. The person on duty must know which credentials exist, which of them the leak reaches, and which command ends them without breaking applications that were never involved.

This module builds on the lease basics from an earlier module. It goes into how a lease lives and ends, how to revoke one lease, a set of leases or a whole tree of tokens, and how to turn those commands into a repeatable response to an incident.

The module has four parts. **The Lease Lifecycle In Depth** covers lease IDs, lifetime limits and renewal. **Revoking Leases And Tokens At Scale** compares the revocation commands and what each one touches. **An Incident Response Runbook** gives the order of actions from containing a leak to checking that it is closed. **Prepare Before An Incident** shows the settings that make a later response small and safe. A graded lab follows the last part.

## Learning objectives

After this module you can:

- Read a lease ID and a lease lookup, and predict when a lease expires.
- Renew a lease and explain why a renewal can return less time than requested.
- Revoke one lease, all leases under a prefix, and all leases of a token.
- Explain what `-sync` and `-force` do and when each is the wrong choice.
- Explain what happens when you disable a secrets engine, disable an auth method, or seal the server.
- Follow a runbook that contains, scopes, revokes, rotates and verifies.
- Configure lifetimes so that a leaked credential is valid for a short time only.

## Before you start

You should be able to look up, renew and revoke a lease, and create and revoke a token. You should know that a token that is revoked takes its children with it.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, installed with the `openbao` Helm chart 0.30.4, **initialized and unsealed**. It contains:

| Object | What it is |
| --- | --- |
| KV version 2 at `secret/` | Holds `secret/billing/db` and `secret/inventory/db` |
| PKI at `pki/` | A root certificate authority and the role `web`, which issues certificates with a lease |
| AppRole at `approle/` | The roles `billing` and `inventory`, both allowed to issue certificates |
| Policy `cert-issuer` | Lets a token issue certificates from `pki/issue/web` and create child tokens |
| Logins and leases | Each role has logged in once. The `billing` token issued two certificates and created one child token. The `inventory` token issued one certificate |

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
