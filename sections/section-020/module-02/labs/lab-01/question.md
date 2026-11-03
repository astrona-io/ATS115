# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Identity

## Scenario

The company has four users, `alice`, `bob`, `carol` and `dave`. Each has an entity with the metadata key `team`: `red` for alice and bob, `blue` for carol and dave. The Secrets are `secret/teams/red/plan`, `secret/teams/blue/plan`, `secret/eng/handbook` and `secret/platform/runbook`. The groups `staff` (all four), `platform` (carol) and `engineering` (dave) exist, with no policies. Nobody can read anything yet.

Start `kubectl -n openbao port-forward svc/openbao 8200:8200` and log in with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Your task

1. Write one policy named `team-area` that lets a user read `secret/teams/<team>/*`, where `<team>` is the `team` metadata of the user's entity. Attach it to the group `staff`.
2. Write a policy `eng-handbook` that reads `secret/eng/*` and attach it to the group `engineering`.
3. Write a policy `platform-runbook` that reads `secret/platform/*` and attach it to the group `platform`.
4. Make `platform` a member group of `engineering`, so that its members receive the handbook policy too. Keep dave a member of `engineering`.

## Constraints

- Use one templated policy for the team areas. Do not write a policy per team.
- Do not attach any policy to a user's entity or to a token directly.
- Do not remove any user from any group.

## Done when

- alice and bob read the red plan and not the blue plan; carol and dave read the blue plan and not the red plan.
- carol reads the handbook and the runbook; dave reads the handbook and not the runbook; alice and bob read neither.
