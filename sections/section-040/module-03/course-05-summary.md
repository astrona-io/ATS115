# Summary

An audit log is a stream of JSON lines, two per API request. Each carries a `type`, a `time`, an `auth` object with the identity, and a request object with the operation, the path and the request ID. The request ID pairs a request with its response, and a failed request has an `error`. KV version 2 paths include a `data` segment. Values and tokens are hashed, so an unknown secret cannot be read from the log. Sealing, unsealing and health checks are not recorded.

To find records, filter with `jq` by path, operation, identity, time and error. Hash a known value, token or accessor with `sys/audit-hash` on the device whose log you search, and search for the hash. Select `type=="request"` before counting, because each request writes two lines. A display name is a convenience; use the entity ID when the answer must be firm.

An investigation builds a timeline for one identity: its logins and addresses, its requests in order, the outcome of each request joined by request ID, and the tokens it created, followed by their accessor hashes. A finding states who, when, from where, what was read or written, what was refused and what changed in the system. It does not state motive. The analyzed copy is kept with a checksum and the filters are recorded.

Patterns worth an alert are repeated refusals from one identity, any use of the root token outside a planned task, any request to `sys/audit`, policy and identity changes, unusual breadth of paths, and logins from unexpected addresses. Start with the precise alerts, add baseline-based ones later, and run them on the shipped copy of the log.

- Count request entries, not lines.
- Hash with the salt of the device you search.
- State what happened, not why.
- Alert on `sys/audit`, root-token use and policy changes first.

<!-- astrona:playground:destroy -->
