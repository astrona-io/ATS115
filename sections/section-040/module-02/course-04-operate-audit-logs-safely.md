# Operate Audit Logs Safely

An audit log has a life: it grows, it is rotated, it is shipped, it is kept and it is deleted. Each stage can break the guarantee that the log is complete. This part covers the stages, the size you need to plan for, and a drill that shows you the failure before it happens.

## Rotation

A file device appends to the file and keeps the file open. If you rename or compress the file with a rotation tool, the server keeps writing into the old, renamed file. After rotation, send the signal `SIGHUP` to the OpenBao process, which makes the device close and reopen the file at the original path. The rotation tool must be configured to send the signal after it moves the file, for example with a post-rotation script. Do not use a rotation method that truncates the file in place unless you have tested that no records are lost between the copy and the truncate.

Check after a rotation. Write a test secret, compute its hash with `sys/audit-hash`, and search for the hash in the new file. If the hash is only in the old file, the server still writes to the old one.

## Sizing the volume

The size of an audit log depends on the number of requests and on the size of each. Every request writes two lines. Lines for large writes and responses are long, and lists without `elide_list_responses` can be very long. Measure it instead of guessing:

<!-- astrona:playground:renew -->

```sh
kubectl -n openbao exec openbao-0 -- ls -l /openbao/audit/
kubectl -n openbao exec openbao-0 -- df -h /openbao/audit
```

Take the size of the file at two moments in a normal day, calculate the growth per day, and multiply by the days that you keep logs on the volume. Add a margin for incident days, which write much more. A full volume is not a soft failure. When no device can write, OpenBao refuses requests, which makes a full audit volume an outage.

Put the audit log on its own volume, and not on the volume of OpenBao's storage. A full audit volume then does not also stop the storage.

## Shipping and retention

Rotation keeps the volume from filling. Shipping keeps the evidence if the server is lost. A common design has two devices: a file device on a local volume with short retention, and a socket device that sends records to a collector with long retention. The collector stores the records where the administrators of OpenBao cannot edit them, because an audit log that the audited person can change is weak evidence.

Decide how long you keep logs. The answer comes from the rules your organization follows and from how long an incident can go unnoticed. Keep the hash of a periodic check, such as the size and the checksum of each rotated file, in a different system.

## Protecting the devices

The most valuable target of an attacker with a powerful token is the audit configuration. Reduce that risk:

- Declare the devices in the server configuration, as the earlier module showed, so that an API call cannot remove them.
- Keep `unsafe_allow_api_audit_creation` off outside of setup.
- Give the `sudo` capability on `sys/audit` and `sys/audit/*` to as few policies as possible. Disabling or creating a device needs it.
- Alert on any request to `sys/audit`, because it is the sign of someone changing what is recorded.

## A failure drill

Test your design before an incident does. In the playground:

1. Enable a file device and a socket device.
2. Stop the receiver with `kubectl -n clients scale deploy/audit-sink --replicas=0`.
3. Make a request. It must succeed, because the file device recorded it.
4. Read the server log and confirm that the socket error is visible.
5. Start the receiver again, make another request, and confirm that it reaches both devices.
6. Write down the time between step 2 and your alert, if you have one. If you have no alert, you have found a gap.

Repeat the drill for the file device if you can: fill a test volume, or point the device at a path that cannot be written, and see what the server does. Learn what the error looks like before you must recognize it under pressure.

## Common pitfalls

> [!WARNING]
> - **Rotating a file without a signal to the server.** The server keeps writing to the renamed file.
> - **One volume for storage and audit.** A full audit log stops the storage too.
> - **A log collector that the OpenBao administrators can edit.** The evidence is not independent.
> - **No alert on `sys/audit`.** Someone can switch off the log without anyone noticing.

## Your mission: Replace A Raw Debug Device

You can now read the options of a device and judge them. The mission applies this. A test left a raw audit device on a production-like server, and it has been writing every secret in clear text for days. You replace it with a safe production device and clean up.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-115-playground-040-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS115.git -c sections/section-040/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-115-lab-040-02
astrona start ats-115-playground-040-02
```
