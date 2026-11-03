# Token Types

All tokens look the same to a client: a string sent in a header. Behind the string, OpenBao stores very different things depending on the type. The type decides what a token costs the server, what it can do, and what happens to it when other tokens are revoked. This part compares the types you will meet and shows how to tell them apart.

## Service tokens

A **service token** is the default type. OpenBao stores it on disk with its policies, its lifetime, its parent and its accessor. Service tokens support every feature: renewal, revocation, child tokens, a private cubbyhole (a key-value store that only this token can read), and leases for the secrets they request. The cost is that each token is a stored record, so a server that creates a very large number of them spends storage and time on it.

Create one and look at its fields:

<!-- astrona:playground:renew -->

```sh
bao token create -policy=worker-read -ttl=30m -format=json
```

The `auth` section of the output shows the `client_token`, the `accessor`, the `policies`, the `lease_duration` and `renewable: true`. The lookup of the token shows `type` as `service`.

## Batch tokens

A **batch token** is an encrypted blob that carries its own information. OpenBao stores nothing for it, so creating one is cheap and a server can create very many. The price is that batch tokens lack features. They cannot be renewed, cannot create child tokens, have no accessor and no cubbyhole, cannot be periodic and cannot have an explicit maximum TTL. They also cannot be revoked one by one: they stop working when their TTL ends, or when their parent token is revoked.

```sh
bao token create -type=batch -policy=worker-read -ttl=10m -format=json
```

The output has a `client_token`, no `accessor`, and `renewable` is false. Try to renew it with `bao token renew` and read the error. Use batch tokens for short, high-volume work such as many small jobs that each read one secret.

## Root tokens

A **root token** has the `root` policy and is the only token type that can have no expiry. Because it can do everything, treat it as an emergency tool. The initial root token comes from `bao operator init`; later root tokens come from `bao operator generate-root`, which needs the approval of key holders. Revoke a root token as soon as the task that needed it is done.

## Orphan tokens

Normally a new token is a child of the token that created it. When the parent is revoked or expires, all its children go with it. An **orphan token** has no parent, so nothing above it can revoke it by revoking a parent. Orphan tokens are right for long-lived processes that must outlive the person or job that started them. A token made by an auth method login, such as AppRole, is an orphan by design.

```sh
bao token create -orphan -policy=worker-read -ttl=30m -format=json
```

Check the difference. Create a parent token with a policy that may create tokens, make a child and an orphan from it, revoke the parent, and look at both. The child is gone, and the orphan still works.

## Periodic tokens

A **periodic token** has no maximum TTL. Instead it has a **period**: each time the holder renews the token, its TTL resets to the period. As long as the holder renews within each period, the token never expires. If the holder stops renewing, the token expires after at most one period. This suits a long-running service: the token cannot outlive the service by more than one period. Creating one needs a root token or `sudo` on the create path, or a token role with a period.

```sh
bao token create -period=1h -policy=worker-read -format=json
```

The lookup of this token shows `period` as `1h`, `ttl` near `1h`, and no `explicit_max_ttl`. Renew it and see the TTL return to the period.

You can now pick a token type for a task: service for full features, batch for cheap volume, periodic for services that renew, orphan for tokens that must not die with a parent, and root only for emergencies. The next question is what decides how long any one of them lasts.

## Common pitfalls

> [!WARNING]
> - **Using batch tokens where renewal is needed.** They cannot be renewed. The application fails when the TTL ends.
> - **Expecting a revoked parent to leave children alone.** Children are revoked with it unless they were created as orphans.
> - **Keeping a root token.** Revoke it after the task. Generate a new one when you need it.
> - **Using periodic tokens without monitoring renewals.** A silent renewal failure takes the service down at the end of the period.
