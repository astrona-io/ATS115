# Summary

OpenBao stores policies by name. The `bao policy` commands and the `sys/policies/acl` API write, read and delete them, and a write replaces the whole policy. The `default` policy gives every token a small set of rights: looking itself up, renewing and revoking itself, asking for its capabilities, using its cubbyhole and handling wrapping tokens. It can be edited but not deleted, and a token can be created without it.

A token carries policy names, not rules. OpenBao loads the current text of each policy on every request, so a change applies to all existing tokens at once. A deleted policy leaves its name on tokens and grants nothing. A token's final rights are the union of its own policies and the policies it receives through its entity and groups. A token that is not root can only create child tokens with a subset of its own policies.

Parameter constraints check the top-level fields of a request body. `allowed_parameters` lists the fields and values a client may send and refuses everything else unless `"*"` is present. `denied_parameters` refuses fields or values and wins over allowed ones. `required_parameters` refuses a request that leaves a field out. They do not work on KV version 2, where the secret sits under one key. The fields `min_wrapping_ttl` and `max_wrapping_ttl` force the client to wrap a response.

The root policy cannot be limited, so people should not use the root token. A few paths, such as audit devices and prefix revocation, need `sudo` on top of the normal capability. A policy administrator is built with a name prefix in the rule path, and policy writing and policy attachment belong to different roles.

- Policies are read by name at request time.
- Deleting a policy removes its rights, not its name from tokens.
- Constraints need flat request bodies.
- Fence delegated roles with a name prefix, and avoid `sudo` unless the task needs it.

<!-- astrona:playground:destroy -->
