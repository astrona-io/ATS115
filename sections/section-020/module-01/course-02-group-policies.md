# Policies On Identity Groups

A templated policy attached to each user still has to be attached thirty times, and removed again when somebody leaves. An **identity group** is a set of entities with its own list of policies. Every member gets the group's policies on every request, without logging in again. This part moves the templated policy onto a group and shows where a token's policies really come from.

## Two places a token's policies come from

A token can get policies from two places, and OpenBao uses both. **Token policies** are fixed when the token is created; for a userpass login they come from the user's `token_policies` setting. **Identity policies** come from the token's entity and the groups the entity belongs to, and OpenBao looks them up on every request.

<!-- astrona:playground:renew -->

See both lists on one token. Log in as `dave`, who is a member of the group `staff`, and look the token up:

```sh
DAVE=$(bao login -method=userpass -token-only -no-store username=dave password=dave-password)
BAO_TOKEN=$DAVE bao token lookup
```

The `policies` field lists the token policies: `default`. The `identity_policies` field is empty, because the group `staff` has no policies yet. Read the group to see its members:

```sh
bao read identity/group/name/staff
```

The output lists `member_entity_ids` for `alice`, `bob` and `dave`, and an empty `policies` list. `carol` is not a member.

## Attaching the templated policy to a group

The `personal-kv` policy gives each caller their own folder under `secret/users/`. Save this as `personal-kv.hcl` if you do not have it yet:

```hcl
path "secret/data/users/{{identity.entity.name}}/*" {
  capabilities = ["create", "read", "update", "patch", "delete"]
}

path "secret/metadata/users/{{identity.entity.name}}/*" {
  capabilities = ["list"]
}
```

Load it and attach it to the group, not to the users:

```sh
bao policy write personal-kv personal-kv.hcl
bao write identity/group/name/staff policies=personal-kv
```

Then check `dave`'s existing token, without logging in again:

```sh
BAO_TOKEN=$DAVE bao token lookup
BAO_TOKEN=$DAVE bao kv put secret/users/dave/todo text="renew certificates"
```

The `identity_policies` field now lists `personal-kv`, and the write succeeds. The token is the same one; OpenBao looked up the group's policies on this request.

Now try `carol`, who is not in `staff`:

```sh
CAROL=$(bao login -method=userpass -token-only -no-store username=carol password=carol-password)
BAO_TOKEN=$CAROL bao kv put secret/users/carol/todo text="hello"
```

The write fails with `permission denied`. Membership of the group decides who gets a private folder, and adding or removing a person is one change to the group.

## Where to attach which policy

The two places suit different jobs. The table sums up the choice:

| Attach to | Applies | Use it for |
| --- | --- | --- |
| The auth method's role or user (`token_policies`) | From the next login | Machine logins, such as an AppRole role or a Kubernetes role |
| An identity group (`policies`) | On the next request, for every member | People and teams; access that changes with membership |
| Both | The union of both lists | Rarely; it makes it hard to see why a token has a right |

A group can also be a member of another group, through `member_group_ids`, and its members then get the policies of both groups. Keep nesting shallow, because every level makes it harder to answer "why can this person read that secret?".

You now know that a token's rights come from its own policies and from its entity's groups, and that group policies take effect at once. With one templated policy on one group, every member has a private folder and nobody else does. The open question is how to protect secrets that a group may read, but only after somebody else agrees.

## Common pitfalls

> [!WARNING]
> - **Attaching the policy to every user as well as the group.** Removing someone from the group then leaves their access in place. Pick one place.
> - **Looking only at the `policies` field.** Group policies appear in `identity_policies`. Read both.
> - **Logging in again to "pick up" a group change.** Not needed; identity policies are evaluated on every request.
> - **Removing a user from a group but not revoking their old tokens.** Group policies disappear at once, but token policies stay until the token is revoked or expires.

## Your mission: Give Every User A Private KV Area

You can now write a templated policy and attach it to an identity group. The mission asks you to give every member of `staff` a private folder under `secret/users/`, while non-members get none and nobody can read another user's folder.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-115-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS115.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-115-lab-020-01
astrona start ats-115-playground-020-01
```
