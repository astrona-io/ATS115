# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Policies

## Scenario

Three teams asked for policies on the KV version 2 mount at `secret/`, and three tickets came back:

- The billing application cannot read `secret/billing/db`, although its policy `billing-app` was meant to block only the administrator password at `secret/billing/admin`.
- The reporting job with the policy `reports` cannot read any team's `reports` secret.
- A security review found that the build system's policy `ci-reader` can read and delete every secret on the server. The build system only reads its own secrets under `secret/ci/`.

Start `kubectl -n openbao port-forward svc/openbao 8200:8200` and log in with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Your task

Fix the three policies so that a token with only that policy behaves like this:

1. `billing-app`: reads `secret/billing/db` and `secret/billing/reports`, and is refused `secret/billing/admin`.
2. `reports`: reads `secret/inventory/reports` and `secret/billing/reports`, and is refused every other secret.
3. `ci-reader`: reads `secret/ci/registry`, is refused every secret outside `secret/ci/`, and cannot delete anything.

## Constraints

- Keep the three policy names.
- Do not give any of the three policies `sudo`.
- Do not move or rename the secrets.

## Done when

- Each policy allows exactly the reads listed above for a new token that has only that policy.
- `billing-app` is refused `secret/billing/admin`, `reports` is refused `secret/inventory/db`, and `ci-reader` is refused `secret/inventory/db` and a delete of `secret/billing/db`.
