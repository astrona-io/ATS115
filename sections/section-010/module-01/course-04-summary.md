# Summary

A token in OpenBao can only do what its policies allow. A policy is a named set of path rules in HCL, and each rule lists capabilities: `create`, `read`, `update`, `patch`, `delete`, `list`, `scan`, `sudo` and `deny`. The capabilities follow the HTTP method of the request, not what happens behind it, and anything that no rule allows is refused.

On a KV version 2 mount, the `bao kv` commands hide the real API paths. Reading and writing use `secret/data/...`, while listing and deleting a whole secret use `secret/metadata/...`. A policy written as if the mount were KV version 1 matches none of them. The `-output-policy` flag on a command prints the exact rule it needs.

When several rules match a request, OpenBao uses only the most specific pattern: an exact path beats a glob, and a longer glob beats a shorter one. A glob, `*`, only works at the end of a path, and `+` matches exactly one segment anywhere. `deny` wins over every other capability, which makes it the tool for cutting one path out of a wider rule, and also makes a `deny` on the wrong path a silent outage.

A policy is proved with a fresh token that carries only that policy, never with the root token. `bao token capabilities` shows what a token has on a path, and a refused request is traced in four steps: the token, the API path, the capability the request needs, and the capability the token has. Parameter constraints limit the fields a request may send, but they do not work on KV version 2.

- Rules for KV version 2 go on `data/` and `metadata/` paths.
- Only the highest-priority matching pattern counts; capabilities of different patterns do not add up.
- `deny` always wins.
- Test what must succeed and what must be refused.

<!-- astrona:playground:destroy -->
