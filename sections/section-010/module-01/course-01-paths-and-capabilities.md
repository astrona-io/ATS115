# Paths And Capabilities

A new token in OpenBao can do almost nothing. It can look itself up and renew itself, but it cannot read a single secret. Every permission it gets comes from a policy. This part builds a first policy for the inventory application, step by step, and shows the one detail that trips up almost everybody on a KV version 2 mount.

## What a policy is made of

A policy is a named set of rules in HashiCorp Configuration Language (HCL). Each rule is a `path` block: the path the rule covers, and a list of **capabilities**, the operations a token may perform on that path. OpenBao stores policies by name, and a token carries a list of policy names.

This is a complete policy with one rule:

```hcl
path "secret/data/inventory/db" {
  capabilities = ["read"]
}
```

The rule allows one thing: reading the secret at `secret/data/inventory/db`. Nothing else is allowed, because OpenBao denies everything that no rule allows.

Capabilities map closely to the HTTP methods of the OpenBao API:

| Capability | HTTP method | What it allows |
| --- | --- | --- |
| `create` | `POST`, `PUT` | Create data at a path that has none yet |
| `read` | `GET` | Read the data at a path |
| `update` | `POST`, `PUT` | Change existing data; in most of OpenBao this also creates it |
| `patch` | `PATCH` | Change part of the data |
| `delete` | `DELETE` | Delete the data |
| `list` | `LIST` | List the keys under a path |
| `scan` | `SCAN` | List the keys under a path recursively |
| `sudo` | none | Use a root-protected path, such as changing audit devices |
| `deny` | none | Refuse the request, whatever any other rule allows |

The mapping follows the HTTP method, not what happens behind it. Generating database credentials creates a credential, but the request is a `GET`, so it needs `read`. When you are unsure, look up the HTTP method of the API call and pick the capability that matches it.

## The data and metadata paths of KV version 2

The secrets in your playground live in a KV version 2 secrets engine at `secret/`. KV version 2 keeps every version of a secret, and it splits its API into separate paths for separate jobs. The `bao kv` commands hide this split, but policies do not.

<!-- astrona:playground:renew -->

Ask `bao` which API path a command really uses. The `-output-policy` flag prints the rule the command would need instead of running it:

```sh
bao kv get -output-policy secret/inventory/db
```

The output is a policy rule on `secret/data/inventory/db` with the `read` capability. The command you typed says `secret/inventory/db`, but the request goes to `secret/data/inventory/db`. The `kv` command added the `data/` segment for you.

Try the same for listing:

```sh
bao kv list -output-policy secret/inventory
```

This time the rule is on `secret/metadata/inventory` with the `list` capability. Listing keys and reading the history of a secret use the `metadata/` path. The table shows the paths you will meet most often:

| What you do | Command | API path | Capability |
| --- | --- | --- | --- |
| Read the latest version | `bao kv get secret/inventory/db` | `secret/data/inventory/db` | `read` |
| Write a new version | `bao kv put secret/inventory/db ...` | `secret/data/inventory/db` | `create`, `update` |
| List keys | `bao kv list secret/inventory` | `secret/metadata/inventory` | `list` |
| Delete every version and the history | `bao kv metadata delete secret/inventory/db` | `secret/metadata/inventory/db` | `delete` |
| Destroy chosen versions | `bao kv destroy -versions=1 secret/inventory/db` | `secret/destroy/inventory/db` | `update` |

A policy written as if the mount were KV version 1, with rules on `secret/inventory/*`, matches none of these API paths. Every request is refused, even though the policy looks right.

## A first policy for the inventory application

The inventory application reads its database password and API key, and it lists the keys under `secret/inventory`. It never writes or deletes. A glob, a `*` at the end of a path, matches anything that starts with the text before it, so one rule covers every secret under `secret/data/inventory/`.

Save this as `inventory-read.hcl`:

```hcl
# Read every inventory secret.
path "secret/data/inventory/*" {
  capabilities = ["read"]
}

# List the keys under secret/inventory.
path "secret/metadata/inventory/*" {
  capabilities = ["list"]
}
```

Load it into OpenBao under the name `inventory-read`:

```sh
bao policy write inventory-read inventory-read.hcl
```

Then check what OpenBao stored:

```sh
bao policy list
bao policy read inventory-read
```

The list shows your new policy next to `default` and `root`, the two policies every OpenBao server has. The `default` policy is attached to almost every token and lets a token look itself up, renew itself and use its own cubbyhole. The `root` policy allows everything and is attached only to root tokens.

Reading the policy back proves it was stored, not that it works. A policy only shows its effect on a token that carries it. Create a short-lived token with only this policy, and keep it in a variable:

```sh
APP_TOKEN=$(bao token create -policy=inventory-read -ttl=15m -field=token)
BAO_TOKEN=$APP_TOKEN bao kv get secret/inventory/db
BAO_TOKEN=$APP_TOKEN bao kv get secret/billing/db
```

The first read returns the inventory database credentials. The second fails with `permission denied`, because no rule in `inventory-read` covers `secret/data/billing/db`. Putting `BAO_TOKEN=...` in front of one command runs only that command as the application, while your shell keeps the root token.

You now know the shape of a rule, the capabilities, and the hidden `data/` and `metadata/` paths of KV version 2. You have also seen the basic test: a fresh token with only the policy you wrote. The open question is what happens when more than one rule matches the same request, which is the normal case in a real policy.

## Common pitfalls

> [!WARNING]
> - **Writing rules on `secret/<name>` for a KV version 2 mount.** The API paths are `secret/data/<name>` and `secret/metadata/<name>`. Use `-output-policy` to see the real path.
> - **Giving `update` for a read-only application.** On most paths `update` also creates data. An application that only reads needs only `read`, and `list` where it lists.
> - **Testing with the root token.** The root policy allows everything, so every test passes. Test with a token that has only the policy you wrote.
> - **Forgetting that `list` is on `metadata/`.** A rule with `list` on `secret/data/...` does nothing; listing uses `secret/metadata/...`.
