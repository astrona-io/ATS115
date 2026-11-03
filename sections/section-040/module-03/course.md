# Investigate Incidents With The Audit Log

When something goes wrong, the questions come in a fixed form. Who read this secret? When? Was anyone refused before someone succeeded? What else did that identity do? The audit log has the answers, but only for a person who knows how to read it. Values are hashed, lines come in pairs, and a single day can hold millions of lines.

This module teaches how to read a record, how to find the records you need without reading the rest, how to follow one identity through the log, and which patterns are worth an alert.

The module has four parts. **Reading An Audit Record** names the fields and shows how a request and its response pair up. **Finding Records With Hashes And Filters** finds a value, a token and a path without exposing a secret. **Following An Identity Through The Log** builds a timeline for one user or one token. **Patterns Worth An Alert** lists what to watch for. A graded lab follows the last part.

## Learning objectives

After this module you can:

- Name the main fields of a request entry and a response entry, and match the two by request ID.
- Filter an audit log with `jq` by path, operation, identity and time.
- Hash a known value or a token accessor with `sys/audit-hash` and search a log for it.
- Tell a successful request from a refused one in the log.
- Count how often an identity read a path.
- Build a timeline for one identity and report what it touched.
- List patterns that should raise an alert.

## Before you start

You should be able to enable a file audit device, read a log with `kubectl exec`, and hash a value with `sys/audit-hash`. A command-line `jq` on your machine makes the filters shorter. If you do not have it, run `jq` in the tester pod with `kubectl -n clients exec -i deploy/tester -- jq`.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, installed with the `openbao` Helm chart 0.30.4, **initialized and unsealed**. It contains:

| Object | What it is |
| --- | --- |
| KV version 2 at `secret/` | Holds `secret/general/handbook`, `secret/payroll/salaries` and `secret/payroll/benefits` |
| Userpass users | `alice`, `bob`, `carol` and `dave`; each password is `<name>-password` |
| Policies | `general-read` (alice and carol) and `payroll-read` (bob and dave) |
| Audit device `file/` | A file device at `/openbao/audit/audit.log`, already holding the records of earlier activity |

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
