# Overview: Write Identity-Aware Policies And Control Groups (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs OpenBao, initializes and unseals it, creates users and identities, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **OpenBao v2.7.1** in the namespace `openbao` (pod `openbao-0`), **initialized and unsealed**. The lab-only unseal key and root token are in the Secret `openbao-init`.
- A KV version 2 secrets engine at `secret/` with `secret/users/bob/notes` and `secret/payroll/salaries`.
- The userpass auth method at `userpass/` with the users `alice`, `bob`, `carol` and `dave`; each password is `<name>-password`.
- One identity entity per user, named like the user, with an alias on the userpass mount.
- The identity group `staff` with `alice`, `bob` and `dave` as members.
- The **`bao` CLI 2.7.1** on your machine, and a **tester** pod in the namespace `clients`.

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

Paste these once in each new terminal. `login_as` logs a userpass user in and prints the token without storing it. `entity_id` prints the ID of an entity by name. `try_as` runs one `bao` command with a given token.

```sh
login_as() { bao login -method=userpass -token-only -no-store username="$1" password="$1-password"; }
entity_id() { bao read -field=id "identity/entity/name/$1"; }
try_as() { local token="$1"; shift; BAO_TOKEN="$token" bao "$@"; }
```

Use them like this: `ALICE=$(login_as alice)`, then `try_as "$ALICE" token lookup`.

## Practice tasks

- Log in as each user and compare the `entity_id` in `bao token lookup` with `bao read identity/entity/name/<user>`.
- Write a templated policy with `{{identity.entity.id}}` instead of the name, and find the folder each user must use.
- Add `carol` to `staff` and check, without a new login, that her existing token gains the group's policies.
- Write a control group that needs two approvals from `approvers`, add a second approver, and run the flow.
- Add `controlled_capabilities = ["update"]` to a factor on a rule with `read` and `update`, and check which operation needs approval.
- Let `dave` try to approve his own request, and read the result.
