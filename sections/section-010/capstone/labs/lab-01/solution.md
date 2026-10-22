# Solution: Repair Policies That Deny Or Allow Too Much

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass.

The grader creates one token per policy and sends the reads, refusals and delete from the task. Each policy is fixed on its own, so take them one at a time.

## Step 1: Read the three policies

Start the port-forward and log in as shown in the task, then read the policies:

```sh
bao policy read billing-app
bao policy read reports
bao policy read ci-reader
```

Three different faults show up:

- `billing-app` has a `deny` rule on `secret/data/billing/db`, the secret the application needs, instead of on `secret/data/billing/admin`.
- `reports` uses `secret/data/*/reports`. A `*` only works as a glob at the end of a path, so this rule never matches `secret/data/inventory/reports`.
- `ci-reader` has `read`, `list`, `delete` and `sudo` on `secret/*`, which covers every path on the mount.

## Step 2: Fix billing-app

The exact `deny` rule has a higher priority than the glob, so it decides the request for whatever path it names. Move it to the administrator secret. Save this as `billing-app.hcl`:

```hcl
path "secret/data/billing/*" {
  capabilities = ["read"]
}

path "secret/data/billing/admin" {
  capabilities = ["deny"]
}
```

Load it and check both paths:

```sh
bao policy write billing-app billing-app.hcl
BILLING=$(bao token create -policy=billing-app -ttl=15m -field=token)
bao token capabilities "$BILLING" secret/data/billing/db
bao token capabilities "$BILLING" secret/data/billing/admin
```

The answers are `read` for the database secret and `deny` for the administrator secret.

## Step 3: Fix reports

A `+` matches exactly one path segment and may appear anywhere in the path. Save this as `reports.hcl`:

```hcl
path "secret/data/+/reports" {
  capabilities = ["read"]
}
```

Load it and check a reports secret and a database secret:

```sh
bao policy write reports reports.hcl
REPORTS=$(bao token create -policy=reports -ttl=15m -field=token)
bao token capabilities "$REPORTS" secret/data/billing/reports
bao token capabilities "$REPORTS" secret/data/inventory/db
```

The answers are `read` and `deny`.

## Step 4: Shrink ci-reader

The build system only reads under `secret/ci/`. Save this as `ci-reader.hcl`:

```hcl
path "secret/data/ci/*" {
  capabilities = ["read"]
}
```

Load it and try a read inside and outside the area, and a delete:

```sh
bao policy write ci-reader ci-reader.hcl
CI=$(bao token create -policy=ci-reader -ttl=15m -field=token)
BAO_TOKEN=$CI bao kv get secret/ci/registry
BAO_TOKEN=$CI bao kv get secret/inventory/db
BAO_TOKEN=$CI bao kv metadata delete secret/billing/db
```

The first read works; the second read and the delete fail with `permission denied`.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete the `deny` rule from `billing-app` | The application can read the administrator password |
| Give `reports` a rule on `secret/data/*` | The job can read every team's database secrets |
| Keep `list` on `secret/*` for `ci-reader` | The build system can still see every key name on the mount; key names often leak information |
