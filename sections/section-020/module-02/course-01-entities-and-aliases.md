# Entities And Aliases

Every auth method in OpenBao identifies a client in its own way: a user name, a role name, a certificate subject. Those names mean nothing outside their auth method. An entity is the OpenBao object that represents one real client across all auth methods, and an alias is the link between that entity and one login name on one auth method. This part shows how to read both, create them by hand, and manage them over time.

## Entities, aliases and mount accessors

An **entity** is a record in OpenBao's identity store. It has an ID, a name, optional policies, optional metadata (key-value pairs that describe the client, such as a team) and a list of aliases. An **entity alias** says "the login name `alice` on this auth mount belongs to that entity". An auth mount is identified by its **mount accessor**, a generated string such as `auth_userpass_1a2b3c4d`, which stays the same for the life of the mount. A name alone is not enough, because two auth methods can both have a user called `alice`.

When a client logs in and no alias exists for that name and mount, OpenBao creates a new entity and an alias automatically. When an alias already exists, the login token is tied to the existing entity. That is why you can create the entity and its alias before the first login, as the playground does.

<!-- astrona:playground:renew -->

Look at the entity for alice, and then at the userpass mount accessor that her alias uses:

```sh
bao read identity/entity/name/alice
bao auth list -format=json
```

The entity output shows the fields `id`, `name`, `metadata` with `team` set to `red`, `policies`, `aliases` and `group_ids`. The alias lists its `name`, its `mount_accessor` and its `mount_type`. The auth list shows the `accessor` value for `userpass/`, which is the same string.

## Seeing the entity on a token

Log in as alice and look at the token. The token lookup shows which entity the login created or reused:

```sh
ALICE=$(bao login -method=userpass -token-only -no-store username=alice password=alice-password)
BAO_TOKEN=$ALICE bao token lookup -format=json
```

In the output, `entity_id` matches the `id` from the entity read. This is the value that appears in audit logs, so it is how you tie a request back to a person. The token's `policies` field includes `default` only, because alice's entity and groups have no other policies attached yet.

## Creating entities and aliases by hand

Creating an entity is a write to `identity/entity`, and an alias is a write to `identity/entity-alias`. You need the entity ID and the mount accessor:

```sh
bao write identity/entity name=erin metadata=team=red metadata=region=north
ENTITY_ID=$(bao read -field=id identity/entity/name/erin)
ACCESSOR=$(bao auth list -format=json | jq -r '."userpass/".accessor')
bao write identity/entity-alias name=erin canonical_id="$ENTITY_ID" mount_accessor="$ACCESSOR"
```

The first command repeats `metadata=` to set two keys. The alias write returns the alias ID and the canonical entity ID. Only the alias name `erin` must match a user on the userpass mount for logins to find this entity. The command `jq` runs on your own machine here; if you do not have it, copy the accessor from the `bao auth list` output.

You can list and read entities in three ways: `bao list identity/entity/name`, `bao read identity/entity/id/<id>`, and a lookup by alias name and mount, which is useful when you only know the login name:

```sh
bao write identity/lookup/entity alias_name=erin alias_mount_accessor="$ACCESSOR"
```

## Policies and metadata on an entity

An entity can carry policies of its own. Every token that belongs to the entity gets them, and they appear in `identity_policies` in the token lookup. Entity metadata is the value templated policies read as `{{identity.entity.metadata.team}}`, which makes metadata a way to give one policy a different meaning for each person.

```sh
bao write identity/entity name=erin policies=default metadata=team=red metadata=region=north
```

Writing to an existing entity by name updates it. Fields you do not repeat are left as they are, but metadata is replaced as a whole map when you send any `metadata=` value, so send all keys every time.

## Merging and disabling

Two entities can end up describing one person, for example when someone logs in with two auth methods before aliases exist. The call `identity/entity/merge` moves the aliases and group memberships of one or more entities into a target entity and deletes the sources:

```sh
bao write identity/entity/merge from_entity_ids="$OLD_ID" to_entity_id="$NEW_ID"
```

To stop a person from using OpenBao without deleting their identity, set `disabled=true` on the entity. Requests with tokens tied to a disabled entity are refused, whatever policies the tokens carry. Set it back to `false` to restore access.

```sh
bao write identity/entity name=erin disabled=true
```

You can now find the entity behind any token, create entities and aliases with metadata, and merge or disable them. A single entity is still a one-person object. The next part groups entities, so that a policy can be attached once for many people.

## Common pitfalls

> [!WARNING]
> - **Creating an alias with the wrong mount accessor.** The name matches nothing and the next login creates a second entity. Copy the accessor from `bao auth list`.
> - **Sending partial metadata.** A write with one `metadata=` key replaces the whole map. Send every key.
> - **Using the entity name as a stable key.** Names can be renamed; the entity ID cannot. Use the ID in anything that must survive a rename.
> - **Forgetting that a disabled entity blocks existing tokens.** Tokens are not revoked, but every request with them fails.
