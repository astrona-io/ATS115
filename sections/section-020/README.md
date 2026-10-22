# Section 020: Templated Policies And Control Groups

A plain policy gives the same rights to every token that carries it. That works for an application, but not for people: each person should reach their own secrets, and some secrets should only be released when a second person agrees. OpenBao handles both with its identity system. Policies can read who the caller is, policies can be attached to groups, and a control group can hold a request until enough approvers say yes.

**Topic covered:** Identity-aware policies

## What you will learn

- Identity entities, aliases and groups, and how a login maps to an entity.
- Templated policies: paths that contain `{{identity.entity.name}}` or `{{identity.entity.id}}`, filled in per caller.
- Attaching policies to identity groups, and the difference between token policies and identity policies.
- Control groups: the `control_group` factor, `controlled_capabilities`, and the request, approve and unwrap flow.

## The learning path

### 1. Write Identity-Aware Policies And Control Groups

The module starts at its landing page, which also launches the playground. The playground holds OpenBao with the userpass users `alice`, `bob`, `carol` and `dave`, an identity entity for each, and the identity group `staff`.

1. Templated Policies From Identity
2. Policies On Identity Groups, followed by the lab **Give Every User A Private KV Area**
3. Control Groups: A Second Person Approves
4. Summary

## Section capstone: Make Payroll Reads Need An Approval

Payroll data must only be released to the payroll team, and only after an approver agrees. The control group exists, but it names a group that does not exist, the policy sits on the wrong group, and the approvers group has no members. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS115.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-115-capstone-020
```
