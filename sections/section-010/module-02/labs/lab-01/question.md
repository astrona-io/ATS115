# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Policies

## Scenario

The payments team lead manages the team's policies, and today does it with the root token. Security wants that to stop. The team's policies all have names that start with `app-`, for example `app-legacy`. Other teams' policies, such as `team-app`, and the built-in `default` policy belong to other people and must stay out of reach.

Start `kubectl -n openbao port-forward svc/openbao 8200:8200` and log in with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Your task

1. Write a policy named `policy-admin`. A token with it must be able to create, read, change and delete policies whose names start with `app-`, and list the policy names.
2. Prove it with a token that carries only `policy-admin` and `default`: write a policy called `app-check`, change `app-legacy`, then delete `app-check`.

## Constraints

- The token must not be able to write `default`, `team-app` or any policy whose name does not start with `app-`.
- The token must not read secrets under `secret/`.
- Do not use `sudo` in the policy, and do not give the token the `root` policy.
- Do not change the `default` policy.

## Done when

- A token with `policy-admin` writes and deletes `app-` policies and lists policy names.
- The same token is refused when it writes `default` or `team-app`, reads `secret/data/inventory/db`, or enables an audit device.
- The text of `default` is the same as at the start.
