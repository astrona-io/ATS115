# Overview: Write Least-Privilege Policies (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao, initializes and unseals it, writes some example secrets, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao` (pod `openbao-0`, Service `openbao` on port `8200`), installed with the `openbao` Helm chart 0.30.4, **initialized and unsealed**. The lab-only unseal key and root token are in the Secret `openbao-init`.
- A KV version 2 secrets engine at `secret/` with `secret/inventory/{db,api,reports}`, `secret/billing/{db,admin,reports}` and `secret/ci/registry`.
- A **tester** pod in the namespace `clients` with `curl` and `jq`.
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

## Helpers

Paste these once in each new terminal. `token_with` creates a 15-minute token that has only the given policies and prints it. `try_as` runs one `bao` command with a given token, so your shell keeps the root token.

```sh
token_with() {
  local policy_flags=()
  for policy in "$@"; do policy_flags+=("-policy=$policy"); done
  bao token create -ttl=15m -field=token "${policy_flags[@]}"
}
try_as() { local token="$1"; shift; BAO_TOKEN="$token" bao "$@"; }
```

Use them like this: `APP=$(token_with inventory-read)`, then `try_as "$APP" kv get secret/inventory/db`.

## Practice tasks

- Run `bao kv get -output-policy`, `bao kv list -output-policy` and `bao kv metadata delete -output-policy` on an inventory secret, and write down the API path and capability of each.
- Write a policy with rules on `secret/inventory/*` and prove with `bao token capabilities` that it allows nothing on the KV version 2 mount.
- Give one token two policies: one with `list` on `secret/metadata/inventory/*` and one with `read` on `secret/metadata/inventory/db`. Predict the capabilities on `secret/metadata/inventory/db`, then check.
- Write a `deny` rule for `secret/data/billing/admin` and prove that a token that also has a `read` rule on `secret/data/billing/*` cannot read it.
- Compare `secret/data/+/reports` and `secret/data/*/reports` with `bao token capabilities`.
- Give a policy `sudo` on `sys/audit/*` and read `bao audit list -detailed` with and without it.
