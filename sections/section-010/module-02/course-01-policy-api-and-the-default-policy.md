# The Policy API And The Default Policy

Policies live inside OpenBao, not on the disk of the machine where you wrote them. Every tool that manages them, from the `bao` command to a Terraform provider, ends up calling the same HTTP API. This part shows the commands and the API underneath, and then looks at the one policy that OpenBao creates for you: `default`.

## Writing, reading and deleting policies

A policy is stored under a name. The name is case-insensitive: OpenBao converts it to lower case. The `bao policy` command group manages policies, and each command is one call to the endpoint `sys/policies/acl/<name>`.

<!-- astrona:playground:renew -->

The playground already has a policy called `team-app`. List the policies and read it:

```sh
bao policy list
bao policy read team-app
```

The list shows `default`, `root` and `team-app`. The read prints the policy text exactly as it was stored. Now write a new policy from standard input. A dash in place of a file name tells `bao policy write` to read the text from the terminal:

```sh
bao policy write report-reader - <<'POLICY'
path "secret/data/inventory/reports" {
  capabilities = ["read"]
}
POLICY
```

The command prints a short success message. A second `bao policy write` with the same name replaces the policy completely; there is no merge and no history. If you need a history, keep the policy files in version control and write them from there.

OpenBao can also format a policy file. `bao policy fmt` rewrites a file in the canonical HCL layout, which keeps diffs small in a repository:

```sh
bao policy fmt team-app.hcl
```

The same actions exist as raw API calls. This is what the CLI sends when you read and then delete a policy:

```sh
bao read sys/policies/acl/report-reader
bao delete sys/policies/acl/report-reader
```

The read returns the fields `name` and `policy`. The delete removes the policy. `bao policy delete report-reader` does the same thing.

## Checking what a token can do before you use it

A policy is easier to review when you can ask OpenBao what it means for a path. Two endpoints answer that. `sys/capabilities-self` reports the capabilities of the token that asks. `sys/capabilities` reports the capabilities of any token you pass, which needs a rule that allows it. The command `bao token capabilities` calls them:

```sh
TOKEN=$(bao token create -policy=team-app -ttl=15m -field=token)
bao token capabilities "$TOKEN" secret/data/inventory/db
bao token capabilities "$TOKEN" secret/data/billing/db
```

The first command lists the capabilities the token has on the inventory secret. The second prints `deny`, which is the answer for a path that no rule allows. The answer combines every policy on the token, so it is a better check than reading policy files by eye.

## The default policy

Every new token gets the policy `default`, unless you ask for it not to. It exists so that a token can do the small set of things any client needs: look itself up, renew itself, revoke itself, ask for its own capabilities, use its own cubbyhole (a private key-value store that belongs to one token), and wrap, look up and unwrap response-wrapping tokens. Read it:

```sh
bao policy read default
```

The text is a list of short rules such as `auth/token/lookup-self`, `auth/token/renew-self`, `sys/capabilities-self`, `cubbyhole/*` and `sys/wrapping/lookup`. You can edit `default`, and a change affects every token that carries it, which is why edits to it need care. You cannot delete it.

A token that should do only one thing can be created without it. The flag is `-no-default-policy`:

```sh
NARROW=$(bao token create -policy=team-app -no-default-policy -ttl=15m -field=token)
BAO_TOKEN=$NARROW bao token lookup
```

The lookup is refused with `permission denied`, because the rule that lets a token look itself up lives in `default`. This is rarely what you want for an application, since most client libraries renew or look up their token. It is useful for a token that only ever makes one call.

You now know how to store, read, format, delete and test policies, and what every token gets by default. The next question is what happens to tokens that already exist when you change or delete a policy they carry.

## Common pitfalls

> [!WARNING]
> - **Treating `bao policy write` as a merge.** It replaces the whole policy. Keep the full text in a file.
> - **Editing `default` casually.** Every token carries it. A mistake there changes the rights of all clients.
> - **Using `-no-default-policy` for an application.** The application then cannot renew or look up its own token, and often fails an hour later instead of at start.
> - **Checking a policy by reading it.** Use `bao token capabilities` with a real token. It shows the result of all policies together.
