# Enabling File And Socket Audit Devices

One audit device is a single point of failure: if it stops, either OpenBao stops answering or the record is lost. Production setups use at least two devices, usually a local file and a network destination that ships records to a central log system. This part enables both kinds, explains the setting OpenBao 2.7 requires for it, and proves that one request reached both.

## Why bao audit enable needs a setting

An audit device writes to a file path or connects to a network address chosen by whoever enables it. Through the API, an operator with the right policy could make OpenBao write files anywhere on the server or open connections anywhere. Since OpenBao 2.3.2, creating audit devices through the API is therefore off unless the server configuration contains:

```hcl
unsafe_allow_api_audit_creation = true
```

Your playground sets this, so `bao audit enable` works. The documentation recommends turning it on only while you create devices, or declaring devices in the server configuration instead.

## A file device on the audit volume

The Helm chart can add a second volume for audit logs with `server.auditStorage`. In your playground it is mounted at `/openbao/audit` in `openbao-0`, so a log file there survives a pod restart, unlike a file in `/tmp`.

<!-- astrona:playground:renew -->

Enable a `file` device at the default path `file/`, writing to the audit volume:

```sh
bao audit enable file file_path=/openbao/audit/audit.log
```

OpenBao creates the file with the mode `0600` by default. Check it from inside the pod:

```sh
kubectl -n openbao exec openbao-0 -- ls -l /openbao/audit/
```

The listing shows `audit.log`, owned by the OpenBao user.

## A socket device to a TCP listener

The `audit-sink` Service in the namespace `clients` listens on TCP port `9090` and prints what it receives. When you enable a socket device, OpenBao first sends a test record, and if the destination does not answer, the device is not enabled. Enable it at the default path `socket/`:

```sh
bao audit enable socket address=audit-sink.clients.svc.cluster.local:9090 socket_type=tcp
bao audit list -detailed
```

The list shows `file/` with its `file_path` and `socket/` with its `address` and `socket_type`. A TCP socket device can make OpenBao wait when the listener accepts the connection but never reads; the `write_timeout` option, two seconds by default, limits how long each write may take.

## Finding one request in both logs

Each device has its own salt, so the same value has a different hash in each log. To find a request, hash the value once per device. Write a secret with a value you will recognise:

```sh
bao kv put secret/inventory/probe marker=audit-test-42
bao write -field=hash sys/audit-hash/file input=audit-test-42
bao write -field=hash sys/audit-hash/socket input=audit-test-42
```

The two hashes are different. Look for each in its own destination; the values below are placeholders for the two hashes:

```sh
kubectl -n openbao exec openbao-0 -- grep -c '<FILE_HASH>' /openbao/audit/audit.log
kubectl -n clients logs deploy/audit-sink | grep -c '<SOCKET_HASH>'
```

Each count is at least one: the request entry with the `marker` value was written to both devices. The value never appears in clear text in either log.

You now have two independent audit devices, and you can prove that a given request reached both without ever writing the secret in clear text. What is still open is how to keep devices from being created or removed through the API at all, and what OpenBao does when its devices stop working.

## Common pitfalls

> [!WARNING]
> - **Writing the audit log to the container's own file system.** It is lost when the pod restarts. Use a volume such as the chart's `server.auditStorage`.
> - **Enabling a socket device before its listener is up.** OpenBao's test record fails and the device is not enabled.
> - **Comparing hashes between devices.** Each device has its own salt; hash the value for each device separately.
> - **Leaving `unsafe_allow_api_audit_creation` on.** Anyone with `sudo` on `sys/audit` can then make OpenBao write files or open connections anywhere.

## Your mission: Send Every Request To Two Audit Devices

You can now enable a file and a socket audit device and find one request in both. The mission gives you an OpenBao server with no audit devices and asks you to enable a file device on the audit volume and a socket device to `audit-sink`, so every request is recorded twice.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-115-playground-040-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS115.git -c sections/section-040/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-115-lab-040-01
astrona start ats-115-playground-040-01
```
