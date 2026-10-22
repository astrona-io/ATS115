# Solution: Fix The Inventory Application Policy

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader creates its own token with only `inventory-app` and checks three things: it reads both inventory secrets, it lists `secret/inventory`, and it is refused a write, a metadata delete and a read of a billing secret.

## Step 1: Reproduce the failure with a token like the application's

Start the port-forward in a second terminal and log in as shown in the task. Then create a token with only the policy, and try a read:

```sh
APP_TOKEN=$(bao token create -policy=inventory-app -ttl=15m -field=token)
BAO_TOKEN=$APP_TOKEN bao kv get secret/inventory/db
```

The read fails with `permission denied`, just as the team reported.

## Step 2: Compare the policy with the paths the request uses

Read the policy and ask `bao` which rule the read needs:

```sh
bao policy read inventory-app
bao kv get -output-policy secret/inventory/db
```

The policy has one rule, on `secret/inventory/*`, with `read`, `list` and `update`. The read needs `read` on `secret/data/inventory/db`. The engine at `secret/` is KV version 2, so `secret/inventory/*` matches none of its API paths. The `update` capability would also let the application write, which the task forbids.

## Step 3: Write the corrected policy

Save this as `inventory-app.hcl`:

```hcl
# Read every inventory secret.
path "secret/data/inventory/*" {
  capabilities = ["read"]
}

# List the keys under secret/inventory.
path "secret/metadata/inventory/*" {
  capabilities = ["list"]
}

path "secret/metadata/inventory" {
  capabilities = ["list"]
}
```

Load it under the same name:

```sh
bao policy write inventory-app inventory-app.hcl
```

The two `metadata` rules cover a list of `secret/inventory` with or without a trailing slash.

## Step 4: Prove what the policy allows and refuses

OpenBao reads the policy at request time, so the token from step 1 would already see the change. A fresh token, created the way the grader does it, keeps the test clean. Test both sides:

```sh
APP_TOKEN=$(bao token create -policy=inventory-app -ttl=15m -field=token)
BAO_TOKEN=$APP_TOKEN bao kv get secret/inventory/db
BAO_TOKEN=$APP_TOKEN bao kv get secret/inventory/api
BAO_TOKEN=$APP_TOKEN bao kv list secret/inventory
BAO_TOKEN=$APP_TOKEN bao kv put secret/inventory/db password=changed
BAO_TOKEN=$APP_TOKEN bao kv metadata delete secret/inventory/db
BAO_TOKEN=$APP_TOKEN bao kv get secret/billing/db
```

The two reads and the list succeed. The write, the metadata delete and the billing read each fail with `permission denied`.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Keep the rule on `secret/inventory/*` and add `secret/data/*` | The application can read every team's secrets |
| Keep `update` | The application can overwrite its own database password |
| Use the root token in the application | Every check passes, and the application can do anything |
| Switch the engine to KV version 1 | Every version history is lost, and the task forbids it |

## Practice on your own

- Remove the `secret/metadata/inventory` rule and check whether `bao kv list secret/inventory` still works.
- Add a `deny` rule for `secret/data/inventory/api` and predict the answer of `bao token capabilities` before you run it.
