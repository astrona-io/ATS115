# Overview: Manage Policies In Production (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao, initializes and unseals it, writes example data and policies, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao` (pod `openbao-0`), **initialized and unsealed**. The lab-only unseal key and root token are in the Secret `openbao-init`.
- A KV version 2 secrets engine at `secret/` with `secret/inventory/db` and `secret/billing/db`.
- A PKI secrets engine at `pki/` with a root certificate authority and the role `web` for names under `example.internal`.
- The policies `team-app` and `app-legacy`.
- The **`bao` CLI 2.7.1** and **Helm 3.22.1** on your machine, and a **tester** pod in the namespace `clients`.

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

- Read `default` with `bao policy read default`, then create a token with `-no-default-policy` and find which commands stop working.
- Change `team-app` while a token that carries it is alive, and check its capabilities before and after.
- Delete `team-app` and read the token lookup of an existing token.
- Write a policy with `allowed_parameters` for `pki/issue/web`, and find a request that each of `allowed_parameters`, `denied_parameters` and `required_parameters` refuses.
- Add `min_wrapping_ttl` to the rule and compare a request with and without `-wrap-ttl`.
- Build `policy-admin` for the prefix `app-` and try to write `default` with it.
