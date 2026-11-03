# Groups And Policy Inheritance

Attaching a policy to every person does not scale and is easy to get wrong. A group lets you attach it once. An internal group in OpenBao holds a list of member entities and a list of member groups, and it carries policies and metadata. This part shows how a person's final policy list is built from every group they belong to, directly or through other groups.

## Internal groups

An **internal group** is a group whose members you manage yourself in OpenBao. You create it with `identity/group`, and the default type is `internal`. It holds `member_entity_ids`, a list of entity IDs, and `member_group_ids`, a list of group IDs. Any token tied to a member entity gets the group's policies.

<!-- astrona:playground:renew -->

Read the group `staff` and see who it contains:

```sh
bao read identity/group/name/staff
```

The output lists `member_entity_ids`, `member_group_ids`, `policies`, `metadata` and the group `id`. In the playground, `staff` has the four user entities as members and no policies yet.

Create a policy that reads the red team area and attach it to `staff`:

```sh
bao policy write staff-read - <<'POLICY'
path "secret/data/teams/red/*" {
  capabilities = ["read"]
}
POLICY
bao write identity/group name=staff policies=staff-read
```

A write to an existing group by name changes only the fields you send. The members stay as they are, and `policies` is set to the list you gave. Now check a member's token without a new login:

```sh
ALICE=$(bao login -method=userpass -token-only -no-store username=alice password=alice-password)
BAO_TOKEN=$ALICE bao kv get secret/teams/red/plan
BAO_TOKEN=$ALICE bao token lookup -format=json
```

The read succeeds, and the lookup lists `staff-read` under `identity_policies` and in `policies`, but not in `token_policies`. The right came from the group, not from the token.

## Groups inside groups

A group can be a member of another group. If the group `platform` is a member of the group `engineering`, every member of `platform` is also, by inheritance, a member of `engineering`, and receives the policies of both. The inheritance works in one direction: policies flow from the parent group to members of its child groups, never from a child group up to the parent's own direct members.

Find the group IDs and make `platform` a child of `engineering`:

```sh
PLATFORM_ID=$(bao read -field=id identity/group/name/platform)
DAVE_ID=$(bao read -field=id identity/entity/name/dave)
bao write identity/group name=engineering member_group_ids="$PLATFORM_ID" member_entity_ids="$DAVE_ID"
```

The list in `member_group_ids` and the list in `member_entity_ids` each replace what was there before, so repeat dave when you set the groups. Read `engineering` and `platform` again: `engineering` now lists `platform` in `member_group_ids`, and `platform` lists `engineering` in `parent_group_ids`.

Attach a policy to each level and compare the result for carol, who is only a member of `platform`, with dave, who is only a member of `engineering`:

```sh
bao policy write eng-handbook - <<'POLICY'
path "secret/data/eng/*" {
  capabilities = ["read"]
}
POLICY
bao policy write platform-runbook - <<'POLICY'
path "secret/data/platform/*" {
  capabilities = ["read"]
}
POLICY
bao write identity/group name=engineering policies=eng-handbook
bao write identity/group name=platform policies=platform-runbook
```

Carol's token now reaches both `secret/eng/handbook` and `secret/platform/runbook`: the first through the parent group `engineering`, the second through `platform`. Dave's token reaches only the handbook. Test each with `BAO_TOKEN=<token> bao kv get`.

## Group metadata and names

Groups also carry metadata, which a template can read. A group name is unique and may be used in a template as `{{identity.groups.names.engineering.id}}`. Policies can therefore depend on membership in a named group without a rule for every user. The reference part lists these variables.

## Loops and limits

OpenBao refuses a group structure that loops: a group cannot be its own ancestor. Deep nesting also makes it harder to see where a right came from, so keep the tree shallow. When you debug a surprise, read the token lookup first, then the entity's `group_ids`, then the groups' `parent_group_ids`.

You now know how to attach policies to a group and how a member group passes on rights from its parent. All of these groups are managed by hand in OpenBao. The next part looks at groups whose membership comes from outside.

## Common pitfalls

> [!WARNING]
> - **Replacing a member list by accident.** `member_entity_ids` and `member_group_ids` set the whole list. Send the full list each time.
> - **Expecting rights to flow upward.** The parent's policies reach the child's members. The child's policies do not reach the parent's own direct members.
> - **Looking for the source in `token_policies`.** Group rights show in `identity_policies` only.
> - **Building deep trees.** Each level makes the source of a right harder to trace.
