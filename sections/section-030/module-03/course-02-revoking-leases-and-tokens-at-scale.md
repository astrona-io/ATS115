# Revoking Leases And Tokens At Scale

During an incident you rarely revoke one lease. You revoke everything one identity created, everything under one path, or everything one auth method issued. OpenBao has a command for each scope. This part compares them, so you choose the one that closes the leak and nothing else.

## One lease

```sh
bao lease revoke "$LEASE_ID"
```

This revokes one lease and asks the engine to remove the secret. For a certificate with a lease, it revokes the certificate. The command returns when the request is accepted. The work can continue in the background, so use `-sync` when the next step depends on it:

<!-- astrona:playground:renew -->

```sh
bao lease revoke -sync "$LEASE_ID"
```

With `-sync`, the command waits for the revocation to finish and reports the result.

## All leases under a prefix

```sh
bao lease revoke -prefix pki/issue/web
```

This revokes every lease whose ID starts with the prefix. It is the right tool when a whole path is suspect, for example every certificate issued from one role. It is also the command that causes the most collateral damage, because it ignores who holds each lease. In the playground, the prefix above revokes the certificates of `inventory` along with those of `billing`. Check the scope with `bao list sys/leases/lookup/pki/issue/web/` before you run it.

## Forcing a revocation

If the engine cannot complete a revocation, for example because the target database is gone, OpenBao keeps retrying. The flag `-force` removes the lease record without waiting for the engine, and it works only together with `-prefix`:

```sh
bao lease revoke -force -prefix pki/issue/web
```

The flag exists for recovery. The secrets that were not revoked by the engine can still be valid at their source, so use it only when you know the target is gone or you will clean it by other means. It is not a faster way to revoke.

To remove records of leases that no longer exist, tidy the lease store:

```sh
bao write -f sys/leases/tidy
```

Tidy cleans up broken records. It does not revoke valid leases.

## One token and everything it made

Revoking a token also revokes its child tokens and the leases created with it. This turns the question "which leases did the leaked token create" into one command:

```sh
bao token revoke -accessor "$ACCESSOR"
```

The accessor is enough, so the token value never has to be read, copied or typed again. Leases of the token and of its children are revoked as part of the same action. The modes change the scope. Without a mode, the whole tree goes. With `-mode=orphan`, only this token goes, and its children continue as orphans. With `-mode=path`, the argument is a path prefix, and every token created under it is revoked, for example everything created by one login path.

```sh
bao token revoke -mode=path auth/approle/login
```

That command ends every token that any AppRole login created, so use it only when the whole method is suspect.

## Disabling a mount

Two commands reach further than any prefix:

- `bao secrets disable pki/` revokes all leases of the engine and removes the mount with its data. This destroys the certificate authority too.
- `bao auth disable approle/` revokes all tokens that the method issued and removes its roles and secret IDs.

Both end the incident and also break every application that used the mount. They are the right answer when the mount itself is compromised, and the wrong answer when one application is.

## Comparing the scopes

| Command | What it ends | Collateral |
| --- | --- | --- |
| `bao lease revoke ID` | One lease | None |
| `bao token revoke -accessor A` | One token, its children and their leases | None outside the tree |
| `bao lease revoke -prefix P` | Every lease under a path | Every holder of a lease there |
| `bao token revoke -mode=path P` | Every token created under a path | Every client of that login path |
| `bao auth disable M` | Every token of a method, and its configuration | Every client of the method |
| `bao secrets disable M` | Every lease of an engine, and its data | Every client of the engine |

Pick the lowest row that covers the leak.

## Verifying a revocation

After a revocation, look the lease or the token up again. A revoked lease is reported as invalid, and a revoked token as not found:

```sh
bao lease lookup "$LEASE_ID"
bao token lookup -accessor "$ACCESSOR"
```

Both commands fail. If a lookup still succeeds, the revocation is not finished or the wrong object was revoked. Wait a moment, then check the scope again.

## Common pitfalls

> [!WARNING]
> - **Revoking by prefix without listing it first.** You also end the leases of applications that were not part of the leak.
> - **Using `-force` to speed things up.** It leaves the secret valid at its source if the engine did not revoke it.
> - **Disabling a mount to contain a small leak.** It removes the data and breaks every client.
> - **Revoking the parent when the children must live.** Use `-mode=orphan` first, or create such children as orphans.
