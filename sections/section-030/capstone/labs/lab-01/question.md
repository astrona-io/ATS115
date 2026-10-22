# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Leases

## Scenario

The token of the build orchestrator `ci-parent` was pasted into a public ticket. Before anyone noticed, `ci-parent` had created a child token, `build-1`, and `build-1` had issued two certificates from the PKI role `web`. A separate token, `release-bot`, issued one more certificate. `release-bot` was created as an orphan by an operator and has nothing to do with the leak. The ConfigMap `incident` in the namespace `clients` holds the accessor of the leaked token (`leaked-accessor`) and of `release-bot` (`release-bot-accessor`).

The review also found that the policy `secret-id-issuer`, used by the pipeline to get AppRole secret IDs for the role `inventory`, lets the pipeline read secret IDs in plain text.

Start `kubectl -n openbao port-forward svc/openbao 8200:8200` and log in with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Your task

1. Revoke the leaked token `ci-parent`, together with every token and lease it created, directly or through its children.
2. Keep `release-bot` and the lease of its certificate valid.
3. Change `secret-id-issuer` so a secret ID for the role `inventory` can only be returned wrapped, with a wrapping TTL of at most 5 minutes.

## Constraints

- You only have accessors for the tokens. Work with them; do not create new tokens for `ci-parent`'s work.
- Do not use `-prefix` revocation.
- Keep the policy name `secret-id-issuer`.

## Done when

- `ci-parent` and `build-1` can no longer be looked up, and the two certificate leases `build-1` created are gone.
- `release-bot` and its certificate lease still exist.
- A token with `secret-id-issuer` is refused a plain secret ID and a secret ID wrapped for 30 minutes, and gets one wrapped for 2 minutes.
