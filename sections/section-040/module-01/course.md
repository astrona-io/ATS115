# Audit Every Request

A newly initialized OpenBao server records nothing. Every login, every secret read and every policy change goes unrecorded until an operator enables an **audit device**: a component that writes each request and response to a destination such as a file or a network socket. Without one, an incident review has no answers. With one, OpenBao answers who did what, and it even refuses requests it cannot record.

The module has three parts. **Audit Devices And The Audit Log Format** explains what is recorded, how secret values are hashed, and which device types exist. **Enabling File And Socket Audit Devices** enables two devices and finds the same request in both with the audit hash; a graded lab follows it. **Declarative Audit Devices And Blocked Logging** moves a device into the server configuration and explains what OpenBao does when no device can write.

## Learning objectives

After this module you can:

- Describe the request and response entries in an audit log, and which strings are hashed.
- Name the paths that are never audited.
- Enable a `file` and a `socket` audit device, and list devices with `bao audit list`.
- Explain why `bao audit enable` needs `unsafe_allow_api_audit_creation` in OpenBao 2.7.
- Find a known value in an audit log with `sys/audit-hash`.
- Declare an audit device with an `audit` stanza, and apply a configuration change to a Helm-installed OpenBao.
- Explain what OpenBao does when one or all audit devices fail.

## Before you start

You need to read and write KV secrets with `bao`, change Helm values with `helm upgrade`, and restart a pod. You should know that OpenBao is sealed again after a pod restart and must be unsealed.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, **initialized and unsealed**, installed with the `openbao` Helm chart 0.30.4. It contains:

| Object | What it is |
| --- | --- |
| KV version 2 at `secret/` | Holds `secret/inventory/db` |
| Audit volume | A 1 GiB PersistentVolumeClaim mounted at `/openbao/audit` in `openbao-0` (`server.auditStorage` in the Helm values) |
| `unsafe_allow_api_audit_creation = true` | Set in the server configuration, so `bao audit enable` works |
| `audit-sink` (namespace `clients`) | A TCP listener on port `9090` that prints every audit record it receives to its log |

No audit device is enabled yet. Keep the port-forward running in a second terminal:

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
