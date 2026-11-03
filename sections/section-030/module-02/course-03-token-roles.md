# Token Roles

Letting an application create its own tokens is convenient and risky. If the application may choose the policies and the lifetime, anyone who steals its token can mint stronger ones. A token role moves those choices from the caller to the operator: the role fixes which policies are allowed, which type the token has and how long it lives, and the caller can only pick from what the role permits.

## What a role is

A **token role** is a named set of limits for tokens created through the path `auth/token/create/<role name>`. Without a role, the caller of `auth/token/create` decides everything the caller's own rights allow. With a role, the role decides. The permission to use a role is a policy rule on `auth/token/create/<role name>`, so you can give an application the right to use exactly one role and no other.

<!-- astrona:playground:renew -->

The playground has a role named `worker` with loose settings. Read it:

```sh
bao read auth/token/roles/worker
```

The output lists the fields of the role. The ones you will use most are:

- `allowed_policies` and `disallowed_policies`: the policies a caller may or may not request. When `allowed_policies` is set, a request for any other policy fails.
- `token_period`: makes tokens from this role periodic with this period.
- `token_explicit_max_ttl`: the hard end of every token from the role.
- `token_ttl` and `token_max_ttl`: the default and the limit of the lifetime.
- `orphan`: when true, tokens from the role have no parent.
- `renewable`: whether tokens can be renewed.
- `token_type`: `service` or `batch`, or `default-service` and `default-batch` to let the caller override.
- `token_no_default_policy`: leaves out the `default` policy.
- `token_bound_cidrs`: the network ranges the tokens can be used from.

## Writing a role

Replace the `worker` role with a strict one. Workers may only get `worker-read`, their tokens are periodic with a one-hour period, and they are orphans, so a restart of the process that created them does not kill them:

```sh
bao write auth/token/roles/worker \
  allowed_policies=worker-read \
  token_period=1h \
  orphan=true \
  renewable=true \
  token_explicit_max_ttl=0
```

A write replaces fields you send and keeps the ones you leave out. Setting `token_explicit_max_ttl=0` removes the explicit maximum, because a periodic token that dies at a fixed time defeats the purpose of the period. Read the role back to confirm the values.

## Using a role

A token is created through a role with `-role`. Always name the policy you want. The role refuses any policy that is not allowed:

```sh
bao token create -role=worker -policy=worker-read -format=json
bao token create -role=worker -policy=worker-write
```

The first command succeeds and returns a token with the policies `default` and `worker-read`. The second is refused, because `worker-write` is not in `allowed_policies`. Look up the first token and check that `period` is `1h`, `orphan` is true and `explicit_max_ttl` is `0s`.

## Giving an application access to a role only

To let an application create its tokens, give it a policy that allows the one create path and nothing wider:

```sh
bao policy write worker-spawner - <<'POLICY'
path "auth/token/create/worker" {
  capabilities = ["update"]
}
POLICY
SPAWNER=$(bao token create -policy=worker-spawner -ttl=1h -field=token)
BAO_TOKEN=$SPAWNER bao token create -role=worker -policy=worker-read
BAO_TOKEN=$SPAWNER bao token create -policy=worker-read
```

The first command works. The second is refused with `permission denied`, because the spawner may use the role `worker` but not the open path `auth/token/create`. The role is the only door.

## Allowed and disallowed together

`allowed_policies` is a strict list: only these. `disallowed_policies` is the opposite: anything except these. Use `allowed_policies` when you know what a worker needs, and `disallowed_policies` only for a role that must offer many policies and must never offer a few dangerous ones, such as `root` and any administrator policy. When both are set, `disallowed_policies` still blocks a policy that is also allowed.

You now know the fields of a role, how to write a strict one, and how to make a role the only way an application can create tokens. A role still allows the token to be used from anywhere and as many times as the holder wants. The last part adds those limits.

## Common pitfalls

> [!WARNING]
> - **Leaving `allowed_policies` empty.** The caller may then request any policy the caller's own token has, and the role does not limit the rights.
> - **Giving `auth/token/create` instead of `auth/token/create/<role>`.** The open path ignores the role. Give only the role path.
> - **Mixing `token_period` with `token_explicit_max_ttl`.** The token ends at the explicit maximum, even when renewed on time. That is a rotation, and it must be intended.
> - **Writing a role with only the fields you want to change and assuming the rest is reset.** A write keeps fields you leave out. Read the role after every change.
