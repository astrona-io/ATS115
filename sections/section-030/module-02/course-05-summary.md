# Summary

OpenBao has several token types. Service tokens are stored records with every feature: renewal, children, an accessor and a cubbyhole. Batch tokens are encrypted blobs that cost no storage, but they cannot be renewed, have no accessor and cannot be revoked one by one. Root tokens have no limits and should exist only for the time of a task. Orphan tokens have no parent and survive its revocation. Periodic tokens renew to a fixed period and have no ordinary maximum TTL.

The lifetime of a token is the shortest of the system maximum, the mount maximum, the role or auth method setting and the request. A request for more is shortened without an error, so the response must be read. Renewal sets a new TTL counted from now, and it never passes the maximum or an explicit maximum TTL. Tuning the token mount changes new tokens and renewals, not existing tokens.

A token role fixes the policies a caller may request, the lifetime, the type, the period, the orphan setting and the allowed networks. Giving an application only the rule `auth/token/create/<role>` makes the role the only way it can create tokens. A write to a role keeps fields that are left out, so the role must be read back after a change.

A use limit revokes a token after a number of requests, and every request counts. An accessor identifies a token without being usable as one, and it can look up, renew and revoke the token. Revocation has modes that decide what happens to children. Network binding refuses requests from outside the allowed ranges.

- Pick the type from the task: service, batch, periodic or orphan.
- The shortest limit wins, silently.
- Give applications a role path, not the open create path.
- Log accessors, never tokens.

<!-- astrona:playground:destroy -->
