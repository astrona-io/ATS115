# Solution: Give Every User A Private KV Area

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass.

The grader reads the policy to check that it uses an identity template, then logs in as `alice`, `bob`, `dave` and `carol` and sends real writes and reads.

## Step 1: Check the identities

Start the port-forward and log in as shown in the task. Then check that the entity names match the user names, and who is in `staff`:

```sh
bao read identity/entity/name/alice
bao read identity/group/name/staff
```

The entity is named `alice`, and the group lists three member entity IDs. So a template on `identity.entity.name` gives each user a folder named after them.

## Step 2: Write the templated policy

Save this as `personal-kv.hcl`:

```hcl
path "secret/data/users/{{identity.entity.name}}/*" {
  capabilities = ["create", "read", "update", "patch", "delete"]
}

path "secret/metadata/users/{{identity.entity.name}}/*" {
  capabilities = ["list"]
}
```

Load it:

```sh
bao policy write personal-kv personal-kv.hcl
```

## Step 3: Attach it to the group

```sh
bao write identity/group/name/staff policies=personal-kv
```

Group policies are identity policies: OpenBao looks them up on every request, so members get them without a new login, and `carol`, who is not a member, does not.

## Step 4: Prove it as the users

```sh
ALICE=$(bao login -method=userpass -token-only -no-store username=alice password=alice-password)
BAO_TOKEN=$ALICE bao kv put secret/users/alice/notes text="alice's notes"
BAO_TOKEN=$ALICE bao kv get secret/users/alice/notes
BAO_TOKEN=$ALICE bao kv get secret/users/bob/notes
CAROL=$(bao login -method=userpass -token-only -no-store username=carol password=carol-password)
BAO_TOKEN=$CAROL bao kv put secret/users/carol/notes text="hello"
```

`alice` writes and reads her own notes, and is refused `bob`'s. `carol` is refused because she is not in `staff`. Repeat the first three commands for `bob` and `dave` if you like.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| One policy per user | Works today, and needs a new policy for every new member |
| A rule on `secret/data/users/*` | Every user can read every other user's folder |
| `personal-kv` in every user's `token_policies` | `carol` gets a folder too, and removing someone from `staff` no longer removes their access |
