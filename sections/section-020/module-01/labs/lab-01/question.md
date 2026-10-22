# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Templated policies

## Scenario

The members of the identity group `staff` (`alice`, `bob` and `dave`) each need a private folder for their secrets in the KV version 2 mount at `secret/`. `carol` works for another team and must not get a folder. The users log in with the userpass method; each password is `<name>-password`, and each user has an identity entity with the same name.

Start `kubectl -n openbao port-forward svc/openbao 8200:8200` and log in with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Your task

1. Write **one** policy named `personal-kv` that lets the caller create, read, update, patch and delete secrets under `secret/users/<their entity name>/`, and list that folder.
2. Make every member of `staff` get this policy, and nobody else.

## Constraints

- Use an identity template in the policy; do not write one rule per user.
- Do not attach `personal-kv` to the userpass users.
- Do not change the group's members.

## Done when

- `alice`, `bob` and `dave` can each write and read a secret under `secret/users/<their name>/`.
- `alice` is refused a read of `secret/users/bob/notes`.
- `carol` is refused a write under `secret/users/carol/`.
