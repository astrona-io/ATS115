# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Audit

## Scenario

Management asks who has read the secret `secret/payroll/salaries`. The audit device `file/` writes to `/openbao/audit/audit.log` in the pod `openbao-0`, and it has been enabled since before the users logged in. Four users exist: `alice`, `bob`, `carol` and `dave`. The policy `general-read` belongs to alice and carol. The policy `payroll-read` belongs to bob and dave.

Start `kubectl -n openbao port-forward svc/openbao 8200:8200` and log in with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Your task

1. Find in the audit log which user successfully read `secret/payroll/salaries`.
2. Count how many times that user read it.
3. Find which user tried to read it and was refused.
4. Write the answers to the KV version 2 secret `secret/incident/answer` with the keys `reader` (the user name, for example `bob`), `reads` (the number) and `denied` (the user name).

## Constraints

- Answer from the audit log. The policies alone do not tell you who actually read the secret.
- Do not disable, change or delete the audit device or the audit log.
- Count each request once.
- Ignore the writes that the root token made during setup. Only reads count.

## Done when

- `secret/incident/answer` holds the correct `reader`, `reads` and `denied`.
- The audit device `file/` is still enabled and the log still holds all earlier records.
