# Summary

An audit device writes every request and response to a destination, as one JSON line of type `request` and one of type `response` with the same request ID. Most strings are hashed with HMAC-SHA256 and a salt that belongs to the device, so no secret value appears in clear text, while numbers and true or false values are written as they are. A known value can still be found by hashing it with `sys/audit-hash/<device path>` and searching the log for the result. A few paths, among them initialization, seal, unseal and health checks, are never audited.

OpenBao has four device types: `file`, `socket`, `syslog` and `http`. The `syslog` device only writes to a local syslog daemon. A `file` device on a dedicated volume keeps records across pod restarts, and a TCP `socket` device ships them to another system; OpenBao sends a test record when a socket device is enabled. Each device has its own salt, so the same value has a different hash in each log.

Since OpenBao 2.3.2, `bao audit enable` only works when the server configuration sets `unsafe_allow_api_audit_creation = true`. The safer model is an `audit` stanza in the server configuration: the device is enabled at every start and on `SIGHUP`, cannot be changed through the API, and disappears when the stanza is removed. With the `openbao` Helm chart, the configuration lives in the ConfigMap `openbao-config`, the StatefulSet uses `OnDelete`, and a configuration change needs a pod restart and an unseal.

OpenBao refuses to answer requests that no device can record. One successful device is enough when the others fail with an error, but a device that blocks in the middle of a write makes every request wait. That is why production setups use at least two devices, including one on local storage.

- Hash a value per device with `sys/audit-hash/<path>` to find it.
- Declare devices in the server configuration, then turn API creation off.
- After a configuration change with the Helm chart: delete the pod, then unseal.
- Use more than one device; a blocked TCP socket blocks every request.

<!-- astrona:playground:destroy -->
