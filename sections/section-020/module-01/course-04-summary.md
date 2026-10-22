# Summary

OpenBao's identity system turns a login into a person or machine it can reason about. An auth method checks the credentials, an alias maps the login name on that mount to an identity entity, and the token carries the entity's ID. Entities created ahead of time have stable names; entities created at first login get generated names, which makes name-based templates useless.

A templated policy contains placeholders such as `{{identity.entity.name}}` or `{{identity.entity.id}}`, and OpenBao fills them in for each request. One policy can therefore give every caller their own folder, and a caller can never reach another caller's folder, because the path in the rule is built from their own identity. The documentation recommends IDs, because they never change or get reused.

A token gets policies from two places. Token policies are fixed when the token is created, for example from a userpass user's `token_policies`. Identity policies come from the entity and its groups and are looked up on every request, so adding someone to a group gives them access at once, and removing them takes it away without a new login. `bao token lookup` shows the two lists in `policies` and `identity_policies`.

A control group holds a request on a protected path until enough members of named identity groups approve it. The requester receives a wrapping token and an accessor instead of the data, an approver reviews and authorizes the request with the accessor, and the requester unwraps the token to get the original response. OpenBao sends no notifications, the requester cannot approve their own request by default, and a factor that names a missing or empty group can never be approved.

- Template on entity IDs where names may change.
- Put people's access on identity groups, machines' access on their auth role.
- A control group factor needs an existing group with members.

<!-- astrona:playground:destroy -->
