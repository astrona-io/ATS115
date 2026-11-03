# An Incident Response Runbook

Commands are not a response. A response is an order of actions that someone can follow while under pressure. This part gives that order for a leaked OpenBao credential, with the commands for each step. The steps are contain, scope, revoke, rotate and verify.

## Step 1: Contain

Decide what you know about the credential. A person reports "the AppRole secret ID of the billing application was in a build log". Write down what leaked: the type (token, secret ID, certificate key), the identity it belongs to, and the time it was first exposed. Then stop new use before you clean up old use.

For an AppRole secret ID, stop new logins by destroying the secret ID. The accessor identifies it without exposing its value:

<!-- astrona:playground:renew -->

```sh
bao write auth/approle/role/billing/secret-id-accessor/destroy secret_id_accessor="$SECRET_ID_ACCESSOR"
```

A destroyed secret ID cannot log in again. The role itself stays, so the application can receive a new secret ID later. Tokens that already exist stay valid; the next steps deal with them.

## Step 2: Scope

Find what the credential touched. For a token, look up the token by its accessor and read its policies, its parent and its time to live:

```sh
bao token lookup -accessor "$TOKEN_ACCESSOR"
bao token capabilities -accessor "$TOKEN_ACCESSOR" pki/issue/web
```

The first command shows who the token is and what it may do. The second answers whether it can issue certificates. To find the leases it created, list the prefixes the policy allows and check them:

```sh
bao list sys/leases/lookup/pki/issue/web/
```

Compare every ID with the issue time of the token. Do not guess which leases belong to the leaker. The audit log records every request with the token accessor, hashed by default, and a later section shows how to match a value against it. For now, remember that the log is the evidence for the scope, and the lists in OpenBao are the places to act.

## Step 3: Revoke

Pick the lowest scope that covers the leak, from the comparison table of scopes. In the case above, one command closes everything the token created:

```sh
bao token revoke -accessor "$TOKEN_ACCESSOR"
```

The token, its child tokens and the certificates they issued are revoked together. If the leak is a certificate private key and not a token, revoke the lease of that certificate instead:

```sh
bao lease revoke -sync "$LEASE_ID"
```

Do not run `bao lease revoke -prefix` on the path to be safe. It ends the leases of applications that did nothing wrong.

## Step 4: Rotate

Revoking removes the leaked value. Rotation removes the reason it leaked. Depending on the type:

- **Secret ID:** create a new one with `bao write -f auth/approle/role/billing/secret-id`, deliver it in a wrapped response, and find how the old one reached the log.
- **Userpass password or other static credential:** write a new value with `bao write auth/userpass/users/<name> password=...`.
- **Certificate:** issue a new one with a new key and deploy it, after the old one is revoked.
- **Encryption material:** `bao operator rotate` adds a new term to the encryption key of the storage. It does not revoke tokens or leases, so it is not a response to a token leak.

If many secrets could have been read, treat the data as exposed, not only the credential. The values behind the policy of the token are the values to change at their source, such as database passwords in the KV engine.

## Step 5: Verify

Prove that the leak is closed, using the leaked value and not your own token. Try the secret ID to log in, and check that the revoked token and leases are gone:

```sh
bao lease lookup "$LEASE_ID"
bao token lookup -accessor "$TOKEN_ACCESSOR"
```

Then check that nothing else changed. Look up one token and one lease of an unrelated application, and read the list of mounts and auth methods:

```sh
bao secrets list
bao auth list
```

All mounts that existed before must still exist, and the unrelated lease must still be valid. A response that breaks the other applications is a second incident.

## The last resort: sealing

`bao operator seal` seals the server. The server drops its decryption key from memory and answers every request with a sealed error. Tokens and leases are not revoked; they remain in storage and work again after an unseal. Sealing stops all access, including your own, until key holders unseal with the required number of key shares. Use it only when the server itself is compromised and you must stop all reads at once. It does not end any lease, and it does not help against a leaked token for a server that you can still protect by revoking.

## Record what you did

Write down the times and commands of each step, the objects revoked, and the objects checked afterwards. The record supports the review and the report. It also tells the next person on duty what has already been done.

## Common pitfalls

> [!WARNING]
> - **Revoking before containing.** If the secret ID still works, the attacker logs in again right after your revocation.
> - **Rotating the credential and forgetting the data it could read.** The values behind the policy may need to change.
> - **Verifying with your own token.** It proves nothing about the leaked value.
> - **Sealing to stop a single leaked token.** Sealing blocks everyone and revokes nothing.
