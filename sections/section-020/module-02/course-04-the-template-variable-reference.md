# The Template Variable Reference

A templated policy is one policy with a path that changes for each caller. OpenBao fills in the template from the caller's identity before it matches the path. One policy replaces hundreds of per-user policies, and the identity objects from the previous parts provide the values. This part lists every variable and shows how each behaves, including the case that causes the most mistakes: a value that is not there.

## The variables

Templates use double curly braces inside the `path` of a rule. Only the path is templated.

| Variable | Value |
| --- | --- |
| `{{identity.entity.id}}` | The ID of the entity |
| `{{identity.entity.name}}` | The name of the entity |
| `{{identity.entity.metadata.<key>}}` | The entity metadata value for `<key>` |
| `{{identity.entity.aliases.<mount accessor>.id}}` | The ID of the entity's alias on that mount |
| `{{identity.entity.aliases.<mount accessor>.name}}` | The login name of the alias on that mount |
| `{{identity.entity.aliases.<mount accessor>.metadata.<key>}}` | A metadata value of that alias |
| `{{identity.groups.ids.<group id>.name}}` | The name of the group with that ID, if the entity is a member |
| `{{identity.groups.names.<group name>.id}}` | The ID of the group with that name, if the entity is a member |

The alias variables need the mount accessor in the variable. That makes a policy depend on one specific mount.

<!-- astrona:playground:renew -->

## Metadata in a path

The playground gave each entity the metadata key `team`. This policy gives every person read access to their team's area and nothing else:

```sh
bao policy write team-area - <<'POLICY'
path "secret/data/teams/{{identity.entity.metadata.team}}/*" {
  capabilities = ["read"]
}
POLICY
bao write identity/group name=staff policies=team-area
```

Test two users that have different teams:

```sh
ALICE=$(bao login -method=userpass -token-only -no-store username=alice password=alice-password)
CAROL=$(bao login -method=userpass -token-only -no-store username=carol password=carol-password)
BAO_TOKEN=$ALICE bao kv get secret/teams/red/plan
BAO_TOKEN=$ALICE bao kv get secret/teams/blue/plan
BAO_TOKEN=$CAROL bao kv get secret/teams/blue/plan
```

Alice reads the red plan and is refused on the blue plan. Carol reads the blue plan. One rule produced two different effective rules, `secret/data/teams/red/*` and `secret/data/teams/blue/*`.

## The alias name in a path

To use the login name instead of metadata, read it from the alias on the userpass mount. First print the accessor:

```sh
bao auth list -format=json | jq -r '."userpass/".accessor'
```

Then use the printed value in the variable. The text below uses `auth_userpass_0123abcd` as a placeholder for your accessor:

```hcl
path "secret/data/users/{{identity.entity.aliases.auth_userpass_0123abcd.name}}/*" {
  capabilities = ["read", "create", "update"]
}
```

The variable ties the policy to the userpass mount. A user who logs in through another mount with an alias of the same name gets nothing from this rule.

## Group variables

Group variables resolve only for groups the entity belongs to. This rule gives the members of the group named `platform` a shared area, and gives everyone else no match:

```hcl
path "secret/data/groups/{{identity.groups.names.platform.id}}/*" {
  capabilities = ["read"]
}
```

For a member of `platform` the path becomes `secret/data/groups/<the group ID>/*`. For anyone else the variable has no value.

## When a value is missing

If a variable has no value for the caller, such as `metadata.team` on an entity that has no `team` key, OpenBao cannot build the path. It does not return an error and does not use an empty string. The rule is skipped, as if it were not in the policy. The effect is a quiet refusal: the caller gets `permission denied` and no hint why. Always check the entity when a templated policy does not work:

```sh
bao read identity/entity/name/alice
BAO_TOKEN=$ALICE bao token capabilities secret/data/teams/red/plan
```

The first command shows the metadata keys that exist. The second shows what the template produced for that token.

## Limits to remember

Templates work in the `path` of a rule. A token without an entity, such as one made by `bao token create`, has no identity values, so every templated rule is skipped for it. A value is inserted as text, so an entity with a metadata value that contains `/` or `*` changes the shape of the path. Control who can write entity metadata as strictly as you control the policy.

You can now use every identity value in a policy path, and you can tell why a rule does not match when a value is missing. The graded lab combines the pieces: a templated policy for team areas, and a group inside a group.

## Common pitfalls

> [!WARNING]
> - **Using templates with tokens that have no entity.** A token from `bao token create` has no identity, so templated rules never match.
> - **Letting users edit their own metadata.** If a user can write `identity/entity/...`, the user can change the path the template builds.
> - **Expecting an error for a missing value.** The rule is skipped without a message.
> - **Hard-coding the accessor in a shared policy.** The accessor changes when the mount is recreated.

## Your mission: Scope Team Areas By Metadata And Pass Rights Down A Group Tree

You can now build templated policies and group trees and find the source of a right. The mission gives you four users, an entity with a team for each, three groups with nothing attached, and secrets for each team and department. You write the policies and connect the groups so that each user gets exactly their rights.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-115-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS115.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-115-lab-020-02
astrona start ats-115-playground-020-02
```
