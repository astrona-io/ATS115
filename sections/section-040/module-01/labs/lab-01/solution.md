# Solution: Send Every Request To Two Audit Devices

Work the task yourself first. Running `astrona submit -c sections/section-040/module-01/labs/lab-01` after a step tells you which checks pass.

The grader reads `bao audit list`, writes a secret with a new value, hashes that value with each device's salt, and looks for each hash in its own destination.

## Step 1: Check the starting point

Start the port-forward and log in as shown in the task. Then check that no device exists yet and that the audit volume is there:

```sh
bao audit list
kubectl -n openbao exec openbao-0 -- ls -ld /openbao/audit
```

`bao audit list` reports that no audit devices are enabled, and the directory exists.

## Step 2: Enable the file device

```sh
bao audit enable file file_path=/openbao/audit/audit.log
```

Without `-path`, the device is enabled at `file/`, the name of its type.

## Step 3: Enable the socket device

```sh
bao audit enable socket address=audit-sink.clients.svc.cluster.local:9090 socket_type=tcp
bao audit list -detailed
```

OpenBao sends a test record to `audit-sink` before it enables the device. The list shows both devices with their options.

## Step 4: Prove that both recorded one request

```sh
bao kv put secret/inventory/probe marker=lab-check-7
FILE_HASH=$(bao write -field=hash sys/audit-hash/file input=lab-check-7)
SOCKET_HASH=$(bao write -field=hash sys/audit-hash/socket input=lab-check-7)
kubectl -n openbao exec openbao-0 -- grep -c "$FILE_HASH" /openbao/audit/audit.log
kubectl -n clients logs deploy/audit-sink | grep -c "$SOCKET_HASH"
```

Both counts are at least one. The two hashes are different, because each device has its own salt.

## Step 5: Submit

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `file_path=stdout` | The log goes to the pod log, mixed with server messages, and is lost with the pod |
| A `udp` socket | Records can be lost without any error; the task asks for TCP |
| One hash for both logs | It only matches the device whose salt produced it |
