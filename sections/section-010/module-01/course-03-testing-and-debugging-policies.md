# Testing Policies And Reading A Permission Denied

A policy is only finished when you have proved what it allows and what it refuses. Applications find the gaps the hard way: a deploy fails at three in the morning with `permission denied`, or an audit finds that a build job could delete production secrets. This part shows how to test a policy quickly, how to read a refusal, and how to limit what a request may send, not only where it goes.

## Asking OpenBao what a token may do

Creating a token and trying every request works, but it is slow. OpenBao can answer the question directly. The `bao token capabilities` command takes a token and a path and prints the capabilities that token has there, after all the matching and priority rules.

<!-- astrona:playground:renew -->

Write the inventory policy from a file, create a token with only that policy, and ask about three paths. Save this as `inventory-read.hcl`:

```hcl
path "secret/data/inventory/*" {
  capabilities = ["read"]
}

path "secret/metadata/inventory/*" {
  capabilities = ["list"]
}
```

Load it and ask:

```sh
bao policy write inventory-read inventory-read.hcl
APP_TOKEN=$(bao token create -policy=inventory-read -ttl=15m -field=token)
bao token capabilities "$APP_TOKEN" secret/data/inventory/db
bao token capabilities "$APP_TOKEN" secret/metadata/inventory/db
bao token capabilities "$APP_TOKEN" secret/data/billing/db
```

The first answer is `read`, the second is `list`, and the third is `deny`. OpenBao prints `deny` both when a rule says `deny` and when no rule matches at all; for the token the result is the same. Note that the paths are API paths: `bao token capabilities` does not add the KV version 2 `data/` segment for you.

## Reading a permission denied

When a request is refused, `bao` prints an error with the HTTP status code `403` and the words `permission denied`. OpenBao does not say which rule was missing, on purpose: the message would tell an attacker about your policies. You find the cause yourself, in a fixed order:

1. **Which token sent the request?** Run `bao token lookup` with that token and read its `policies` field. Many problems are a token with the wrong policies, or a different token than you thought.
2. **Which API path did the request use?** Run the same command with `-output-policy`. On a KV version 2 mount the path has `data/` or `metadata/` in it.
3. **Which capability does that request need?** The `-output-policy` output names it.
4. **What does the token have there?** Run `bao token capabilities <token> <path>`.

Try it on a command that the inventory application is not allowed to run:

```sh
BAO_TOKEN=$APP_TOKEN bao kv put secret/inventory/db password=changed
bao kv put -output-policy secret/inventory/db password=changed
```

The first command fails with `permission denied`. The second shows that a write to `secret/data/inventory/db` needs `create` and `update`, and the token only has `read` there. That refusal is correct: the application only reads.

## Limiting what a request sends

A rule can also limit the fields a request carries. These **parameter constraints** are optional settings on a path rule:

| Setting | What it does |
| --- | --- |
| `required_parameters` | The request must contain these fields |
| `allowed_parameters` | Only these fields are accepted; a field with a list of values may only have one of those values |
| `denied_parameters` | These fields are refused; it wins over `allowed_parameters` |

Parameter constraints do **not** work with the KV version 2 secrets engine, because KV version 2 wraps the secret's fields inside one `data` object. Use them on other APIs. A common case is a help desk that may reset a user's password but must not change the user's policies.

Enable the userpass auth method, create a user, and save this as `password-reset.hcl`:

```hcl
path "auth/userpass/users/*" {
  capabilities = ["update"]
  allowed_parameters = {
    "password" = []
  }
}
```

An empty list means the field may have any value. Load the policy and try both kinds of change with a help desk token:

```sh
bao auth enable userpass
bao write auth/userpass/users/erin password=erin-password
bao policy write password-reset password-reset.hcl
DESK_TOKEN=$(bao token create -policy=password-reset -ttl=15m -field=token)
BAO_TOKEN=$DESK_TOKEN bao write auth/userpass/users/erin password=new-password
BAO_TOKEN=$DESK_TOKEN bao write auth/userpass/users/erin token_policies=root
```

The password reset succeeds. The second write fails with `permission denied`, because `token_policies` is not an allowed parameter. Without the constraint, the help desk could have given any user any policy.

You can now test a policy without guessing, trace a refusal to its cause in four steps, and limit the fields a request may send. These are the habits that keep policies small: write the rule, prove what it allows, and prove what it refuses.

## Common pitfalls

> [!WARNING]
> - **Testing only what should work.** A policy that allows too much passes every positive test. Always test at least one request that must be refused.
> - **Asking `bao token capabilities` about the `bao kv` path.** It needs the API path, such as `secret/data/inventory/db`, not `secret/inventory/db`.
> - **Using parameter constraints on KV version 2.** They are not supported there. Restrict KV version 2 with paths instead.
> - **Debugging with the wrong token.** Check `bao token lookup` first. The `BAO_TOKEN` variable in your shell may not be the token the application uses.

## Your mission: Fix The Inventory Application Policy

You can now trace a refused request to its rule and prove what a policy allows and refuses. The mission gives you an inventory application whose policy was written for the wrong kind of KV mount and allows writes, and asks you to make it read and list its own secrets and nothing more.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-115-playground-010-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS115.git -c sections/section-010/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-115-lab-010-01
astrona start ats-115-playground-010-01
```
