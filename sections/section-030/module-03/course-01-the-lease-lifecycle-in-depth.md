# The Lease Lifecycle In Depth

A lease is the record OpenBao keeps for a secret that it hands out and later takes back. Dynamic secrets, certificates issued with a lease, and the leases of service tokens all use it. To respond well to an incident, you need to know what a lease contains, where its lifetime comes from, and what OpenBao does when it ends.

## The lease ID

Every lease has an ID. The ID starts with the path that created the lease, followed by a random part. A certificate issued from the role `web` has an ID such as `pki/issue/web/` followed by a long random string. This shape matters, because it lets you act on all leases of one path with one prefix. Issue a certificate and read the ID:

<!-- astrona:playground:renew -->

```sh
bao write -format=json pki/issue/web common_name=demo.inventory.local ttl=1h
```

The answer has a `lease_id`, a `lease_duration` in seconds and a `renewable` flag, next to the certificate data. Keep the `lease_id` in a shell variable for the next commands. A lease from a login has the login path in its ID, for example one that begins with `auth/approle/login/`.

## Looking up a lease

```sh
bao lease lookup "$LEASE_ID"
```

The lookup shows `issue_time`, `expire_time`, `last_renewal`, `renewable` and `ttl`, the seconds left. Everything you need to know about a lease is in these fields. The lookup does not show the secret itself, so it is safe to run while you investigate.

## Where the lifetime comes from

The lifetime of a lease follows the same rule as the lifetime of a token: the shortest applicable limit wins. The limits are the system default and maximum, the mount default and maximum set with `bao secrets tune -default-lease-ttl` and `-max-lease-ttl`, the setting of the role, and the TTL in the request. A request for more time than allowed gets the longest allowed time, without an error.

```sh
bao secrets tune -max-lease-ttl=2h pki/
bao write -format=json pki/issue/web common_name=cap.inventory.local ttl=24h
```

The certificate request asks for 24 hours. The answer shows a `lease_duration` of at most two hours, because the mount maximum is two hours. A certificate may carry its own validity, so also read the `expiration` of the certificate. Set the mount maximum back when you are done, for example with `bao secrets tune -max-lease-ttl=87600h pki/`.

## Renewing a lease

A renewable lease can be extended before it expires:

```sh
bao lease renew -increment=30m "$LEASE_ID"
```

The increment is a request, counted from now. The answer shows the new `lease_duration`. Like a token, a lease cannot be renewed beyond its maximum. The engine that issued the secret is asked to renew, and it may refuse or return less. A lease with `renewable` set to false cannot be renewed at all; the holder must request a new secret before the old one expires.

## What happens at expiry

OpenBao keeps lease records in an expiration manager. When a lease expires, the manager asks the engine to revoke the secret. For a database engine this means dropping the user. For a certificate with a lease, it means revoking the certificate. When the engine succeeds, the lease record is removed. When the engine fails, for example because the database is down, OpenBao retries. A lease that cannot be revoked stays in the record until it succeeds or until you remove it by force, which the next part covers.

Expiry is not instant. The manager works through leases in the background, so a secret can stay valid a short time after its `expire_time`. Do not use expiry as an emergency control. Use revocation for that.

## Listing leases

You can list the leases under a prefix, which is how you find everything a path has issued. The call needs `sudo`, which the root token has:

```sh
bao list sys/leases/lookup/pki/issue/web/
```

The answer lists the lease IDs under that path, relative to the prefix. On a busy server the list can be long, so narrow the prefix. For tokens, leases belong to the token that made the request. Revoking the token ends all leases it created, which turns a hunt for many leases into one action.

## Common pitfalls

> [!WARNING]
> - **Treating expiry as revocation.** A secret can stay valid a short while after the expire time. Revoke when you need it to stop now.
> - **Reading the requested TTL as the granted TTL.** Always read `lease_duration` in the answer.
> - **Looking up a lease and storing the secret that came with it.** Keep the lease ID, not the secret.
> - **Listing leases at the top of a busy mount.** Use the narrowest prefix that answers the question.
