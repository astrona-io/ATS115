# Overview: Work With Entities, Aliases And Groups (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao, initializes and unseals it, creates users, entities and groups, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao` (pod `openbao-0`), **initialized and unsealed**. The lab-only unseal key and root token are in the Secret `openbao-init`.
- A KV version 2 secrets engine at `secret/` with `secret/teams/red/plan`, `secret/teams/blue/plan`, `secret/eng/handbook` and `secret/platform/runbook`.
- The userpass auth method with the users `alice`, `bob`, `carol` and `dave`; each password is `<name>-password`.
- One entity per user with an alias on the userpass mount. The metadata key `team` is `red` for alice and bob, and `blue` for carol and dave.
- The groups `staff` (all four users), `platform` (carol) and `engineering` (dave), without policies.
- The **`bao` CLI 2.7.1** and **Helm 3.22.1** on your machine, and a **tester** pod in the namespace `clients`.

Keep the port-forward running in a second terminal:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

Then set these in each terminal where you work:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

## Helpers

Paste these once in each new terminal. `login_as` logs a userpass user in and prints the token without storing it. `try_as` runs one `bao` command with a given token.

```sh
login_as() { bao login -method=userpass -token-only -no-store username="$1" password="$1-password"; }
try_as() { local token="$1"; shift; BAO_TOKEN="$token" bao "$@"; }
```

Use them like this: `ALICE=$(login_as alice)`, then `try_as "$ALICE" token lookup`.

## Practice tasks

- Read the entity of each user and compare its `id` with the `entity_id` in a token lookup.
- Create an entity with no alias, then log in with a user of the same name, and count the entities.
- Disable an entity with `disabled=true` and check what its existing token can still do.
- Make `platform` a member group of `engineering` and compare carol's `identity_policies` before and after.
- Create an external group with a group alias and read the group.
- Write a templated policy for `metadata.team`, remove the metadata key from one entity, and observe the refusal.
