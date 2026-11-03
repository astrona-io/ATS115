# Overview: Choose Token Types, Lifetimes And Roles (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao, initializes and unseals it, creates a few policies and a token role, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao` (pod `openbao-0`), **initialized and unsealed**. The lab-only unseal key and root token are in the Secret `openbao-init`.
- A KV version 2 secrets engine at `secret/` with the secret `secret/worker/queue`.
- The policies `worker-read` (reads `secret/data/worker/*`), `worker-write` (creates and updates it), `admin-ops` (a broad policy on `sys/*`) and `worker-spawner` (allows only `auth/token/create/worker`).
- The token role `worker` with loose settings: no allowed policies, not an orphan, and an explicit maximum TTL of 30 minutes.
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

- Create a service token and a batch token with the same policy, and compare the fields in `bao token lookup`.
- Try `bao token renew` on a batch token and read the error.
- Create a token with `-ttl=2400h` and compare the `lease_duration` in the answer with what you asked for.
- Create a token with `-ttl=10m -explicit-max-ttl=1h`, renew it with `-increment=2h`, and look up the remaining TTL.
- Create a periodic token with `-period=1h`, renew it, and see the TTL return to the period.
- Change the role `worker` to allow only `worker-read`, and check that a request for `worker-write` is refused.
- Create a token with `-use-limit=2` and count how many requests it survives.
- Find a token by its accessor with `bao token lookup -accessor`, and revoke it with `bao token revoke -accessor`.
- Write a role with `token_bound_cidrs=203.0.113.0/24` and see the token refused.
