# Finding Records With Hashes And Filters

The log is large and most of it is noise. This part shows how to find a few records fast: by a path, by a known value, by a token accessor, and by a time window.

## Filter by path and operation

The most common question is "who touched this secret". The path is plain text in the log, so filter on it:

<!-- astrona:playground:renew -->

```sh
jq -c 'select(.type=="request" and .request.path=="secret/data/payroll/salaries")
  | {time, name: .auth.display_name, op: .request.operation}' audit.log
```

Each result is one request for that path. The `name` shows which identity made it. Use `select(.request.path | startswith("secret/data/payroll/"))` to include all secrets below a prefix.

## Filter by identity

To see everything one identity did, filter on `auth.display_name`:

```sh
jq -c 'select(.type=="request" and .auth.display_name=="userpass-bob")
  | {time, op: .request.operation, path: .request.path}' audit.log
```

The display name is a convenience, not proof. Two different mounts can produce similar names, and a token created by a role can carry a name that you chose. When the answer matters, also check the entity ID of the identity, which is stable:

```sh
bao read -field=id identity/entity/name/bob
```

Compare the result with `auth.entity_id` in the lines. If the value in your log does not match the plain ID, hash the ID with `sys/audit-hash` and search for the hash.

## Find a known value

When someone says "the password `X` was exposed, who read it", hash the value with the salt of the device and search the log for the hash:

```sh
HASH=$(bao write -field=hash sys/audit-hash/file input='the-known-value')
grep -F "$HASH" audit.log | jq -c '{time, type, path: .request.path, name: .auth.display_name}'
```

Each match is a request or response that carried the value. A write of the value appears in a request entry, and a read of it appears in a response entry. This is how you answer "was this secret ever read" without exposing it. It works only for values you already know.

## Find a token or an accessor

Tokens and accessors are hashed in the same way. Hash the value you were given and search for it:

```sh
ACC_HASH=$(bao write -field=hash sys/audit-hash/file input="$ACCESSOR")
grep -F "$ACC_HASH" audit.log | jq -c '{time, op: .request.operation, path: .request.path}'
```

The result is a list of every request that token made. Combine this with the revocation commands from the lease module: find what the token did, then revoke it by its accessor.

## Filter by time

Each entry has an ISO 8601 `time`. Strings in that format sort in time order, so you can compare them as strings:

```sh
jq -c 'select(.time >= "2026-01-01T10:00:00" and .time < "2026-01-01T11:00:00") | {time, path: .request.path}' audit.log
```

Replace the date with the window of your incident. A narrow window keeps the output short. Start from the moment of the alert, go back until the first unusual request, and note the time.

## Count and group

`jq` can count, which is how you answer "how often":

```sh
jq -s '[.[] | select(.type=="request" and .request.operation=="read" and .request.path=="secret/data/payroll/salaries")]
  | group_by(.auth.display_name) | map({name: .[0].auth.display_name, reads: length})' audit.log
```

The `-s` option reads the whole file into one array. The filter keeps request entries for one path, groups them by the display name, and counts each group. Count request entries only, so each request counts once.

## Common pitfalls

> [!WARNING]
> - **Hashing a value with the wrong device path.** Each device has its own salt. Use the device whose log you search.
> - **Counting both entries of a request.** Select `type=="request"` before you count.
> - **Using a display name as proof of a person.** Check the entity ID for a firm answer.
> - **Searching a rotated log only in the current file.** Search every file that covers the time window.
