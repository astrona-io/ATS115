# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** Policies

## Scenario

The inventory team wrote the policy `inventory-app` for their application and attached it to the application's token. Every read of `secret/inventory/db` now fails with `permission denied`. The team also gave the policy `update` "to be safe".

OpenBao answers at `http://openbao.localtest.me:8200` after you start `kubectl -n openbao port-forward svc/openbao 8200:8200`. Log in with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Your task

Change the policy `inventory-app` so a token that has only this policy:

1. reads every secret under `secret/inventory/`, for example `secret/inventory/db` and `secret/inventory/api`;
2. lists the keys under `secret/inventory`;
3. cannot write, delete or destroy any secret;
4. cannot read anything outside `secret/inventory/`.

## Constraints

- Keep the policy name `inventory-app`.
- Do not give the policy `sudo`, `update`, `create`, `patch` or `delete` on any path.
- The secrets engine at `secret/` stays a KV version 2 engine.

## Done when

- A new token with only `inventory-app` reads `secret/inventory/db` and `secret/inventory/api`.
- The same token lists `secret/inventory`.
- The same token is refused a write to `secret/inventory/db`, a delete of its metadata, and a read of `secret/billing/db`.
