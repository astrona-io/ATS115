# Manage Policies In Production

Writing one correct policy is the first skill. Running policies for a whole organisation is the second. Policies are stored in OpenBao by name, tokens refer to them by name, and a change to a policy changes what every token with that name can do, immediately. Delegating the work of writing policies without handing out the root token needs its own rules.

This module covers how to manage policies with the CLI and the API, what the `default` policy contains, what happens to existing tokens when a policy changes or disappears, advanced parameter constraints, and how to build an administrator policy that does a real job without `root`.

The module has four parts. **The Policy API And The Default Policy** shows every way to write, read, format, test and delete a policy. **What Happens To Tokens When A Policy Changes** explains how OpenBao resolves policy names at request time. **Parameter Constraints In Depth** covers `required_parameters`, value lists and wildcards. **Administrator Policies And Root-Protected Paths** builds a limited policy-administrator role and explains `sudo`. A graded lab follows the last part.

## Learning objectives

After this module you can:

- Manage policies with `bao policy` commands and the `sys/policies/acl` API.
- List what the `default` policy allows and create a token without it.
- Predict what a policy change or deletion does to tokens that already exist.
- Use `bao token capabilities` and `sys/capabilities` to check a token's rights before using the token.
- Limit a request with `allowed_parameters`, `denied_parameters` and `required_parameters`.
- Write a delegated administrator policy that manages some policies but not others, without `root` or `sudo`.

## Before you start

You should be able to write a path rule and explain the capabilities `read`, `list`, `update` and `deny`. You should know that a KV version 2 mount splits its API into `data/` and `metadata/` paths.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, installed with the `openbao` Helm chart 0.30.4, **initialized and unsealed**. It contains:

| Object | What it is |
| --- | --- |
| KV version 2 at `secret/` | Example secrets under `secret/inventory/` and `secret/billing/` |
| PKI secrets engine at `pki/` | A root certificate authority and the role `web`, which signs names under `example.internal` |
| Policy `team-app` | An existing application policy to read, change and delete |

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
