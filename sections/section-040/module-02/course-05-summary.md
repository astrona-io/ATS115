# Summary

An audit device hashes tokens, request data and response data by default. `hmac_accessor` controls whether token accessors are hashed too, and the safe default is true. `log_raw` turns hashing off and writes every secret in clear text, so it belongs only in a short debugging session on a test system. Options of a running device cannot be changed: disable the device and enable a new one. A raw file keeps every secret it recorded after the device is gone, so it must be reviewed, the secrets rotated, and the file deleted. Each device has its own salt, so hashes from different devices or from before a re-creation do not match.

The options `elide_list_responses`, `prefix` and `mode` shape the log. Eliding replaces key lists with a count and keeps lines short. A prefix makes lines invalid JSON and requires parser changes. The mode `0600` keeps the file readable only by its owner. Clear device paths and descriptions tell the next operator what each device is for.

A socket device ships records to another process. TCP is the choice for records that must not be lost, UDP loses records silently, and a Unix socket suits a collector on the same machine. `write_timeout` bounds how long a hung receiver can hold up requests. When one device fails and another succeeds, the request succeeds, and records the failed device could not send are not retried. When every device fails, requests are refused.

Operation keeps the log complete: rotate with a signal to the server so it reopens the file, measure growth to size a separate audit volume, ship records to a collector that administrators cannot edit, protect device configuration by declaring devices in the server configuration, alert on requests to `sys/audit`, and run a failure drill.

- Keep `log_raw` off and `hmac_accessor` on.
- Replace a device to change its options, then clean up the old file.
- Use more than one device, with a file as the complete copy.
- Alert on changes to `sys/audit`.

<!-- astrona:playground:destroy -->
