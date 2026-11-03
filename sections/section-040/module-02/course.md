# Tune Audit Devices For Production

An audit device that works in a test can fail in production in quiet ways. It can write secrets in clear text. It can write so much that it fills the disk, and then every request to OpenBao fails. It can send records to a network address that sometimes drops them. The audit log is only worth having if it is complete, safe to store and cheap to keep.

This module covers the options that change what a device records and how it writes, the settings of the socket device, and the operating habits that keep an audit log healthy: rotation, volume size, shipping and failure drills.

The module has four parts. **Hashing Options And Raw Logging** covers `hmac_accessor` and `log_raw`. **Shaping The Log Lines** covers `elide_list_responses`, `prefix` and `mode`. **Socket Device Settings** covers addresses, socket types and write timeouts. **Operate Audit Logs Safely** covers rotation, volume sizing, shipping and a failure drill. A graded lab follows the last part.

## Learning objectives

After this module you can:

- Explain what `hmac_accessor` and `log_raw` change, and why `log_raw` is unsafe outside a debugging session.
- Read the options of a device with `bao audit list -detailed`.
- Enable a file device with `elide_list_responses`, `prefix` and `mode`.
- Explain why options cannot be changed on a running device, and what replacing a device does to its hashes.
- Choose between the TCP, UDP and Unix socket types and set `write_timeout`.
- Rotate an audit file, and plan the size of an audit volume.
- Run a failure drill and read the result.

## Before you start

You should be able to enable a `file` and a `socket` audit device, and find a value in a log with `sys/audit-hash`.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, installed with the `openbao` Helm chart 0.30.4, **initialized and unsealed**. It contains:

| Object | What it is |
| --- | --- |
| KV version 2 at `secret/` | Holds `secret/inventory/db` and `secret/billing/db` |
| Audit volume | A 1 GiB PersistentVolumeClaim mounted at `/openbao/audit` in `openbao-0` |
| `unsafe_allow_api_audit_creation = true` | Set in the server configuration, so `bao audit enable` works |
| `audit-sink` (namespace `clients`) | A TCP listener on port `9090` that prints every audit record it receives to its log |
| Audit device `debug/` | A file device at `/openbao/audit/debug.log` left over from a test, with `log_raw=true` and `hmac_accessor=false` |

The playground puts the `bao` command-line tool 2.7.1 on your machine. OpenBao answers at `http://openbao.localtest.me:8200`. Keep this port-forward running in a second terminal, and start it again if the OpenBao pod restarts:

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
