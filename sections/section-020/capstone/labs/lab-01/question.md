# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Control groups

## Scenario

Payroll data lives at `secret/payroll/salaries` in the KV version 2 mount at `secret/`. The rule is simple: only the payroll team may ask for it, and the data is only released after one member of the approvers group agrees. The policy `payroll-read` with a control group was written for this, but it does not work:

- `dave`, the payroll team's only member, never gets his request approved.
- `alice`, who works in `staff`, can request payroll data too.

The users log in with the userpass method; each password is `<name>-password`. The identity groups `staff`, `payroll` and `approvers` exist. `carol` is the approver.

Start `kubectl -n openbao port-forward svc/openbao 8200:8200` and log in with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Your task

Make the payroll rule work:

1. A read of `secret/payroll/salaries` by a member of the group `payroll` is held until one member of the group `approvers` approves it, and then returns the data when unwrapped.
2. `carol` can approve such a request.
3. `alice`, who is in `staff` but not in `payroll`, is refused outright.

## Constraints

- Keep the policy name `payroll-read` and its control group with one approval from the group `approvers`.
- Do not delete and create again any of the groups `staff`, `payroll` or `approvers`; change them.
- Do not give anybody a policy that reads `secret/payroll/` without a control group.

## Done when

- `dave`'s read returns a wrapping token instead of data, `carol` authorizes it with the accessor, and `dave`'s unwrap returns the salaries.
- `alice`'s read is refused with `permission denied`.
- The three groups are the original ones.
