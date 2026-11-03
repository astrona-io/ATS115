# Solution: Scope Team Areas By Metadata And Pass Rights Down A Group Tree

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass.

The grader logs in as each user and tries to read the four secrets.

## Step 1: Write the templated team policy

```sh
bao policy write team-area - <<'POLICY'
path "secret/data/teams/{{identity.entity.metadata.team}}/*" {
  capabilities = ["read"]
}
POLICY
bao write identity/group name=staff policies=team-area
```

The policy has one rule. For alice it builds `secret/data/teams/red/*`, and for carol `secret/data/teams/blue/*`.

## Step 2: Write and attach the department policies

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

## Step 3: Put platform inside engineering

The member lists of a group are replaced as a whole, so send dave again:

```sh
PLATFORM_ID=$(bao read -field=id identity/group/name/platform)
DAVE_ID=$(bao read -field=id identity/entity/name/dave)
bao write identity/group name=engineering member_group_ids="$PLATFORM_ID" member_entity_ids="$DAVE_ID"
```

## Step 4: Prove it as each user

```sh
login_as() { bao login -method=userpass -token-only -no-store username="$1" password="$1-password"; }
for u in alice bob carol dave; do
  T=$(login_as "$u")
  echo "== $u"
  for s in teams/red/plan teams/blue/plan eng/handbook platform/runbook; do
    BAO_TOKEN=$T bao kv get "secret/$s" >/dev/null 2>&1 && echo "read  $s" || echo "deny  $s"
  done
done
```

The table of results is the one in the task. If a user gets nothing from the team policy, read the entity with `bao read identity/entity/name/<user>` and check the `team` key.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| One policy per team | The task forbids it, and it does not scale to many teams |
| Attach the handbook policy to carol's entity | Rights no longer follow the group tree, and carol keeps them if she leaves |
| Write `member_group_ids` without dave | Dave is removed from `engineering` and loses the handbook |
| Put the policy on `platform` and expect it to flow up | Rights flow from parent to child members, not the other way |

## Practice on your own

- Look at `identity_policies` in the token lookup for carol.
- Remove the `team` key from one entity and watch that user lose the team area.
