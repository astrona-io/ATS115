# Solution: Make The Worker Role Strict

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass.

The grader makes a spawner token, creates a worker token through the role, and looks the worker token up.

## Step 1: Read the role

```sh
bao read auth/token/roles/worker
```

Note `allowed_policies` (empty), `orphan` (false) and `token_explicit_max_ttl` (30 minutes).

## Step 2: Write the strict role

```sh
bao write auth/token/roles/worker \
  allowed_policies=worker-read \
  token_period=1h \
  orphan=true \
  renewable=true \
  token_explicit_max_ttl=0
```

A write keeps fields you leave out, so the explicit maximum must be set to `0` to clear it. Read the role again to confirm.

## Step 3: Prove it as the spawner

```sh
SPAWNER=$(bao token create -policy=worker-spawner -ttl=15m -field=token)
WORKER=$(BAO_TOKEN=$SPAWNER bao token create -role=worker -policy=worker-read -field=token)
BAO_TOKEN=$WORKER bao token lookup
BAO_TOKEN=$WORKER bao kv get secret/worker/queue
BAO_TOKEN=$SPAWNER bao token create -role=worker -policy=worker-write
BAO_TOKEN=$SPAWNER bao token create -policy=worker-read
```

The lookup shows `period` as `1h`, `orphan` as true and `explicit_max_ttl` as `0s`. The read works. The last two commands are refused.

## Step 4: Submit

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Use `disallowed_policies=admin-ops` instead of `allowed_policies` | Every other policy, including `worker-write`, is still allowed |
| Set `token_ttl=1h` instead of `token_period=1h` | The tokens are not periodic, and renewal stops at the maximum |
| Leave `token_explicit_max_ttl` at 30 minutes | The token still ends after 30 minutes, even when renewed |
| Give the spawner `auth/token/create` | The open path ignores the role |

## Practice on your own

- Add `token_bound_cidrs` to a copy of the role under another name and see the token refused.
- Create a batch token from the role by setting `token_type=batch` and compare it with the periodic one.
