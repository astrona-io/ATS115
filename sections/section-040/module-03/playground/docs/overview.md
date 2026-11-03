# Overview: Investigate Incidents With The Audit Log (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao, initializes and unseals it, enables a file audit device, produces some activity, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao` (pod `openbao-0`), **initialized and unsealed**. The lab-only unseal key and root token are in the Secret `openbao-init`.
- A KV version 2 secrets engine at `secret/` with `secret/general/handbook`, `secret/payroll/salaries` and `secret/payroll/benefits`.
- The userpass users `alice`, `bob`, `carol` and `dave`; each password is `<name>-password`. The policy `general-read` belongs to alice and carol, and `payroll-read` to bob and dave.
- The audit device `file/` at `/openbao/audit/audit.log`, which already holds the records of the activity above.
- The `audit-sink` Deployment in the namespace `clients`, and a **tester** pod.
- The **`bao` CLI 2.7.1** and **Helm 3.22.1** on your machine.

Keep the port-forward running in a second terminal:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

Then set these in each terminal where you work:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Practice tasks

- Copy the log with `kubectl -n openbao exec openbao-0 -- cat /openbao/audit/audit.log > audit.log` and read the first lines with `jq .`.
- Pair a request and a response by `request.id`.
- List every request for `secret/data/payroll/salaries` with the identity that made it.
- List all entries that have an error.
- Hash the value `1200000` with `sys/audit-hash/file` and search the log for it.
- Build a timeline for `userpass-dave`.
- Make a few refused requests yourself and find them in the log.
