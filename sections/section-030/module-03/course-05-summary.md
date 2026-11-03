# Summary

A lease is a record that OpenBao keeps for every secret it hands out. Its ID starts with the path that created it, which lets you act on all leases of one path with a prefix. A lease lookup shows when a lease expires, whether it is renewable and how much time is left. The lifetime is the shortest applicable limit, and a request for more time is shortened without an error. Expiry is processed in the background and is not an emergency control.

Revocation has scopes. `bao lease revoke` ends one lease, and `-sync` waits for the result. `-prefix` ends every lease under a path, regardless of who holds it. `-force` removes a lease record without the engine, works only with `-prefix`, and is for recovery. `bao token revoke -accessor` ends a token with its children and their leases, without exposing the token value. `-mode=orphan` keeps the children and `-mode=path` revokes by a path prefix. Disabling an auth method or a secrets engine ends everything it issued and removes its configuration.

An incident response runs in order. Contain by stopping new use, for example by destroying the secret ID by its accessor. Scope by looking up the token and the leases. Revoke at the lowest scope that covers the leak. Rotate the credential and change the data it could read. Verify with the leaked value, and confirm that unrelated applications are untouched. Sealing the server blocks all access and revokes nothing, so it is a last resort for a compromised server.

Preparation makes the response small: short lifetimes with automation, one role and one policy per application, wrapped delivery of secret IDs, audit devices enabled in advance, an inventory of accessors, and drills.

- Revoke at the lowest scope that covers the leak.
- Contain first, then revoke, then rotate, then verify.
- Use accessors, not token values.
- Prove the result with the leaked value and with an unrelated application.

<!-- astrona:playground:destroy -->
