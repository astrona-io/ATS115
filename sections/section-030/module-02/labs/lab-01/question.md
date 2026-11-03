# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Tokens

## Scenario

Worker processes create their own tokens through the token role `worker`. The role is too loose: it allows any policy, every token ends after 30 minutes whether or not the worker renews it, and the tokens are children of the token that created them, so a restart of the creator kills all workers.

The policy `worker-spawner` already lets the spawner token use the path `auth/token/create/worker` and nothing else. The secret `secret/worker/queue` and the policies `worker-read`, `worker-write` and `admin-ops` exist.

Start `kubectl -n openbao port-forward svc/openbao 8200:8200` and log in with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Your task

Change the token role `worker` so that:

1. Only the policy `worker-read` can be requested through it.
2. Its tokens are periodic with a period of one hour and have no explicit maximum TTL.
3. Its tokens are orphans.
4. Its tokens can be renewed.

## Constraints

- Do not change the policies `worker-spawner` and `admin-ops`.
- Do not give the spawner any path other than `auth/token/create/worker`.

## Done when

- A token with the policy `worker-spawner` can create a token through the role `worker` for the policy `worker-read`.
- That new token is periodic with a period of one hour, is an orphan, has no explicit maximum TTL, can read `secret/worker/queue` and cannot write it.
- A request through the role for the policy `worker-write` is refused, and the same spawner token cannot use the open path `auth/token/create`.
