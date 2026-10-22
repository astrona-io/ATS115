# Overview: Hand Over Secrets Safely And Control Their Lifetime (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao, initializes and unseals it, sets up AppRole and PKI, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao` (pod `openbao-0`), **initialized and unsealed**. The lab-only unseal key and root token are in the Secret `openbao-init`.
- A KV version 2 secrets engine at `secret/` with `secret/inventory/db`, and the policy `inventory-app` that reads `secret/inventory/`.
- The AppRole auth method at `approle/` with the role `inventory`; its tokens get `inventory-app`.
- A PKI secrets engine at `pki/` with a root CA and the role `web`, which issues certificates for `*.inventory.local` with a lease (`generate_lease=true`).
- The **`bao` CLI 2.7.1** on your machine, and a **tester** pod in the namespace `clients`.

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

Paste these once in each new terminal. `wrapped_secret_id` prints a wrapping token that holds a new secret ID for the role `inventory`. `issue_cert` issues a certificate for a host name and prints its lease ID.

```sh
wrapped_secret_id() { bao write -wrap-ttl="${1:-10m}" -f -field=wrapping_token auth/approle/role/inventory/secret-id; }
issue_cert() { bao write -format=json pki/issue/web common_name="$1" ttl=24h | jq -r .lease_id; }
```

Use them like this: `TOKEN=$(wrapped_secret_id 5m)`, `LEASE=$(issue_cert shop.inventory.local)`.

## Practice tasks

- Wrap a secret ID, unwrap it, and try the lookup and the unwrap a second time.
- Wrap a secret ID, then wrap its unwrapped value again with `bao write sys/wrapping/wrap`, and compare the two creation paths.
- Issue three certificates, list `sys/leases/lookup/pki/issue/web`, and revoke the middle one only.
- Try `bao lease renew` on a certificate lease, and read the error.
- Build a parent, a child and an orphan token, revoke the parent, and check which of the three still work.
- Revoke a token with `-mode=orphan` and look up its child afterwards.
- Write a policy with `min_wrapping_ttl` and `max_wrapping_ttl` on the secret ID path, and test it with and without `-wrap-ttl`.
