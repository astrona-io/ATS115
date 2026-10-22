# Write Least-Privilege Policies

An application that reads two database passwords should be able to read those two passwords and nothing else. In OpenBao, a policy decides that. A policy is a named set of rules written in HashiCorp Configuration Language (HCL). Each rule names a path and the capabilities a token has on it.

Most policy mistakes fall into two groups. The first group refuses requests the application needs, and the application fails at start. The second group allows more than the application needs, and nothing fails at all, which makes it more dangerous. This module teaches you to write rules that sit exactly between the two, and to prove that they do.

The module has three parts. **Paths And Capabilities** builds a first policy on a KV version 2 mount and explains why it needs the `data/` and `metadata/` paths. **How OpenBao Matches A Request To A Rule** covers globs, the `+` segment, the priority rules and `deny`. **Testing Policies And Reading A Permission Denied** adds parameter constraints and shows how to test a policy with a fresh token before an application uses it; a graded lab follows it.

## Learning objectives

After this module you can:

- Write a path rule with the capabilities a task needs, and load it with `bao policy write`.
- Map an HTTP request on a KV version 2 mount to the path and capability a rule must allow.
- Predict which rule applies when several rules match a request.
- Use `deny` to block one path inside a wider rule.
- Limit the fields of a request with `allowed_parameters` and `denied_parameters`.
- Test a policy with a token that has only that policy, and with `bao token capabilities`.

## Before you start

You need Kubernetes basics, and you should be able to log in to OpenBao with a token and read a secret with `bao kv get`. You should know that OpenBao serves everything through paths, such as `secret/` for a secrets engine and `sys/` for its own configuration.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, installed with the `openbao` Helm chart 0.30.4, **initialized and unsealed**. A KV version 2 secrets engine is enabled at `secret/` and holds these secrets:

| Path | What it is |
| --- | --- |
| `secret/inventory/db`, `secret/inventory/api`, `secret/inventory/reports` | The inventory application's database password, API key and report schedule |
| `secret/billing/db`, `secret/billing/admin`, `secret/billing/reports` | The billing application's secrets, including an administrator password |
| `secret/ci/registry` | The build system's registry password |

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
