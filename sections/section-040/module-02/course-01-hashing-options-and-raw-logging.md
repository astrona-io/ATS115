# Hashing Options And Raw Logging

By default, an audit device hashes the strings that could expose a secret: tokens, request data and response data. Two options change that behavior. One of them widens what is hashed. The other turns hashing off. Knowing both is how you read a device configuration and judge whether it is safe.

## Reading the options of a device

Every device has options that you set when you enable it. List them with the detailed form of the list command:

<!-- astrona:playground:renew -->

```sh
bao audit list -detailed
```

The output has one row per device with its type, path, description and options. In the playground, the leftover device `debug/` shows `log_raw` as `true` and `hmac_accessor` as `false`. Those are the two options to understand first. For a machine-readable answer, use `bao audit list -detailed -format=json`, where each option is a string.

## hmac_accessor

A token has a value and an **accessor**, a second identifier that cannot make requests but can look up and revoke the token. The default is `hmac_accessor=true`: the accessor in the audit log is hashed with the same salt as other values, so a person who reads the log cannot use the accessor to look up or revoke a token.

With `hmac_accessor=false`, the accessor is written as it is. This helps an investigator, who can copy the accessor from the log and run `bao token lookup -accessor`. It also means that anyone with the log, who also has the right policy, can do the same. For most installations, keep the default. You do not lose the ability to search: hash a known accessor with `sys/audit-hash`, and look for the hash.

```sh
bao write sys/audit-hash/debug input=some-accessor-value
```

## log_raw

With `log_raw=true`, the device writes security-sensitive information without hashing it: token values, secret data in requests and responses, everything. The option exists for debugging a problem on a test system. On a real system, it writes every secret that crosses the server into a file, and into every copy of the file that a backup, a log shipper or an operator makes.

Prove it on the playground. The device `debug/` is already raw. Write a secret and look for the value in its log:

```sh
bao kv put secret/billing/probe marker=raw-visible-123
kubectl -n openbao exec openbao-0 -- grep -c raw-visible-123 /openbao/audit/debug.log
```

The count is greater than zero: the value is in the file as plain text. Now do the same for a hashed device. Enable one, write another value, and look for it:

```sh
bao audit enable -path=hashed file file_path=/openbao/audit/hashed.log
bao kv put secret/billing/probe marker=hashed-hidden-456
kubectl -n openbao exec openbao-0 -- grep -c hashed-hidden-456 /openbao/audit/hashed.log
```

The count is zero. The log holds an `hmac-sha256:` value in its place. Find it with `bao write -field=hash sys/audit-hash/hashed input=hashed-hidden-456`, then count that hash in the file.

## Fixing a leftover raw device

You cannot change the options of a running device. To fix a device, disable it and enable a new one with the options you want:

```sh
bao audit disable debug
```

The raw file stays on the volume. It still holds every secret that passed through while the device was on. Treat that file as sensitive data: read what it contains, decide which secrets must be rotated, and delete the file, or move it to storage with the same protection as the secrets.

## Hashes after re-creating a device

Each device has its own salt. A hash from one device does not match a hash from another. When you disable a device and enable a new one, do not assume that the new hashes match the old ones. Hash the known value again with `sys/audit-hash` on the device you search. Keep this in mind when an investigation covers a period in which a device was replaced: search each log with the hash of its own device.

## Common pitfalls

> [!WARNING]
> - **Leaving `log_raw=true` after debugging.** Every secret is now in the log file and in each copy of it.
> - **Disabling a raw device and forgetting its file.** The file keeps all the secrets it recorded.
> - **Setting `hmac_accessor=false` for convenience.** Anyone with the log gets usable accessors.
> - **Comparing hashes across devices.** Each device hashes with its own salt.
