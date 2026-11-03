# Solution: Replace A Raw Debug Device

Work the task yourself first. Running `astrona submit -c sections/section-040/module-02/labs/lab-01` after a step tells you which checks pass.

The grader reads the options of the devices, looks for the old file, writes a new value and searches the new log for it.

## Step 1: Read the current devices

```sh
bao audit list -detailed
```

Note that `debug/` has `log_raw` set to `true`.

## Step 2: Enable the production device first

```sh
bao audit enable -path=file -description="Production audit file" file \
  file_path=/openbao/audit/audit.log \
  mode=0600 \
  elide_list_responses=true
bao audit list -detailed
```

The options `log_raw` and `hmac_accessor` stay at their defaults, so values and accessors are hashed.

## Step 3: Disable the raw device

```sh
bao audit disable debug
```

Enabling the new device first means no request is unrecorded between the two commands.

## Step 4: Remove the raw file

The file holds the secrets it recorded in clear text. Review it, then delete it from the pod:

```sh
kubectl -n openbao exec openbao-0 -- grep -c raw-debug-leftover-7731 /openbao/audit/debug.log
kubectl -n openbao exec openbao-0 -- rm /openbao/audit/debug.log
kubectl -n openbao exec openbao-0 -- ls -l /openbao/audit/
```

In a real incident, rotate every secret that the file contains, such as `secret/billing/api`.

## Step 5: Prove the new log hashes values

```sh
bao kv put secret/billing/probe marker=prod-hidden-889
bao write -field=hash sys/audit-hash/file input=prod-hidden-889
kubectl -n openbao exec openbao-0 -- grep -c prod-hidden-889 /openbao/audit/audit.log
```

The last count is `0`. Search for the hash from the second command in the same file, and the count is greater than zero.

## Step 6: Submit

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Disable `debug/` and keep the file | The secrets stay on the volume in clear text |
| Disable `debug/` before enabling the new device | Requests in between are not recorded |
| Enable the new device with `log_raw=true` to make searching easier | Every secret is in the new log too |
| Keep `hmac_accessor=false` | Anyone with the log gets usable token accessors |

## Practice on your own

- Add a socket device to `audit-sink` and find the same hash in its log.
- Compare the response line of `bao kv list secret/` with and without `elide_list_responses`.
