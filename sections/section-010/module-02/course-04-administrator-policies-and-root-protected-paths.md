# Administrator Policies And Root-Protected Paths

At some point someone other than you must manage policies, mounts or authentication methods. The shortcut is to hand out the root token, and that shortcut ends in an incident: the root policy cannot be limited, and one leaked token controls the whole server. This part builds administrator policies with limited reach, and explains `sudo`, the capability that guards a short list of dangerous paths.

## What the root policy is, and why it is not for people

The `root` policy allows every capability on every path. A token with it never needs a rule, and no rule can reduce it. OpenBao creates one root token at initialization. Good practice is to use it once to set up authentication, then revoke it. If you need a root token later, `bao operator generate-root` creates one with the approval of the key holders. Day-to-day administration uses a policy that names the paths an administrator needs.

## Paths that need sudo

A few API paths do more than read or write data: they change how the server protects everything else. These paths need the capability `sudo` in addition to the normal capability. A rule `capabilities = ["update"]` is not enough on them. Examples are the audit device paths under `sys/audit`, `sys/leases/revoke-prefix`, `sys/leases/revoke-force`, the raw storage path `sys/raw`, `sys/rotate`, `sys/seal` and the listing of token accessors at `auth/token/accessors`. The documentation page of each endpoint says if it is root-protected.

Check it. A policy with `update` but not `sudo` on `sys/audit/*` cannot enable a device:

```sh
bao policy write audit-nosudo - <<'POLICY'
path "sys/audit/*" {
  capabilities = ["create", "update", "read"]
}
POLICY
T=$(bao token create -policy=audit-nosudo -ttl=15m -field=token)
bao token capabilities "$T" sys/audit/file
```

The answer lists the capabilities without `sudo`, so an enable request is refused. Adding `"sudo"` to the list is the one change that allows it. Because `sudo` can make a rule much stronger than its name suggests, treat every rule that contains it as a reviewed exception.

## A policy administrator with a fence

The task: a team lead may create and change policies whose names start with `app-`, and list all policy names, but must not be able to change `default`, `root`, or any other team's policies, and must not read secrets.

<!-- astrona:playground:renew -->

```sh
bao policy write policy-admin - <<'POLICY'
path "sys/policies/acl" {
  capabilities = ["list"]
}
path "sys/policies/acl/app-*" {
  capabilities = ["create", "read", "update", "delete"]
}
POLICY
LEAD=$(bao token create -policy=policy-admin -ttl=30m -field=token)
```

Test the allowed and refused operations one by one:

```sh
printf 'path "secret/data/app-demo/*" {\n  capabilities = ["read"]\n}\n' > app-demo.hcl
BAO_TOKEN=$LEAD bao policy write app-demo app-demo.hcl
BAO_TOKEN=$LEAD bao policy list
BAO_TOKEN=$LEAD bao policy write team-other app-demo.hcl
BAO_TOKEN=$LEAD bao policy write default app-demo.hcl
BAO_TOKEN=$LEAD bao kv get secret/inventory/db
```

The first write and the list succeed. The writes to `team-other` and `default` fail with `permission denied`, because only names that start with `app-` match the second rule. The secret read fails too. The glob at the end of the rule is what builds the fence; the exact name of the policy decides everything.

## The fence has two gaps to know about

A policy administrator can write any content into an `app-` policy, including a rule that allows everything. The policy does nothing until a token carries it, and attaching it is a separate right: it needs access to token creation, to an auth method role, or to identity. If the administrator also holds that right, the fence is gone. Give policy writing and policy attachment to different roles, and review who holds both.

The second gap is `sys/policies/acl/app-*` itself. A glob after the prefix also matches `app-` followed by slashes, so a rule intended for flat names covers nested paths too. Choose a naming rule and keep to it.

You now know that administration does not need `root`, which paths need `sudo`, and how a glob builds a fence around a set of policy names. A graded lab follows: you will build exactly this kind of delegated role.

## Common pitfalls

> [!WARNING]
> - **Adding `sudo` to make an error go away.** The refusal tells you the path is protected. Find out why the task needs it before you grant it.
> - **Granting `sys/policies/acl/*` to a team lead.** That includes `default` and every other team's policies. Fence with a name prefix.
> - **Letting one role write and attach policies.** Together these rights equal full control.
> - **Keeping the initial root token.** Revoke it after setup and use `bao operator generate-root` when you really need one.

## Your mission: Delegate Policy Administration Without The Root Token

You can now write policies with fences and prove what they allow. The mission gives you a team whose lead currently uses the root token for one job: managing the team's own policies. You replace that with a policy that does only that job.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-115-playground-010-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS115.git -c sections/section-010/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-115-lab-010-02
astrona start ats-115-playground-010-02
```
