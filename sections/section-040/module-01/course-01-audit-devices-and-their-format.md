# Audit Devices And The Audit Log Format

An audit log is only useful if you know what it contains before you need it. This part explains what OpenBao writes for each request, why you will not find any secret values in it, which few requests it does not record, and which kinds of audit devices exist. You enable your first device at the end.

## What one request produces

Every interaction with OpenBao is an API request with a response. For each one, an audit device writes two JSON objects, one per line: an entry with `"type": "request"` and an entry with `"type": "response"`. Both carry the same request ID, so you can match them. The entries hold the full request and response: the path, the operation, the client's token accessor, the entity and policies, the request data, and the response data.

Writing full responses would put every secret in the log. OpenBao prevents that by **hashing** most strings before it writes them. It uses HMAC-SHA256, a keyed hash, with a salt that belongs to that one audit device. A value such as a password appears as `hmac-sha256:` followed by the hash. Only strings are hashed: numbers and true or false values are written as they are, so sensitive numbers should be sent to OpenBao as strings.

The salt makes the hash useless to an attacker who only has the log, but you can still search it. If you know a value, you ask OpenBao to hash it with the same device's salt on `sys/audit-hash/<device path>`, and then look for that hash in the log.

## What is not recorded

A few paths never reach the audit devices, because OpenBao must answer them before or without the normal request handling:

| Path | Why it matters |
| --- | --- |
| `sys/init`, `sys/seal-status`, `sys/seal`, `sys/unseal` | Initialization and seal operations |
| `sys/leader`, `sys/health` | Health and leader checks |
| `sys/storage/raft/bootstrap`, `sys/storage/raft/join` | Integrated Storage cluster setup |
| `sys/metrics`, `sys/pprof/*`, `sys/in-flight-req` | Only when the listener allows them without a token |

Sealing and unsealing therefore leave no trace in the audit log. Watch them with the server's own log and with monitoring instead.

## The device types

OpenBao has four audit device types:

| Type | Where it writes | Notes |
| --- | --- | --- |
| `file` | A file, or `stdout` | Appends; send `SIGHUP` to reopen the file after log rotation |
| `socket` | A TCP, UDP or Unix socket | TCP can block OpenBao if the other end hangs; UDP can lose records without notice |
| `syslog` | The local syslog daemon | No remote destination; the OpenBao container in this course has no syslog daemon |
| `http` | An HTTP endpoint | Sends each record to a web service |

Because the `syslog` device always writes to a syslog daemon on the same machine, this course teaches it in prose and uses `file` and `socket` in the labs. On a virtual machine with a syslog daemon, `bao audit enable syslog tag="openbao" facility="AUTH"` enables it.

The documentation recommends more than one device. OpenBao considers a request successful when **at least one** device records it, so a second device keeps OpenBao working when the first one fails, and the two logs together are a check against tampering.

## A first device: file to standard output

<!-- astrona:playground:renew -->

The quickest device writes to the OpenBao process's standard output, which Kubernetes keeps as the pod log. Enable it at the path `stdout`:

```sh
bao audit enable -path=stdout file file_path=stdout
bao audit list -detailed
```

The list shows the device at `stdout/` with the type `file` and the option `file_path=stdout`. Now make a request and read the pod log:

```sh
bao kv get secret/inventory/db
kubectl -n openbao logs openbao-0 --tail=4
```

The last lines of the log are JSON objects: a request entry and a response entry for `secret/data/inventory/db`, with the password replaced by an `hmac-sha256:` value. The pod log also holds OpenBao's own messages, which is why a dedicated file is the better destination.

You now know what an audit device records, how secret values are hashed, which paths are never recorded, and which device types exist. The open questions are how to send records to a durable file and to a second destination at the same time, and how to prove that a given request is in both.

## Common pitfalls

> [!WARNING]
> - **Expecting to see secret values in the log.** They are hashed with the device's salt. Use `sys/audit-hash` to search for a known value.
> - **Sending sensitive numbers as JSON numbers.** Only strings are hashed; send them as strings.
> - **Looking for unseal events in the audit log.** Seal and unseal paths are not audited.
> - **Disabling a device to "reset" it.** A device enabled again at the same path gets a new salt, and you can no longer compute hashes for the old log.
