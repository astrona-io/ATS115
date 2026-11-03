# Solution: Delegate Policy Administration Without The Root Token

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass.

The grader creates its own token with `policy-admin`, tries allowed and refused operations on policies, secrets and audit devices, and compares the `default` policy with its state at the start.

## Step 1: Find the paths a policy administrator uses

Ask `bao` which rule a write needs:

```sh
bao write -output-policy sys/policies/acl/app-check policy=x
bao list -output-policy sys/policies/acl
```

The first command prints a rule on `sys/policies/acl/app-check` with the capability `update`. The second prints a rule on `sys/policies/acl` with the capability `list`.

## Step 2: Write the fenced policy

```sh
bao policy write policy-admin - <<'POLICY'
path "sys/policies/acl" {
  capabilities = ["list"]
}
path "sys/policies/acl/app-*" {
  capabilities = ["create", "read", "update", "delete"]
}
POLICY
```

The glob at the end of the second path covers every name that starts with `app-` and nothing else. There is no rule for `secret/` and no `sudo`.

## Step 3: Prove it with a token that only has this policy

```sh
LEAD=$(bao token create -policy=policy-admin -ttl=15m -field=token)
printf 'path "secret/data/app-check/*" {\n  capabilities = ["read"]\n}\n' > app-check.hcl
BAO_TOKEN=$LEAD bao policy write app-check app-check.hcl
BAO_TOKEN=$LEAD bao policy write app-legacy app-check.hcl
BAO_TOKEN=$LEAD bao policy delete app-check
BAO_TOKEN=$LEAD bao policy write team-app app-check.hcl
BAO_TOKEN=$LEAD bao policy write default app-check.hcl
BAO_TOKEN=$LEAD bao kv get secret/inventory/db
```

The first three commands succeed. The writes to `team-app` and `default` and the secret read fail with `permission denied`. If you changed `app-legacy` here, that is allowed by the task.

## Step 4: Submit

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Use `sys/policies/acl/*` | The lead can rewrite `default` and every other team's policy |
| Add `sudo` to make an error go away | The token gains access to root-protected paths such as audit devices |
| Hand out the root token | Every check passes, and the lead can do anything |
| Forget the `list` rule on `sys/policies/acl` | `bao policy list` is refused |

## Practice on your own

- Add `app-*` rules for a second prefix and check that the old fence still holds.
- Remove the `delete` capability and check which command fails.
