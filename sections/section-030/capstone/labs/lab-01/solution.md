# Solution: Contain A Leaked Token Tree

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass.

The grader looks up the three tokens by accessor, checks the three certificate leases, and requests secret IDs with a fresh `secret-id-issuer` token, unwrapped and with two wrapping TTLs.

## Step 1: Look at the leaked token and its tree

Start the port-forward and log in as shown in the task. Read the accessors and look the leaked token up:

```sh
LEAKED=$(kubectl -n clients get configmap incident -o jsonpath='{.data.leaked-accessor}')
RELEASE_BOT=$(kubectl -n clients get configmap incident -o jsonpath='{.data.release-bot-accessor}')
bao token lookup -accessor "$LEAKED"
bao token lookup -accessor "$RELEASE_BOT"
```

The leaked token's `display_name` is `token-ci-parent` and it has the policies `ci-orchestrator` and `pki-issuer`. The `release-bot` token has `orphan` set to `true`: it has no parent, so it is not part of `ci-parent`'s tree. List the certificate leases too:

```sh
bao list sys/leases/lookup/pki/issue/web
```

There are three leases: two from `build-1` and one from `release-bot`.

## Step 2: Revoke the tree

Revoking a token in the default mode revokes it, all its children, and every lease any of them created. Revoke by accessor:

```sh
bao token revoke -accessor "$LEAKED"
```

Check the result:

```sh
bao token lookup -accessor "$LEAKED"
bao token lookup -accessor "$RELEASE_BOT"
bao list sys/leases/lookup/pki/issue/web
```

The first lookup fails, the `release-bot` lookup still works, and the list shows one lease: the one `release-bot` created. `build-1` was revoked with its parent; you never needed its accessor.

## Step 3: Force wrapping in secret-id-issuer

Save this as `secret-id-issuer.hcl`:

```hcl
path "auth/approle/role/inventory/secret-id" {
  capabilities     = ["update"]
  min_wrapping_ttl = "1s"
  max_wrapping_ttl = "5m"
}
```

Load it and test it with a fresh token:

```sh
bao policy write secret-id-issuer secret-id-issuer.hcl
PIPELINE=$(bao token create -policy=secret-id-issuer -ttl=15m -field=token)
BAO_TOKEN=$PIPELINE bao write -f auth/approle/role/inventory/secret-id
BAO_TOKEN=$PIPELINE bao write -f -wrap-ttl=30m auth/approle/role/inventory/secret-id
BAO_TOKEN=$PIPELINE bao write -f -wrap-ttl=2m auth/approle/role/inventory/secret-id
```

The first two requests are refused: one asks for no wrapping, the other for more than five minutes. The third returns a wrapping token.

## Step 4: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `bao token revoke -mode=orphan` on the leaked token | `build-1` becomes an orphan and keeps working, with its certificates |
| `bao lease revoke -prefix pki/issue/web` | `release-bot`'s certificate is revoked too |
| Revoke the `release-bot` token "to be safe" | The release pipeline stops, and it was never part of the leak |
| Remove `update` from `secret-id-issuer` | The pipeline cannot get secret IDs at all |
