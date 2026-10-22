# Write Identity-Aware Policies And Control Groups

Ten people each need a private place for their secrets. With plain policies, that means ten policies, and one more every time somebody joins. Payroll data is worse: the payroll team may read it, but only after somebody else agrees. Both problems need policies that know who is calling. OpenBao's identity system provides that knowledge, and this module shows how policies use it.

An **identity entity** is OpenBao's record of one person or machine. An **alias** connects the entity to a login on one auth method, such as the user name `alice` on the userpass method. An **identity group** is a set of entities, and policies attached to the group apply to every member.

The module has three parts. **Templated Policies From Identity** writes one policy that gives every user their own area by filling the user's entity name into the path. **Policies On Identity Groups** attaches that policy to a group and shows where a token's policies really come from; a graded lab follows it. **Control Groups: A Second Person Approves** holds a request until a member of an approvers group agrees.

## Learning objectives

After this module you can:

- Explain how a userpass login is mapped to an identity entity through an alias.
- Write a templated policy with `{{identity.entity.name}}` or `{{identity.entity.id}}`.
- Attach policies to an identity group, and tell token policies from identity policies in `bao token lookup`.
- Write a `control_group` factor with group names, approvals and `controlled_capabilities`.
- Run the control group flow: request, review, authorize and unwrap.

## Before you start

You need to log in to OpenBao with the userpass method, write a policy with `bao policy write`, and read and write KV version 2 secrets. You should know that a KV version 2 policy uses `secret/data/...` for reading and writing and `secret/metadata/...` for listing.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, **initialized and unsealed**. It contains:

| Object | What it is |
| --- | --- |
| KV version 2 at `secret/` | Holds `secret/users/bob/notes` and `secret/payroll/salaries` |
| userpass at `userpass/` | The users `alice`, `bob`, `carol` and `dave`, each with the password `<name>-password` |
| Identity entities | One entity per user, named like the user, with an alias on the userpass method |
| Identity group `staff` | The members `alice`, `bob` and `dave`; `carol` is not a member |

Keep the port-forward running in a second terminal:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

In the terminal where you work, point `bao` at the server and log in with the lab-only root token:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

If your network blocks the name `openbao.localtest.me`, add `127.0.0.1 openbao.localtest.me` to `/etc/hosts`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
