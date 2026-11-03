# Work With Entities, Aliases And Groups

A policy decides what a token may do, but it is the identity system that decides which policies a person gets. One person may log in with a password on Monday, with a certificate on Tuesday and with a single sign-on provider on Wednesday. Without identity, OpenBao sees three unrelated clients. With identity, it sees one person with three ways in, and it can attach policies, metadata and group memberships to that person once.

This module covers the identity objects: entities, aliases, internal and external groups, group nesting, and the template variables a policy can use to read identity information.

The module has four parts. **Entities And Aliases** explains how a login becomes an entity and how entities are created, found, merged and disabled. **Groups And Policy Inheritance** covers internal groups and how groups inside groups pass on policies. **External Groups And Group Aliases** shows how groups from an outside provider map to OpenBao groups. **The Template Variable Reference** lists every identity value a policy path may use. A graded lab follows the last part.

## Learning objectives

After this module you can:

- Explain what an entity, an entity alias and a mount accessor are, and how they relate.
- Create entities with metadata and aliases, look them up, merge two of them and disable one.
- Create internal groups, add entities and groups as members, and predict the policies a member gets.
- Describe how an external group and a group alias connect an outside provider's group to a group in OpenBao.
- Write a templated policy with `identity.entity` and `identity.groups` variables.
- Find the identity source of a right in a token lookup.

## Before you start

You should be able to write a path rule, create a token with a policy, and enable the userpass auth method. You should know that a policy path can contain a template such as `{{identity.entity.name}}`.

Your playground is a single-node `kind` cluster with **OpenBao v2.7.1** in the namespace `openbao`, installed with the `openbao` Helm chart 0.30.4, **initialized and unsealed**. It contains:

| Object | What it is |
| --- | --- |
| KV version 2 at `secret/` | Secrets under `secret/teams/red/`, `secret/teams/blue/`, `secret/eng/` and `secret/platform/` |
| Userpass at `userpass/` | The users `alice`, `bob`, `carol` and `dave`; each password is `<name>-password` |
| Entities | One entity per user, with the metadata `team` set to `red` for alice and bob and `blue` for carol and dave, and an alias on the userpass mount |
| Groups | `staff` with all four users, `platform` with carol, and `engineering` with dave |

The playground puts the `bao` command-line tool 2.7.1 on your machine. OpenBao answers at `http://openbao.localtest.me:8200`. Keep this port-forward running in a second terminal, and start it again if the OpenBao pod restarts:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

In the terminal where you work, point `bao` at the server and log in with the lab-only root token. A real installation revokes its root token after setup.

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

If your network blocks the name `openbao.localtest.me`, add `127.0.0.1 openbao.localtest.me` to `/etc/hosts`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
