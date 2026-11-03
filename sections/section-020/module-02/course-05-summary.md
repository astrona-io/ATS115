# Summary

An entity is the identity store's record of one client. It has an ID, a name, optional policies, optional metadata and a list of aliases. An alias links one login name on one auth mount, identified by the mount accessor, to an entity. A login that matches an alias uses that entity, and a login that matches none creates a new entity and alias. The entity ID is the stable key, and it appears in the token lookup and in audit logs. Entities can be merged, and an entity set to disabled makes every request with its tokens fail.

Groups attach policies to many entities at once. An internal group lists member entities and member groups, and a member group passes the policies of its parent groups to its own members, never the other way. A write to a group sets whole member lists, so the full list must be sent. Policies that come from the entity or from groups show in `identity_policies` in the token lookup, and the token's `policies` field is the union of all sources.

An external group has no member list of its own. A group alias binds the group to a group name that an auth method reports at login, and OpenBao changes membership at each login. A removal in the outside system therefore applies at the next login, so token lifetimes limit how fast a removal takes effect.

Policy paths can use identity values: the entity ID, name and metadata, alias values for a given mount accessor, and group IDs and names. A missing value makes OpenBao skip the rule without any error. Templates work only in paths, and tokens without an entity cannot use them.

- Use the entity ID as the stable key.
- Send full member lists and full metadata maps.
- Read `identity_policies` to find the source of a right.
- A missing template value skips the rule silently.

<!-- astrona:playground:destroy -->
