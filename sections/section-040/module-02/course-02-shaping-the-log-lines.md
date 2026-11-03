# Shaping The Log Lines

Besides hashing, three options of a file device decide what a line looks like and who can read the file. They are small settings with large effects on size, tooling and safety.

## elide_list_responses

A list request, such as `bao kv list secret/`, returns every key under a path. On a mount with thousands of keys, each list request would write thousands of names into the log twice, once for the request and once in the response. The option `elide_list_responses=true` replaces the list in the response entry with a count of its entries, so the size of a log line no longer depends on the size of the list.

<!-- astrona:playground:renew -->

```sh
bao audit enable -path=compact file file_path=/openbao/audit/compact.log elide_list_responses=true
bao kv list secret/
kubectl -n openbao exec openbao-0 -- tail -n 2 /openbao/audit/compact.log
```

The last two lines are the request and the response for the list. The response no longer carries the key names. You lose the ability to see in the log which keys a list returned. You keep the fact that the list happened, who asked, and how many entries it had. For most investigations that is enough, because the read of an individual key is logged by its own request.

## prefix

The option `prefix` is a string that the device writes before each line. It exists so that a log collector can tell the lines of this device from other lines in a shared stream.

```sh
bao audit enable -path=tagged file file_path=/openbao/audit/tagged.log prefix='@cee: '
```

A prefixed line no longer starts with an opening brace, so it is not valid JSON on its own. Any tool that parses each line as JSON must remove the prefix first. If you use a prefix, test your parsing and your alerts against a real line before relying on them.

## mode

The option `mode` is the file permission, written as an octal number. The default is `0600`, which lets only the owner of the file read and write it. The audit file holds hashed values, but it also holds the paths, accessors and identities of every request. Keep it as restrictive as the default unless a log shipper that runs as another user needs to read it, and then give that user access with the narrowest group rule you can.

```sh
bao audit enable -path=restricted file file_path=/openbao/audit/restricted.log mode=0600
kubectl -n openbao exec openbao-0 -- ls -l /openbao/audit/
```

The listing shows the permission string of each file. A line that begins with `-rw-------` is a file readable only by its owner.

## description and the device path

Give each device a path that says what it is, and a description that says why it exists. A path such as `file/` is fine for one device, but with several devices, `audit-primary/` and `audit-shipping/` tell the next person on duty what to leave alone.

```sh
bao audit enable -path=audit-primary -description="Primary audit file for compliance" file file_path=/openbao/audit/primary.log
bao audit list -detailed
```

The description appears in the list. Disabling a device is the one action that can blind an investigation, so make the purpose obvious.

## Combining the options

A production file device usually combines all of these:

```sh
bao audit enable -path=audit-primary -description="Primary audit file" file \
  file_path=/openbao/audit/primary.log \
  mode=0600 \
  elide_list_responses=true
```

The options `log_raw` and `hmac_accessor` are not set, so they keep their safe defaults: values are hashed, and accessors are hashed. Read the result with `bao audit list -detailed` and compare it with the intent.

## Common pitfalls

> [!WARNING]
> - **Using `elide_list_responses` and then expecting key names in the log.** The names are replaced with a count.
> - **Setting a `prefix` and not changing the parser.** Lines that are not valid JSON are dropped or misread.
> - **Making the audit file world-readable.** It holds the identity and path of every request.
> - **Reusing one device path name for different purposes.** Use clear paths and descriptions.
