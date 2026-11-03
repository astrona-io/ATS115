# External Groups And Group Aliases

Many organisations already keep their people in groups somewhere else: a directory service, a single sign-on provider, a cluster. Copying those memberships into OpenBao by hand would go out of date within a week. An external group lets the outside system decide who belongs, and OpenBao attaches policies to the group. This part shows how an external group is built and when its membership is updated.

## Internal and external groups

An **internal group** has members that you list in OpenBao. An **external group** has no member list you manage. OpenBao fills in its members at login, from the group names that the auth method reports for the client. Auth methods that report groups include LDAP, OpenID Connect (OIDC) and JSON Web Token (JWT) login. The userpass method does not report groups.

The link between the outside group name and the external group is a **group alias**. A group alias holds the name that the auth method reports, the mount accessor of that auth method, and the ID of the external group it points to. The same external group can have several aliases, one for each auth method that uses a different name for the same people.

## Creating an external group and its alias

Create an external group named `auditors` and attach a policy, then find the userpass accessor and the group ID. This works on any mount, even one that never reports groups, which is useful for seeing the objects:

<!-- astrona:playground:renew -->

```sh
bao policy write auditors-read - <<'POLICY'
path "secret/data/eng/*" {
  capabilities = ["read"]
}
POLICY
bao write identity/group name=auditors type=external policies=auditors-read
GROUP_ID=$(bao read -field=id identity/group/name/auditors)
ACCESSOR=$(bao auth list -format=json | jq -r '."userpass/".accessor')
bao write identity/group-alias name=audit-team mount_accessor="$ACCESSOR" canonical_id="$GROUP_ID"
```

The group is created with the type `external`. The alias says: when the auth mount with this accessor reports the group name `audit-team` for a login, add that client's entity to `auditors`. Read the group to see the alias:

```sh
bao read identity/group/name/auditors
```

The output has `type` set to `external` and an `alias` object with the `name`, the `mount_accessor` and the `canonical_id`. The `member_entity_ids` list is empty until someone logs in through a mount that reports `audit-team`.

## When membership changes

For an external group, OpenBao computes membership at login. A person who logs in and is reported in the group is added to it. A person who logs in later without being reported is removed from it. The membership in between login times is whatever the last login said. A person removed in the directory keeps the right until the next login or until the token expires, so token lifetimes bound how long a removal takes to work.

For this reason, give tokens from groups-based logins a short lifetime, and set the auth method's own token TTL to match how fast removals must apply.

## Using external groups with internal ones

An external group can be a member of an internal group, and an internal group can be the parent of an external group. This is the usual pattern: the external group says who the person is, an internal group says what teams do. Attach broad policies to the internal group once, and give the external group a short list of its own.

You now know the difference between the two group types, how a group alias connects an outside name to an external group, and why membership changes arrive at the next login. The last part is a reference for the template variables that read all of this identity data inside a policy path.

## Common pitfalls

> [!WARNING]
> - **Adding members to an external group by hand.** Members of an external group come from logins. A hand-made list is overwritten.
> - **Creating a group alias without the exact name the provider reports.** Names are compared as strings. Check what the provider sends, including case.
> - **Using userpass to test external groups.** It reports no groups. Use a method that does, or test the objects only.
> - **Assuming a directory change takes effect at once.** It arrives at the next login.
