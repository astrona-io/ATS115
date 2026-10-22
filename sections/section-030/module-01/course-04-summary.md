# Summary

Response wrapping protects a secret on its way to the consumer. A client asks for it with `-wrap-ttl` or the `X-Vault-Wrap-TTL` header, and OpenBao stores the response in the cubbyhole of a new single-use token and returns that token instead. Whoever carries the wrapping token cannot read the secret without using the token up, so an interception is noticed when the real receiver tries to unwrap.

The receiver checks before it unwraps. It looks the token up on `sys/wrapping/lookup`, which needs no other token, and compares the exact creation path with what it expects. A token that does not arrive, a failed lookup, an unexpected creation path or a failed unwrap are all reasons to raise an alert and read the audit log, not to generate a new secret. The usual handover is an AppRole secret ID: the pipeline gets it wrapped, and only the application unwraps it and logs in with its role ID.

Leases control how long a secret lives. Dynamic secrets, such as PKI certificates from a role with `generate_lease=true`, and tokens each have a lease that OpenBao can look up, renew when it is renewable, and revoke. `bao lease revoke` ends one lease, and for a certificate also puts it on the certificate revocation list. `-prefix` revokes every lease under a path and is rarely what an incident needs.

Tokens form a tree. A token created by another token is its child, and revoking a token revokes all its children and every lease any of them created. An orphan token has no parent and is not part of anybody's tree. A token can be revoked by its accessor, and a policy can force wrapped responses on a path with `min_wrapping_ttl` and limit their lifetime with `max_wrapping_ttl`.

- Wrap with a short TTL; only the final consumer unwraps.
- A failed lookup or an unexpected creation path is an incident.
- Revoke one lease ID, not a prefix, unless you mean the whole path.
- Revoking a token takes its children and their leases; orphans stay.

<!-- astrona:playground:destroy -->
